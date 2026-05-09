import json
import os
import sys
import unittest
from datetime import datetime, timedelta, timezone


FUNCTIONS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if FUNCTIONS_DIR not in sys.path:
    sys.path.insert(0, FUNCTIONS_DIR)

from backend.ai import OpenAITriageClient, TriageAnalysisError, parse_response_text
from backend.api import ApiRouter, JsonResponse
from backend.config import Settings
from backend.models import MessageStatus, NotificationStatus, Priority, VoiceRequestPriority
from backend.service import TriageService


class FakeRepository:
    def __init__(self):
        self.messages = {}
        self.voice_requests = {}
        self.notifications = {}
        self.users = {
            "senior-1": {
                "role": "senior",
                "linked_accounts": ["caregiver-1"],
                "profile_context": "Lives alone, hypertension history.",
                "fcm_tokens": [],
            },
            "caregiver-1": {
                "role": "caregiver",
                "linked_accounts": ["senior-1"],
                "profile_context": "",
                "fcm_tokens": ["token-red"],
            },
            "caregiver-2": {
                "role": "caregiver",
                "linked_accounts": [],
                "profile_context": "",
                "fcm_tokens": ["token-other"],
            },
        }
        self.next_id = 1

    def create_user(self, uid, fields):
        if uid in self.users:
            raise ValueError("user_id already exists")
        user = dict(fields)
        user.setdefault("linked_accounts", [])
        user.setdefault("profile_context", "")
        user.setdefault("fcm_tokens", [])
        if user.get("role") == "senior":
            user.setdefault("pairing_code", "PAIR-NEW")
        user["id"] = uid
        self.users[uid] = user
        return user

    def create_triage_message(self, senior_id, storage_path, uploaded_at=None):
        message_id = f"message-{self.next_id}"
        self.next_id += 1
        now = datetime(2026, 5, 9, tzinfo=timezone.utc)
        self.messages[message_id] = {
            "id": message_id,
            "senior_id": senior_id,
            "audio_url": storage_path,
            "transcript": "",
            "summary": "",
            "priority": "",
            "suggested_action": "",
            "status": MessageStatus.PROCESSING,
            "created_at": uploaded_at or now,
            "updated_at": now,
        }
        return message_id

    def create_voice_request(self, fields):
        request_id = f"request-{self.next_id}"
        self.next_id += 1
        document = dict(fields)
        document["id"] = request_id
        self.voice_requests[request_id] = document
        return request_id

    def get_message(self, message_id):
        return self.messages.get(message_id)

    def update_message(self, message_id, fields):
        self.messages[message_id].update(fields)

    def get_user(self, uid):
        user = self.users.get(uid)
        if not user:
            return None
        return {"id": uid, **user}

    def find_senior_by_pairing_code(self, pairing_code):
        if pairing_code == "PAIR-123":
            return "senior-1"
        if pairing_code in self.users and self.users[pairing_code].get("role") == "senior":
            return pairing_code
        return None

    def link_accounts(self, caregiver_id, senior_id):
        self.users[caregiver_id].setdefault("linked_accounts", [])
        self.users[senior_id].setdefault("linked_accounts", [])
        if senior_id not in self.users[caregiver_id]["linked_accounts"]:
            self.users[caregiver_id]["linked_accounts"].append(senior_id)
        if caregiver_id not in self.users[senior_id]["linked_accounts"]:
            self.users[senior_id]["linked_accounts"].append(caregiver_id)

    def update_senior_context(self, senior_id, context):
        self.users[senior_id]["profile_context"] = context

    def list_messages_for_caregiver(self, caregiver_id, status=None, limit=20):
        linked = set(self.users[caregiver_id].get("linked_accounts", []))
        messages = [
            message
            for message in self.messages.values()
            if message["senior_id"] in linked
            and (status is None or message.get("status") == status)
        ]
        return messages[:limit]

    def get_caregiver_tokens_for_senior(self, senior_id):
        tokens = []
        for uid in self.users[senior_id].get("linked_accounts", []):
            user = self.users.get(uid, {})
            if user.get("role") == "caregiver":
                tokens.extend(user.get("fcm_tokens", []))
        return tokens

    def get_caregivers_for_senior(self, senior_id):
        senior = self.users.get(senior_id)
        if not senior:
            return []
        caregivers = []
        for uid in senior.get("linked_accounts", []):
            user = self.users.get(uid)
            if user and user.get("role") == "caregiver":
                caregivers.append({"id": uid, **user})
        return caregivers

    def create_notification(self, fields):
        notification_id = f"notification-{self.next_id}"
        self.next_id += 1
        document = dict(fields)
        document.setdefault("status", NotificationStatus.PENDING)
        document.setdefault("send_count", 0)
        document["id"] = notification_id
        self.notifications[notification_id] = document
        return document

    def get_notification(self, notification_id):
        return self.notifications.get(notification_id)

    def update_notification(self, notification_id, fields):
        self.notifications[notification_id].update(fields)
        return self.notifications[notification_id]

    def get_due_notifications(self, now):
        due = []
        for notification in self.notifications.values():
            next_send_at = notification.get("next_send_at")
            if (
                notification.get("status") in (NotificationStatus.PENDING, NotificationStatus.SENT)
                and next_send_at is not None
                and next_send_at <= now
            ):
                due.append(notification)
        return due


class FakeStorage:
    def __init__(self, path="local-audio.webm"):
        self.path = path
        self.downloaded = []

    def download(self, storage_path):
        self.downloaded.append(storage_path)
        return self.path


class FakeAI:
    def __init__(self, transcript="Help, I fell in the kitchen.", result=None, fail=False):
        self.transcript = transcript
        self.result = result or {
            "summary": "Senior reports a fall in the kitchen.",
            "priority": Priority.EMERGENCY,
            "reasoning": "Falls require urgent caregiver action.",
            "suggested_action": "Call immediately and dispatch help if no response.",
        }
        self.fail = fail
        self.analyze_calls = []

    def transcribe(self, audio_path):
        if self.fail:
            raise TriageAnalysisError("AI timeout")
        return self.transcript

    def analyze(self, transcript, profile_context):
        self.analyze_calls.append((transcript, profile_context))
        if self.fail:
            raise TriageAnalysisError("AI timeout")
        return self.result


class FakeNotifier:
    def __init__(self, fail=False):
        self.sent = []
        self.fail = fail

    def notify_caregivers(self, tokens, message):
        if self.fail:
            raise RuntimeError("FCM unavailable")
        self.sent.append((tokens, message))

    def send(self, payload):
        if self.fail:
            raise RuntimeError("Mock notification unavailable")
        self.sent.append(payload)
        return {"sent": True}


class FakeRequest:
    def __init__(self, method, path, body=None, args=None):
        self.method = method
        self.path = path
        self._body = body
        self.args = args or {}

    def get_json(self, silent=True):
        return self._body


class BackendServiceTests(unittest.TestCase):
    def build_service(self, ai=None):
        repo = FakeRepository()
        notifier = FakeNotifier()
        settings = Settings(
            openai_api_key=None,
            text_model="test",
            transcription_model="test",
            transcription_prompt="test",
            request_timeout_seconds=1.0,
            high_priority_repeat_interval_seconds=10,
            high_priority_max_sends=5,
            enable_mock_notifications=True,
        )
        service = TriageService(repo, FakeStorage(), ai or FakeAI(), notifier, settings)
        return service, repo, notifier

    def test_ingest_creates_processing_message(self):
        service, repo, _ = self.build_service()

        result = service.ingest("senior-1", "gs://bucket/audio/senior-1.webm")

        self.assertEqual(result["status"], MessageStatus.PROCESSING)
        message = repo.get_message(result["message_id"])
        self.assertEqual(message["senior_id"], "senior-1")
        self.assertEqual(message["audio_url"], "gs://bucket/audio/senior-1.webm")
        self.assertEqual(message["status"], MessageStatus.PROCESSING)

    def test_analyze_uses_profile_context_and_sends_notification(self):
        service, repo, notifier = self.build_service()
        message_id = repo.create_triage_message("senior-1", "gs://bucket/audio.webm")
        repo.update_message(message_id, {"transcript": "I fell down."})

        result = service.analyze(message_id)

        self.assertEqual(result["priority"], Priority.EMERGENCY)
        self.assertEqual(repo.get_message(message_id)["status"], MessageStatus.UNREAD)
        self.assertEqual(notifier.sent[0][0], ["token-red"])
        self.assertIn("fall", notifier.sent[0][1]["summary"].lower())

    def test_analyze_falls_back_to_emergency_when_ai_fails(self):
        service, repo, notifier = self.build_service(ai=FakeAI(fail=True))
        message_id = repo.create_triage_message("senior-1", "gs://bucket/audio.webm")
        repo.update_message(message_id, {"transcript": "Unclear audio"})

        result = service.analyze(message_id)

        self.assertEqual(result["priority"], Priority.EMERGENCY)
        self.assertEqual(repo.get_message(message_id)["status"], MessageStatus.UNREAD)
        self.assertEqual(repo.get_message(message_id)["suggested_action"], "Review the raw audio and contact the senior directly.")
        self.assertEqual(repo.get_message(message_id)["error"], "AI timeout")
        self.assertEqual(notifier.sent[0][0], ["token-red"])

    def test_process_message_dead_letters_when_transcription_fails(self):
        service, repo, notifier = self.build_service(ai=FakeAI(fail=True))
        message_id = repo.create_triage_message("senior-1", "gs://bucket/audio.webm")

        result = service.process_message(message_id)

        self.assertEqual(result["priority"], Priority.EMERGENCY)
        self.assertEqual(result["status"], MessageStatus.UNREAD)
        self.assertIn("AI timeout", repo.get_message(message_id)["error"])
        self.assertEqual(notifier.sent[0][0], ["token-red"])

    def test_notification_failure_is_recorded_without_failing_analysis(self):
        repo = FakeRepository()
        notifier = FakeNotifier(fail=True)
        service = TriageService(repo, FakeStorage(), FakeAI(), notifier)
        message_id = repo.create_triage_message("senior-1", "gs://bucket/audio.webm")
        repo.update_message(message_id, {"transcript": "I fell down."})

        result = service.analyze(message_id)

        self.assertEqual(result["priority"], Priority.EMERGENCY)
        self.assertIn("notification_error", repo.get_message(message_id))

    def test_feed_is_scoped_to_caregiver_and_sorted_by_priority_then_created_desc(self):
        service, repo, _ = self.build_service()
        older = datetime(2026, 5, 8, tzinfo=timezone.utc)
        newer = datetime(2026, 5, 9, tzinfo=timezone.utc)
        routine = repo.create_triage_message("senior-1", "gs://routine", older)
        emergency_old = repo.create_triage_message("senior-1", "gs://emergency-old", older)
        emergency_new = repo.create_triage_message("senior-1", "gs://emergency-new", newer)
        repo.update_message(routine, {"priority": Priority.NOT_EMERGENCY, "status": MessageStatus.UNREAD})
        repo.update_message(emergency_old, {"priority": Priority.EMERGENCY, "status": MessageStatus.UNREAD})
        repo.update_message(emergency_new, {"priority": Priority.EMERGENCY, "status": MessageStatus.UNREAD})

        feed = service.feed("caregiver-1", MessageStatus.UNREAD, 20)

        self.assertEqual([message["id"] for message in feed], [emergency_new, emergency_old, routine])
        self.assertEqual(service.feed("caregiver-2", MessageStatus.UNREAD, 20), [])

    def test_status_update_rejects_invalid_status(self):
        service, repo, _ = self.build_service()
        message_id = repo.create_triage_message("senior-1", "gs://bucket/audio.webm")

        with self.assertRaises(ValueError):
            service.update_status(message_id, "unread", "opened accidentally")

    def test_link_users_and_update_context(self):
        service, repo, _ = self.build_service()

        link_result = service.link_users("caregiver-1", "PAIR-123")
        context_result = service.update_context("senior-1", "Morning meds at 8am.")

        self.assertEqual(link_result, {"linked_senior_id": "senior-1"})
        self.assertEqual(context_result, {"success": True})
        self.assertIn("caregiver-1", repo.users["senior-1"]["linked_accounts"])
        self.assertEqual(repo.users["senior-1"]["profile_context"], "Morning meds at 8am.")

    def test_signup_creates_user_and_hides_password_fields(self):
        service, repo, _ = self.build_service()

        result = service.signup(
            "senior",
            "senior-new",
            "safe-password",
            "Mary Tan",
            "Lives alone.",
        )

        self.assertEqual(result["user"]["id"], "senior-new")
        self.assertEqual(result["user"]["role"], "senior")
        self.assertEqual(result["user"]["pairing_code"], "PAIR-NEW")
        self.assertNotIn("password_hash", result["user"])
        self.assertIn("password_hash", repo.users["senior-new"])

    def test_login_rejects_wrong_password(self):
        service, _, _ = self.build_service()
        service.signup("caregiver", "caregiver-new", "safe-password")

        result = service.login("caregiver-new", "safe-password")
        self.assertEqual(result["user"]["id"], "caregiver-new")

        with self.assertRaises(ValueError):
            service.login("caregiver-new", "wrong-password")

    def test_standard_priority_creates_one_notification_and_sends_once(self):
        service, repo, notifier = self.build_service()
        now = datetime(2026, 5, 10, 8, 0, tzinfo=timezone.utc)

        result = service.process_voice_request_result(
            senior_id="senior-1",
            transcript="Can someone call me later?",
            intent="Routine message",
            mood="calm",
            priority=VoiceRequestPriority.STANDARD,
            audio_url="gs://bucket/audio.webm",
            now=now,
        )

        self.assertEqual(result["priority"], VoiceRequestPriority.STANDARD)
        self.assertEqual(len(result["notifications_created"]), 1)
        notification = next(iter(repo.notifications.values()))
        self.assertEqual(notification["status"], NotificationStatus.SENT)
        self.assertFalse(notification["repeat_until_acknowledged"])
        self.assertIsNone(notification["next_send_at"])
        self.assertEqual(notification["send_count"], 1)
        self.assertEqual(len(notifier.sent), 1)
        self.assertEqual(notifier.sent[0]["type"], "STANDARD_MESSAGE")

    def test_high_priority_creates_repeating_notification(self):
        service, repo, notifier = self.build_service()
        now = datetime(2026, 5, 10, 8, 0, tzinfo=timezone.utc)

        service.process_voice_request_result(
            senior_id="senior-1",
            transcript="I feel dizzy and missed my medicine.",
            intent="Medication / urgent help",
            mood="distressed",
            priority=VoiceRequestPriority.HIGH,
            now=now,
        )

        notification = next(iter(repo.notifications.values()))
        self.assertEqual(notification["priority"], VoiceRequestPriority.HIGH)
        self.assertTrue(notification["repeat_until_acknowledged"])
        self.assertEqual(notification["status"], NotificationStatus.SENT)
        self.assertEqual(notification["next_send_at"], now + timedelta(seconds=10))
        self.assertEqual(len(notifier.sent), 1)
        self.assertEqual(notifier.sent[0]["type"], "HIGH_PRIORITY_ALERT")

    def test_high_priority_notification_resends_when_due(self):
        service, repo, notifier = self.build_service()
        now = datetime(2026, 5, 10, 8, 0, tzinfo=timezone.utc)
        service.process_voice_request_result(
            "senior-1",
            "Help me now",
            "Urgent help",
            "distressed",
            VoiceRequestPriority.HIGH,
            now=now,
        )
        due_at = now + timedelta(seconds=10)

        sent = service.send_due_notifications(due_at)

        notification = next(iter(repo.notifications.values()))
        self.assertEqual(len(sent), 1)
        self.assertEqual(notification["send_count"], 2)
        self.assertEqual(notification["next_send_at"], due_at + timedelta(seconds=10))
        self.assertEqual(len(notifier.sent), 2)

    def test_high_priority_stops_repeating_after_acknowledgement(self):
        service, repo, notifier = self.build_service()
        now = datetime(2026, 5, 10, 8, 0, tzinfo=timezone.utc)
        service.process_voice_request_result(
            "senior-1",
            "Help me now",
            "Urgent help",
            "distressed",
            VoiceRequestPriority.HIGH,
            now=now,
        )
        notification_id = next(iter(repo.notifications))
        service.acknowledge_notification(notification_id, now + timedelta(seconds=5))

        sent = service.send_due_notifications(now + timedelta(seconds=10))

        notification = repo.get_notification(notification_id)
        self.assertEqual(sent, [])
        self.assertEqual(notification["status"], NotificationStatus.ACKNOWLEDGED)
        self.assertFalse(notification["repeat_until_acknowledged"])
        self.assertIsNone(notification["next_send_at"])
        self.assertEqual(len(notifier.sent), 1)

    def test_acknowledgement_updates_status(self):
        service, repo, _ = self.build_service()
        now = datetime(2026, 5, 10, 8, 0, tzinfo=timezone.utc)
        service.process_voice_request_result(
            "senior-1",
            "Help me now",
            "Urgent help",
            "distressed",
            VoiceRequestPriority.HIGH,
            now=now,
        )
        notification_id = next(iter(repo.notifications))

        result = service.acknowledge_notification(notification_id, now + timedelta(seconds=3))

        self.assertEqual(result["status"], NotificationStatus.ACKNOWLEDGED)
        self.assertIsNotNone(result["acknowledged_at"])

    def test_invalid_priority_is_rejected(self):
        service, _, _ = self.build_service()

        with self.assertRaises(ValueError):
            service.process_voice_request_result(
                "senior-1",
                "hello",
                "Routine",
                "calm",
                "LOW",
            )

    def test_missing_caregiver_relationship_creates_no_notifications(self):
        service, repo, notifier = self.build_service()
        repo.users["senior-alone"] = {"role": "senior", "linked_accounts": [], "fcm_tokens": []}

        result = service.process_voice_request_result(
            "senior-alone",
            "hello",
            "Routine",
            "calm",
            VoiceRequestPriority.STANDARD,
        )

        self.assertEqual(result["notifications_created"], [])
        self.assertEqual(repo.notifications, {})
        self.assertEqual(notifier.sent, [])


class ApiRouterTests(unittest.TestCase):
    def test_ingest_route_returns_accepted(self):
        service, _, _ = BackendServiceTests().build_service()
        router = ApiRouter(service)

        response = router.handle(
            FakeRequest(
                "POST",
                "/api/v1/triage/ingest",
                {"senior_id": "senior-1", "storage_path": "gs://bucket/audio.webm"},
            )
        )

        self.assertIsInstance(response, JsonResponse)
        self.assertEqual(response.status_code, 202)
        self.assertEqual(response.body["status"], MessageStatus.PROCESSING)

    def test_signup_route_creates_account(self):
        service, _, _ = BackendServiceTests().build_service()
        router = ApiRouter(service)

        response = router.handle(
            FakeRequest(
                "POST",
                "/api/v1/auth/signup",
                {"role": "caregiver", "user_id": "caregiver-new", "password": "safe-password"},
            )
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.body["user"]["id"], "caregiver-new")

    def test_process_result_route_creates_notification(self):
        service, _, _ = BackendServiceTests().build_service()
        router = ApiRouter(service)

        response = router.handle(
            FakeRequest(
                "POST",
                "/voice-requests/process-result",
                {
                    "senior_id": "senior-1",
                    "transcript": "I feel dizzy and I missed my medicine. Please help.",
                    "intent": "Medication / urgent help",
                    "mood": "distressed",
                    "priority": "HIGH",
                    "audio_url": "gs://bucket/audio.webm",
                },
            )
        )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.body["priority"], VoiceRequestPriority.HIGH)
        self.assertEqual(len(response.body["notifications_created"]), 1)

    def test_acknowledge_route_updates_notification(self):
        service, repo, _ = BackendServiceTests().build_service()
        router = ApiRouter(service)
        service.process_voice_request_result("senior-1", "help", "urgent", "distressed", "HIGH")
        notification_id = next(iter(repo.notifications))

        response = router.handle(FakeRequest("POST", f"/notifications/{notification_id}/acknowledge"))

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.body["status"], NotificationStatus.ACKNOWLEDGED)

    def test_process_result_route_rejects_invalid_priority(self):
        service, _, _ = BackendServiceTests().build_service()
        router = ApiRouter(service)

        response = router.handle(
            FakeRequest(
                "POST",
                "/voice-requests/process-result",
                {
                    "senior_id": "senior-1",
                    "transcript": "hello",
                    "intent": "Routine",
                    "mood": "calm",
                    "priority": "LOW",
                },
            )
        )

        self.assertEqual(response.status_code, 400)


class OpenAITriageClientTests(unittest.TestCase):
    def test_parse_response_text_extracts_schema_payload(self):
        text = json.dumps(
            {
                "summary": "Mum asks about dinner.",
                "priority": "Not Emergency",
                "reasoning": "Routine social question.",
                "suggested_action": "Reply when available.",
            }
        )

        result = parse_response_text(text)

        self.assertEqual(result["priority"], Priority.NOT_EMERGENCY)
        self.assertEqual(result["summary"], "Mum asks about dinner.")

    def test_parse_response_text_accepts_legacy_priority_aliases(self):
        result = parse_response_text(
            '{"summary":"x","priority":"Green","reasoning":"x","suggested_action":"x"}'
        )

        self.assertEqual(result["priority"], Priority.NOT_EMERGENCY)

    def test_parse_response_text_rejects_unknown_priority(self):
        with self.assertRaises(TriageAnalysisError):
            parse_response_text('{"summary":"x","priority":"Blue","reasoning":"x","suggested_action":"x"}')

    def test_response_schema_enforces_priority_enum(self):
        schema = OpenAITriageClient.response_schema()

        self.assertEqual(
            schema["properties"]["priority"]["enum"],
            [Priority.EMERGENCY, Priority.NOT_EMERGENCY],
        )


if __name__ == "__main__":
    unittest.main()
