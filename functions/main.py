from __future__ import annotations

import os
from datetime import datetime
from typing import Any

from backend.ai import OpenAITriageClient
from backend.api import ApiRouter
from backend.notifications import FirebaseNotifier
from backend.repeat_scheduler import CloudTasksRepeatScheduler
from backend.repository import FirestoreRepository
from backend.service import TriageService
from backend.storage import FirebaseStorageGateway

FUNCTION_REGION = "asia-southeast1"

try:
    from firebase_functions import https_fn, storage_fn
except ImportError:
    https_fn = None
    storage_fn = None


def _initialize_firebase() -> None:
    try:
        import firebase_admin

        if not firebase_admin._apps:
            firebase_admin.initialize_app()
    except ImportError:
        return


def build_service() -> TriageService:
    _initialize_firebase()
    return TriageService(
        FirestoreRepository(),
        FirebaseStorageGateway(),
        OpenAITriageClient(),
        FirebaseNotifier(),
        CloudTasksRepeatScheduler(location=FUNCTION_REGION),
    )


def _api_impl(request: Any) -> tuple[str, int, dict[str, str]]:
    return ApiRouter(build_service()).handle(request).as_http()


def _process_audio_upload_impl(cloud_event: Any) -> dict[str, Any] | None:
    """Cloud Storage finalize entrypoint for uploaded audio files.

    Expects either object metadata `senior_id` or a path shaped like
    `triage_uploads/{senior_id}/{filename}`.
    """
    data = getattr(cloud_event, "data", cloud_event) or {}
    bucket = _event_value(data, "bucket")
    name = _event_value(data, "name")
    if not name:
        return None

    metadata = _event_value(data, "metadata") or {}
    senior_id = _event_value(metadata, "senior_id") or _senior_id_from_path(name)
    if not senior_id:
        raise ValueError("Uploaded object must include senior_id metadata or path")

    storage_path = f"gs://{bucket}/{name}" if bucket else name
    uploaded_at = _parse_time(_event_value(data, "timeCreated") or _event_value(data, "time_created"))
    return build_service().process_storage_event(storage_path, senior_id, uploaded_at)


def _storage_trigger_can_register() -> bool:
    if _configured_storage_bucket():
        return True
    firebase_config = os.getenv("FIREBASE_CONFIG", "")
    return "storageBucket" in firebase_config


def _configured_storage_bucket() -> str | None:
    return os.getenv("STORAGE_BUCKET") or os.getenv("FIREBASE_STORAGE_BUCKET")


def _senior_id_from_path(path: str) -> str | None:
    parts = path.strip("/").split("/")
    if len(parts) >= 3 and parts[0] == "triage_uploads":
        return parts[1]
    return os.getenv("DEFAULT_SENIOR_ID")


def _parse_time(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def _event_value(data: Any, key: str) -> Any:
    if isinstance(data, dict):
        return data.get(key)
    return getattr(data, key, None)


if https_fn is not None:
    @https_fn.on_request(region=FUNCTION_REGION)
    def api(req: Any) -> Any:
        return _api_impl(req)
else:
    def api(request: Any) -> tuple[str, int, dict[str, str]]:
        return _api_impl(request)


if storage_fn is not None and _storage_trigger_can_register():
    storage_bucket = _configured_storage_bucket()

    if storage_bucket:
        @storage_fn.on_object_finalized(bucket=storage_bucket, region=FUNCTION_REGION)
        def process_audio_upload(event: Any) -> Any:
            return _process_audio_upload_impl(event)
    else:
        @storage_fn.on_object_finalized(region=FUNCTION_REGION)
        def process_audio_upload(event: Any) -> Any:
            return _process_audio_upload_impl(event)
else:
    def process_audio_upload(cloud_event: Any) -> dict[str, Any] | None:
        return _process_audio_upload_impl(cloud_event)
