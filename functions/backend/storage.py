from __future__ import annotations

import os
import tempfile
from urllib.parse import urlparse


class FirebaseStorageGateway:
    def download(self, storage_path: str) -> str:
        try:
            from firebase_admin import storage
        except ImportError as exc:
            raise RuntimeError("firebase-admin is required for Firebase Storage access") from exc

        bucket_name, blob_name = parse_storage_path(storage_path)
        bucket = storage.bucket(bucket_name) if bucket_name else storage.bucket()
        blob = bucket.blob(blob_name)

        suffix = os.path.splitext(blob_name)[1] or ".webm"
        handle = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
        handle.close()
        blob.download_to_filename(handle.name)
        return handle.name


def parse_storage_path(storage_path: str) -> tuple[str | None, str]:
    if storage_path.startswith("gs://"):
        parsed = urlparse(storage_path)
        return parsed.netloc, parsed.path.lstrip("/")
    return None, storage_path.lstrip("/")

