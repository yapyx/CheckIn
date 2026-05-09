from __future__ import annotations

from datetime import datetime
from typing import Any

from .ai import TriageAnalysisError
from .auth import hash_password, verify_password
from .models import MessageStatus, Priority, UserRole, public_message, public_user


EMERGENCY_FALLBACK = {
    "summary": "The voice message could not be triaged safely.",
    "priority": Priority.EMERGENCY,
    "reasoning": "AI processing failed or confidence was insufficient.",
    "suggested_action": "Review the raw audio and contact the senior directly.",
}


class TriageService:
    def __init__(self, repository: Any, storage: Any, ai_client: Any, notifier: Any):
        self.repository = repository
        self.storage = storage
        self.ai_client = ai_client
        self.notifier = notifier

    def ingest(self, senior_id: str, storage_path: str, uploaded_at: datetime | None = None) -> dict[str, str]:
        senior = self.repository.get_user(senior_id)
        if not senior:
            raise ValueError("senior_id does not exist")
        if senior.get("role") != UserRole.SENIOR:
            raise ValueError("senior_id must belong to a senior user")
        message_id = self.repository.create_triage_message(senior_id, storage_path, uploaded_at)
        return {"message_id": message_id, "status": MessageStatus.PROCESSING}

    def signup(
        self,
        role: str,
        user_id: str,
        password: str,
        display_name: str = "",
        profile_context: str = "",
        occupation: str = "",
    ) -> dict[str, Any]:
        if role not in UserRole.ALL:
            raise ValueError("role must be senior or caregiver")
        if "/" in user_id or len(user_id) > 120:
            raise ValueError("user_id must be a simple id without slashes")
        if len(password) < 8:
            raise ValueError("password must be at least 8 characters")

        fields: dict[str, Any] = {
            "role": role,
            "display_name": display_name.strip(),
            "profile_context": profile_context.strip(),
            "occupation": occupation.strip(),
            "fcm_tokens": [],
            "linked_accounts": [],
            **hash_password(password),
        }
        user = self.repository.create_user(user_id, fields)
        return {"user": public_user(user)}

    def login(self, user_id: str, password: str) -> dict[str, Any]:
        if "/" in user_id or len(user_id) > 120:
            raise ValueError("Invalid user id or password")
        user = self.repository.get_user(user_id)
        if not user or not verify_password(password, user):
            raise ValueError("Invalid user id or password")
        return {"user": public_user(user)}

    def transcribe(self, message_id: str) -> dict[str, Any]:
        message = self._get_message_or_raise(message_id)
        audio_path = self.storage.download(message["audio_url"])
        transcript = self.ai_client.transcribe(audio_path)
        self.repository.update_message(message_id, {"transcript": transcript})
        updated = self._get_message_or_raise(message_id)
        return public_message(updated)

    def analyze(self, message_id: str) -> dict[str, Any]:
        message = self._get_message_or_raise(message_id)
        senior = self.repository.get_user(message["senior_id"]) or {}
        transcript = message.get("transcript", "")

        fallback_error = ""
        try:
            if not transcript.strip():
                raise TriageAnalysisError("Transcript is empty")
            result = self.ai_client.analyze(transcript, senior.get("profile_context", ""))
            if result.get("priority") not in Priority.ALL:
                raise TriageAnalysisError("Priority outside allowed enum")
        except Exception as exc:
            fallback_error = str(exc)
            result = dict(EMERGENCY_FALLBACK)

        update = {
            "summary": result["summary"],
            "priority": result["priority"],
            "reasoning": result["reasoning"],
            "suggested_action": result["suggested_action"],
            "status": MessageStatus.UNREAD,
        }
        if fallback_error:
            update["error"] = fallback_error
        self.repository.update_message(message_id, update)
        updated = self._get_message_or_raise(message_id)
        self._notify(updated)
        return public_message(updated)

    def process_message(self, message_id: str) -> dict[str, Any]:
        try:
            self.transcribe(message_id)
        except Exception as exc:
            return self.dead_letter(message_id, str(exc))
        return self.analyze(message_id)

    def process_storage_event(self, storage_path: str, senior_id: str, uploaded_at: datetime | None = None) -> dict[str, Any]:
        ingest_result = self.ingest(senior_id, storage_path, uploaded_at)
        return self.process_message(ingest_result["message_id"])

    def feed(self, caregiver_id: str, status: str | None, limit: int = 20) -> list[dict[str, Any]]:
        if status and status not in MessageStatus.ALL:
            raise ValueError("Invalid status filter")
        safe_limit = max(1, min(int(limit), 100))
        messages = self.repository.list_messages_for_caregiver(caregiver_id, status, safe_limit)
        messages.sort(key=lambda item: (Priority.SORT_ORDER.get(item.get("priority"), 4), _timestamp_sort(item.get("created_at"))))
        return [public_message(message) for message in messages[:safe_limit]]

    def update_status(self, message_id: str, status: str, action_taken: str = "") -> dict[str, bool]:
        if status not in MessageStatus.CAREGIVER_WRITABLE:
            raise ValueError("Status must be acknowledged or resolved")
        self._get_message_or_raise(message_id)
        self.repository.update_message(message_id, {"status": status, "action_taken": action_taken})
        return {"success": True}

    def link_users(self, caregiver_id: str, senior_pairing_code: str) -> dict[str, str]:
        caregiver = self.repository.get_user(caregiver_id)
        if not caregiver:
            raise ValueError("caregiver_id does not exist")
        if caregiver.get("role") != UserRole.CAREGIVER:
            raise ValueError("caregiver_id must belong to a caregiver user")
        senior_id = self.repository.find_senior_by_pairing_code(senior_pairing_code)
        if not senior_id:
            raise ValueError("senior_pairing_code is invalid")
        self.repository.link_accounts(caregiver_id, senior_id)
        return {"linked_senior_id": senior_id}

    def update_context(self, senior_id: str, context: str) -> dict[str, bool]:
        senior = self.repository.get_user(senior_id)
        if not senior:
            raise ValueError("senior_id does not exist")
        if senior.get("role") != UserRole.SENIOR:
            raise ValueError("senior_id must belong to a senior user")
        self.repository.update_senior_context(senior_id, context)
        return {"success": True}

    def dead_letter(self, message_id: str, error: str = "") -> dict[str, Any]:
        self._get_message_or_raise(message_id)
        update = dict(EMERGENCY_FALLBACK)
        update.update({"status": MessageStatus.UNREAD, "error": error})
        self.repository.update_message(message_id, update)
        updated = self._get_message_or_raise(message_id)
        self._notify(updated)
        return public_message(updated)

    def _notify(self, message: dict[str, Any]) -> None:
        tokens = self.repository.get_caregiver_tokens_for_senior(message["senior_id"])
        try:
            self.notifier.notify_caregivers(tokens, message)
        except Exception as exc:
            self.repository.update_message(message["id"], {"notification_error": str(exc)})

    def _get_message_or_raise(self, message_id: str) -> dict[str, Any]:
        message = self.repository.get_message(message_id)
        if not message:
            raise ValueError("message_id does not exist")
        return message


def _timestamp_sort(value: Any) -> float:
    if isinstance(value, datetime):
        return -value.timestamp()
    if isinstance(value, str):
        try:
            return -datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
        except ValueError:
            return 0
    return 0
