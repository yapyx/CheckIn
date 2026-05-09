from __future__ import annotations

from typing import Any

from .models import Priority


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
