from __future__ import annotations

import json
from typing import Any

from .config import Settings
from .models import Priority


class TriageAnalysisError(RuntimeError):
    """Raised when the model response cannot be trusted for triage."""


TRIAGE_SYSTEM_PROMPT = """You are a medical dispatcher for an elder-care voice triage app.
Classify the senior's voice note using only the transcript and profile context.

Priority definitions:
- Emergency: acute physical pain, falls, chest pain, breathing trouble, stroke signs, confusion, medication danger, home safety danger, immediate threat, or anything too ambiguous to triage safely.
- Not Emergency: social check-ins, routine logistics, meals, groceries, non-urgent questions, or clearly low-risk comfort requests.

Return JSON that matches the provided schema. Keep the summary concise and actionable.
When uncertain, choose Emergency and tell the caregiver to review the raw audio or contact the senior directly."""


class OpenAITriageClient:
    def __init__(self, settings: Settings | None = None, client: Any = None):
        self.settings = settings or Settings.from_env()
        self._client = client

    @staticmethod
    def response_schema() -> dict[str, Any]:
        return {
            "type": "object",
            "additionalProperties": False,
            "required": ["summary", "priority", "reasoning", "suggested_action"],
            "properties": {
                "summary": {"type": "string", "minLength": 1},
                "priority": {"type": "string", "enum": list(Priority.ALL)},
                "reasoning": {"type": "string", "minLength": 1},
                "suggested_action": {"type": "string", "minLength": 1},
            },
        }

    @property
    def client(self) -> Any:
        if self._client is None:
            try:
                from openai import OpenAI
            except ImportError as exc:
                raise TriageAnalysisError("The openai package is not installed") from exc
            self._client = OpenAI(api_key=self.settings.openai_api_key, timeout=self.settings.request_timeout_seconds)
        return self._client

    def transcribe(self, audio_path: str) -> str:
        try:
            with open(audio_path, "rb") as audio_file:
                response = self.client.audio.transcriptions.create(
                    model=self.settings.transcription_model,
                    file=audio_file,
                    prompt=self.settings.transcription_prompt,
                    response_format="json",
                )
        except Exception as exc:
            raise TriageAnalysisError(f"Transcription failed: {exc}") from exc

        transcript = getattr(response, "text", None)
        if transcript is None and isinstance(response, dict):
            transcript = response.get("text")
        if not isinstance(transcript, str) or not transcript.strip():
            raise TriageAnalysisError("Transcription returned empty text")
        return transcript.strip()

    def analyze(self, transcript: str, profile_context: str) -> dict[str, str]:
        payload = {
            "transcript": transcript,
            "profile_context": profile_context or "No profile context available.",
        }
        try:
            response = self.client.responses.create(
                model=self.settings.text_model,
                input=[
                    {"role": "system", "content": TRIAGE_SYSTEM_PROMPT},
                    {"role": "user", "content": json.dumps(payload, ensure_ascii=True)},
                ],
                text={
                    "format": {
                        "type": "json_schema",
                        "name": "eldercare_triage_result",
                        "strict": True,
                        "schema": self.response_schema(),
                    }
                },
            )
        except Exception as exc:
            raise TriageAnalysisError(f"Triage inference failed: {exc}") from exc

        return parse_response_text(extract_output_text(response))


def extract_output_text(response: Any) -> str:
    output_text = getattr(response, "output_text", None)
    if isinstance(output_text, str) and output_text.strip():
        return output_text

    if isinstance(response, dict):
        output_text = response.get("output_text")
        if isinstance(output_text, str) and output_text.strip():
            return output_text
        output = response.get("output", [])
    else:
        output = getattr(response, "output", [])

    chunks: list[str] = []
    for item in output or []:
        content = item.get("content", []) if isinstance(item, dict) else getattr(item, "content", [])
        for part in content or []:
            text = part.get("text") if isinstance(part, dict) else getattr(part, "text", None)
            if isinstance(text, str):
                chunks.append(text)

    combined = "".join(chunks).strip()
    if not combined:
        raise TriageAnalysisError("Model response did not include output text")
    return combined


def parse_response_text(text: str) -> dict[str, str]:
    try:
        parsed = json.loads(text)
    except json.JSONDecodeError as exc:
        raise TriageAnalysisError("Model response was not valid JSON") from exc

    if not isinstance(parsed, dict):
        raise TriageAnalysisError("Model response JSON must be an object")

    required = ("summary", "priority", "reasoning", "suggested_action")
    for key in required:
        if not isinstance(parsed.get(key), str) or not parsed[key].strip():
            raise TriageAnalysisError(f"Model response missing '{key}'")

    priority = _normalize_priority(parsed["priority"])
    if priority not in Priority.ALL:
        raise TriageAnalysisError(f"Unknown priority '{parsed['priority']}'")

    return {
        "summary": parsed["summary"].strip(),
        "priority": priority,
        "reasoning": parsed["reasoning"].strip(),
        "suggested_action": parsed["suggested_action"].strip(),
    }


def _normalize_priority(priority: str) -> str:
    normalized = priority.strip().lower()
    for allowed in Priority.ALL:
        if normalized == allowed.lower():
            return allowed
    emergency_aliases = {"red", "amber", "grey", "gray", "urgent", "yes", "true"}
    not_emergency_aliases = {"green", "non-emergency", "non emergency", "routine", "no", "false"}
    if normalized in emergency_aliases:
        return Priority.EMERGENCY
    if normalized in not_emergency_aliases:
        return Priority.NOT_EMERGENCY
    return priority.strip()
