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

    @classmethod
    def from_env(cls) -> "Settings":
        return cls(
            openai_api_key=os.getenv("OPENAI_API_KEY"),
            text_model=os.getenv("OPENAI_TEXT_MODEL", "gpt-5.5"),
            transcription_model=os.getenv("OPENAI_TRANSCRIPTION_MODEL", "whisper-1"),
            transcription_prompt=os.getenv("OPENAI_TRANSCRIPTION_PROMPT", DEFAULT_TRANSCRIPTION_PROMPT),
            request_timeout_seconds=float(os.getenv("OPENAI_REQUEST_TIMEOUT_SECONDS", "4.0")),
        )

