from __future__ import annotations

import os
from dataclasses import dataclass


DEFAULT_TRANSCRIPTION_PROMPT = (
    "Singapore elder-care voice note. Singlish context: Uncle, Auntie, Makan, "
    "Alamak, kopi, makan already, take medicine, fall down, chest pain."
)


@dataclass(frozen=True)
class Settings:
    openai_api_key: str | None
    text_model: str
    transcription_model: str
    transcription_prompt: str
    request_timeout_seconds: float
    high_priority_repeat_interval_seconds: int
    high_priority_max_sends: int
    enable_mock_notifications: bool

    @classmethod
    def from_env(cls) -> "Settings":
        return cls(
            openai_api_key=os.getenv("OPENAI_API_KEY"),
            text_model=os.getenv("OPENAI_TEXT_MODEL", "gpt-5.5"),
            transcription_model=os.getenv("OPENAI_TRANSCRIPTION_MODEL", "whisper-1"),
            transcription_prompt=os.getenv("OPENAI_TRANSCRIPTION_PROMPT", DEFAULT_TRANSCRIPTION_PROMPT),
            request_timeout_seconds=float(os.getenv("OPENAI_REQUEST_TIMEOUT_SECONDS", "4.0")),
            # TODO: Production high-priority repeats should use 120 seconds.
            high_priority_repeat_interval_seconds=int(os.getenv("HIGH_PRIORITY_REPEAT_INTERVAL_SECONDS", "10")),
            high_priority_max_sends=int(os.getenv("HIGH_PRIORITY_MAX_SENDS", "30")),
            enable_mock_notifications=os.getenv("ENABLE_MOCK_NOTIFICATIONS", "true").lower() != "false",
        )

