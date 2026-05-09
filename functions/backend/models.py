from __future__ import annotations

from datetime import datetime
from typing import Any


class Priority:
    EMERGENCY = "Emergency"
    NOT_EMERGENCY = "Not Emergency"

    ALL = (EMERGENCY, NOT_EMERGENCY)
    SORT_ORDER = {
        EMERGENCY: 0,
        NOT_EMERGENCY: 1,
        # Legacy priorities can still exist in old Firestore documents.
        "Red": 0,
        "Amber": 0,
        "Grey": 0,
        "Green": 1,
        "": 2,
        None: 2,
    }


class MessageStatus:
    PROCESSING = "processing"
    UNREAD = "unread"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"

    ALL = (PROCESSING, UNREAD, ACKNOWLEDGED, RESOLVED)
    CAREGIVER_WRITABLE = (ACKNOWLEDGED, RESOLVED)


class UserRole:
    SENIOR = "senior"
    CAREGIVER = "caregiver"


def require_string(payload: dict[str, Any], key: str) -> str:
    value = payload.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"'{key}' is required")
    return value.strip()


def iso_or_value(value: Any) -> Any:
    if isinstance(value, datetime):
        return value.isoformat()
    return value


def public_message(message: dict[str, Any]) -> dict[str, Any]:
    return {key: iso_or_value(value) for key, value in message.items()}
