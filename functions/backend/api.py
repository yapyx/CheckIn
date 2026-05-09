from __future__ import annotations

import json
import re
from dataclasses import dataclass
from typing import Any

from .models import require_string


@dataclass
class JsonResponse:
    body: dict[str, Any] | list[dict[str, Any]]
    status_code: int = 200

    def as_http(self) -> tuple[str, int, dict[str, str]]:
        return (
            json.dumps(self.body, ensure_ascii=True),
            self.status_code,
            {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET,POST,PUT,PATCH,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type,Authorization",
            },
        )


class ApiRouter:
    def __init__(self, service: Any):
        self.service = service

    def handle(self, request: Any) -> JsonResponse:
        if request.method == "OPTIONS":
            return JsonResponse({}, 204)

        try:
            return self._dispatch(request)
        except ValueError as exc:
            return JsonResponse({"error": str(exc)}, 400)
        except Exception as exc:
            return JsonResponse({"error": "Internal server error", "detail": str(exc)}, 500)

    def _dispatch(self, request: Any) -> JsonResponse:
        path = _normalized_path(getattr(request, "path", ""))
        method = request.method.upper()
        body = _json_body(request)

        if method == "POST" and path == "/api/v1/auth/signup":
            return JsonResponse(
                self.service.signup(
                    require_string(body, "role"),
                    require_string(body, "user_id"),
                    require_string(body, "password"),
                    str(body.get("display_name", "")),
                    str(body.get("profile_context", "")),
                    str(body.get("occupation", "")),
                ),
                201,
            )

        if method == "POST" and path == "/api/v1/auth/login":
            return JsonResponse(
                self.service.login(
                    require_string(body, "user_id"),
                    require_string(body, "password"),
                )
            )

        if method == "POST" and path == "/api/v1/triage/ingest":
            result = self.service.ingest(
                require_string(body, "senior_id"),
                require_string(body, "storage_path"),
            )
            return JsonResponse(result, 202)

        if method == "POST" and path == "/api/v1/triage/transcribe":
            return JsonResponse(self.service.transcribe(require_string(body, "message_id")))

        if method == "POST" and path == "/api/v1/triage/analyze":
            return JsonResponse(self.service.analyze(require_string(body, "message_id")))

        if method == "GET" and path == "/api/v1/messages/feed":
            args = getattr(request, "args", {}) or {}
            limit = int(args.get("limit", 20))
            status = args.get("status")
            caregiver_id = args.get("caregiver_id")
            if not caregiver_id:
                raise ValueError("'caregiver_id' is required")
            return JsonResponse(self.service.feed(caregiver_id, status, limit))

        status_match = re.fullmatch(r"/api/v1/messages/([^/]+)/status", path)
        if method == "PATCH" and status_match:
            return JsonResponse(
                self.service.update_status(
                    status_match.group(1),
                    require_string(body, "status"),
                    str(body.get("action_taken", "")),
                )
            )

        fcm_match = re.fullmatch(r"/api/v1/users/([^/]+)/fcm-token", path)
        if method == "POST" and fcm_match:
            return JsonResponse(
                self.service.register_fcm_token(
                    fcm_match.group(1),
                    require_string(body, "token"),
                )
            )

        if method == "POST" and path == "/api/v1/users/link":
            return JsonResponse(
                self.service.link_users(
                    require_string(body, "caregiver_id"),
                    require_string(body, "senior_pairing_code"),
                )
            )

        context_match = re.fullmatch(r"/api/v1/users/([^/]+)/context", path)
        if method == "PUT" and context_match:
            return JsonResponse(
                self.service.update_context(
                    context_match.group(1),
                    require_string(body, "routine_context"),
                )
            )

        if method == "POST" and path == "/api/v1/system/dead-letter":
            return JsonResponse(
                self.service.dead_letter(
                    require_string(body, "message_id"),
                    str(body.get("error", "")),
                )
            )

        if method == "POST" and path == "/api/v1/notifications/emergency-repeat":
            return JsonResponse(
                self.service.repeat_emergency_notification(
                    require_string(body, "message_id"),
                )
            )

        return JsonResponse({"error": "Not found"}, 404)


def _json_body(request: Any) -> dict[str, Any]:
    body = request.get_json(silent=True) if hasattr(request, "get_json") else None
    if body is None:
        return {}
    if not isinstance(body, dict):
        raise ValueError("JSON body must be an object")
    return body


def _normalized_path(path: str) -> str:
    if not path:
        return "/"
    return "/" + path.strip("/")

