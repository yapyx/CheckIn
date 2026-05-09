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
        is_emergency = priority == Priority.EMERGENCY
        android_channel_id = "Emergency" if is_emergency else "CaregiverUpdates"

        multicast = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(title=title, body=summary),
            data={
                "message_id": str(message.get("id") or message.get("message_id") or ""),
                "priority": str(priority),
                "repeat": "true" if is_emergency else "false",
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
            },
            android=messaging.AndroidConfig(
                priority="high" if is_emergency else "normal",
                notification=messaging.AndroidNotification(
                    channel_id=android_channel_id,
                    priority="max" if is_emergency else "default",
                    vibrate_timings_millis=(
                        [0, 800, 250, 800, 250, 1200] if is_emergency else None
                    ),
                ),
            ),
        )
        messaging.send_each_for_multicast(multicast)
