from __future__ import annotations

import json
import os
from datetime import datetime, timedelta, timezone
from typing import Any


class NoopRepeatScheduler:
    def schedule(self, message_id: str) -> None:
        return None


class CloudTasksRepeatScheduler:
    def __init__(
        self,
        project_id: str | None = None,
        location: str | None = None,
        queue_id: str | None = None,
        target_url: str | None = None,
        delay_seconds: int | None = None,
    ):
        self.project_id = (
            project_id
            or os.getenv("GCLOUD_PROJECT")
            or os.getenv("GCP_PROJECT")
            or os.getenv("GOOGLE_CLOUD_PROJECT")
        )
        self.location = location or os.getenv("FUNCTION_REGION", "asia-southeast1")
        self.queue_id = queue_id or os.getenv("EMERGENCY_REPEAT_QUEUE", "emergency-repeat")
        self.target_url = target_url or os.getenv("EMERGENCY_REPEAT_URL") or self._default_target_url()
        self.delay_seconds = delay_seconds or int(os.getenv("EMERGENCY_REPEAT_SECONDS", "3"))

    def schedule(self, message_id: str) -> None:
        if not self.project_id or not self.target_url:
            raise RuntimeError("Cloud Tasks repeat scheduler is missing project id or target URL")

        try:
            from google.cloud import tasks_v2
            from google.protobuf import timestamp_pb2
        except ImportError as exc:
            raise RuntimeError("google-cloud-tasks is required for emergency repeats") from exc

        client = tasks_v2.CloudTasksClient()
        parent = client.queue_path(self.project_id, self.location, self.queue_id)
        run_at = datetime.now(timezone.utc) + timedelta(seconds=self.delay_seconds)
        timestamp = timestamp_pb2.Timestamp()
        timestamp.FromDatetime(run_at)

        task: dict[str, Any] = {
            "http_request": {
                "http_method": tasks_v2.HttpMethod.POST,
                "url": self.target_url,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"message_id": message_id}).encode(),
            },
            "schedule_time": timestamp,
        }
        client.create_task(request={"parent": parent, "task": task})

    def _default_target_url(self) -> str | None:
        if not self.project_id:
            return None
        return (
            f"https://{self.location}-{self.project_id}.cloudfunctions.net/"
            "api/api/v1/notifications/emergency-repeat"
        )
