from __future__ import annotations

from typing import Any

from .models import Priority, VoiceRequestPriority


class MockNotificationSender:
    """Development sender that records/logs payloads instead of using FCM/SMS."""

    def __init__(self):
        self.sent: list[dict[str, Any]] = []

    def send(self, payload: dict[str, Any]) -> dict[str, Any]:
        # TODO: Replace with Firebase Cloud Messaging, SMS, or email integration.
        self.sent.append(payload)
        return {"sent": True, "payload": payload}

    def notify_caregivers(self, tokens: list[str], message: dict[str, Any]) -> None:
        # Compatibility for the older triage notification path.
        self.send({"tokens": tokens, "message": message})


def notification_payload(notification: dict[str, Any], senior: dict[str, Any] | None = None) -> dict[str, Any]:
    priority = notification.get("priority", VoiceRequestPriority.STANDARD)
    senior_name = (senior or {}).get("display_name") or notification.get("senior_name") or "Senior"
    repeat = bool(notification.get("repeat_until_acknowledged"))
    if priority == VoiceRequestPriority.HIGH:
        return {
            "type": "HIGH_PRIORITY_ALERT",
            "title": "Urgent request from senior",
            "body": f"{senior_name} may need immediate attention",
            "priority": VoiceRequestPriority.HIGH,
            "repeat": repeat,
            "notification_id": notification.get("id"),
            "senior_id": notification.get("senior_id"),
            "caregiver_id": notification.get("caregiver_id"),
        }
    return {
        "type": "STANDARD_MESSAGE",
        "title": "New message from senior",
        "body": f"{senior_name} sent a new message",
        "priority": VoiceRequestPriority.STANDARD,
        "repeat": False,
        "notification_id": notification.get("id"),
        "senior_id": notification.get("senior_id"),
        "caregiver_id": notification.get("caregiver_id"),
    }


class FirebaseNotifier:
    def notify_caregivers(self, tokens: list[str], message: dict[str, Any]) -> None:
        if not tokens:
            return

        try:
            from firebase_admin import messaging
        except ImportError as exc:
            raise RuntimeError("firebase-admin is required for FCM notifications") from exc

        priority = message.get("priority", Priority.EMERGENCY)
        senior_name = message.get("senior_name") or "Mum"
        title = f"Triage [{priority.upper()}]: {senior_name}"
        summary = message.get("summary") or "Voice message needs review."
        android_channel_id = "Emergency" if priority == Priority.EMERGENCY else "CaregiverUpdates"

        multicast = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(title=title, body=summary),
            data={
                "message_id": str(message.get("id") or message.get("message_id") or ""),
                "priority": str(priority),
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
            },
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(channel_id=android_channel_id),
            ),
        )
        messaging.send_each_for_multicast(multicast)
