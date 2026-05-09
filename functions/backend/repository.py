from __future__ import annotations

import secrets
import string
from datetime import datetime, timezone
from typing import Any

from .models import MessageStatus, UserRole


class FirestoreRepository:
    def __init__(self, client: Any = None):
        self._client = client

    @property
    def client(self) -> Any:
        if self._client is None:
            try:
                from firebase_admin import firestore
            except ImportError as exc:
                raise RuntimeError("firebase-admin is required for Firestore access") from exc
            self._client = firestore.client()
        return self._client

    def create_triage_message(self, senior_id: str, storage_path: str, uploaded_at: datetime | None = None) -> str:
        now = self._server_timestamp()
        document = {
            "senior_id": senior_id,
            "audio_url": storage_path,
            "transcript": "",
            "summary": "",
            "priority": "",
            "suggested_action": "",
            "reasoning": "",
            "status": MessageStatus.PROCESSING,
            "created_at": uploaded_at or now,
            "updated_at": now,
        }
        doc_ref = self.client.collection("triage_messages").document()
        doc_ref.set(document)
        return doc_ref.id

    def get_message(self, message_id: str) -> dict[str, Any] | None:
        snapshot = self.client.collection("triage_messages").document(message_id).get()
        if not snapshot.exists:
            return None
        message = snapshot.to_dict()
        message["id"] = snapshot.id
        return message

    def update_message(self, message_id: str, fields: dict[str, Any]) -> None:
        update = dict(fields)
        update["updated_at"] = self._server_timestamp()
        self.client.collection("triage_messages").document(message_id).update(update)

    def create_user(self, uid: str, fields: dict[str, Any]) -> dict[str, Any]:
        existing = self.get_user(uid)
        if existing:
            raise ValueError("user_id already exists")

        now = self._server_timestamp()
        document = dict(fields)
        document.update(
            {
                "linked_accounts": document.get("linked_accounts", []),
                "profile_context": document.get("profile_context", ""),
                "fcm_tokens": document.get("fcm_tokens", []),
                "created_at": now,
                "updated_at": now,
            }
        )
        if document.get("role") == UserRole.SENIOR and not document.get("pairing_code"):
            document["pairing_code"] = self.generate_pairing_code()

        self.client.collection("users").document(uid).set(document)
        document["id"] = uid
        return document

    def get_user(self, uid: str) -> dict[str, Any] | None:
        snapshot = self.client.collection("users").document(uid).get()
        if not snapshot.exists:
            return None
        user = snapshot.to_dict()
        user["id"] = snapshot.id
        return user

    def find_senior_by_pairing_code(self, pairing_code: str) -> str | None:
        direct = self.get_user(pairing_code)
        if direct and direct.get("role") == UserRole.SENIOR:
            return pairing_code

        query = (
            self.client.collection("users")
            .where("role", "==", UserRole.SENIOR)
            .where("pairing_code", "==", pairing_code)
            .limit(1)
            .stream()
        )
        for snapshot in query:
            return snapshot.id
        return None

    def link_accounts(self, caregiver_id: str, senior_id: str) -> None:
        from firebase_admin import firestore

        caregiver_ref = self.client.collection("users").document(caregiver_id)
        senior_ref = self.client.collection("users").document(senior_id)
        caregiver_ref.update({"linked_accounts": firestore.ArrayUnion([senior_id])})
        senior_ref.update({"linked_accounts": firestore.ArrayUnion([caregiver_id])})

    def update_senior_context(self, senior_id: str, context: str) -> None:
        self.client.collection("users").document(senior_id).update({"profile_context": context})

    def add_fcm_token(self, uid: str, token: str) -> None:
        from firebase_admin import firestore

        self.client.collection("users").document(uid).update({"fcm_tokens": firestore.ArrayUnion([token])})

    def list_messages_for_caregiver(self, caregiver_id: str, status: str | None = None, limit: int = 20) -> list[dict[str, Any]]:
        caregiver = self.get_user(caregiver_id)
        if not caregiver:
            return []

        senior_ids = caregiver.get("linked_accounts", [])
        if not senior_ids:
            return []

        messages: list[dict[str, Any]] = []
        for senior_id in senior_ids:
            query = self.client.collection("triage_messages").where("senior_id", "==", senior_id)
            if status:
                query = query.where("status", "==", status)
            for snapshot in query.limit(limit).stream():
                message = snapshot.to_dict()
                message["id"] = snapshot.id
                messages.append(message)
        return messages

    def get_caregiver_tokens_for_senior(self, senior_id: str) -> list[str]:
        senior = self.get_user(senior_id)
        if not senior:
            return []

        tokens: list[str] = []
        for linked_uid in senior.get("linked_accounts", []):
            user = self.get_user(linked_uid)
            if user and user.get("role") == UserRole.CAREGIVER:
                tokens.extend(user.get("fcm_tokens", []))
        return tokens

    def _server_timestamp(self) -> Any:
        try:
            from firebase_admin import firestore

            return firestore.SERVER_TIMESTAMP
        except Exception:
            return datetime.now(timezone.utc)

    def generate_pairing_code(self) -> str:
        alphabet = string.ascii_uppercase + string.digits
        while True:
            code = "CI-" + "".join(secrets.choice(alphabet) for _ in range(6))
            if not self.find_senior_by_pairing_code(code):
                return code

