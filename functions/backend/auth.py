from __future__ import annotations

import base64
import hashlib
import hmac
import secrets


PBKDF2_ITERATIONS = 260_000


def hash_password(password: str) -> dict[str, str | int]:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PBKDF2_ITERATIONS)
    return {
        "password_hash": base64.b64encode(digest).decode("ascii"),
        "password_salt": base64.b64encode(salt).decode("ascii"),
        "password_iterations": PBKDF2_ITERATIONS,
    }


def verify_password(password: str, user: dict[str, object]) -> bool:
    stored_hash = user.get("password_hash")
    stored_salt = user.get("password_salt")
    iterations = user.get("password_iterations", PBKDF2_ITERATIONS)
    if not isinstance(stored_hash, str) or not isinstance(stored_salt, str):
        return False

    try:
        salt = base64.b64decode(stored_salt.encode("ascii"), validate=True)
        expected = base64.b64decode(stored_hash.encode("ascii"), validate=True)
        iteration_count = int(iterations)
    except Exception:
        return False

    candidate = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, iteration_count)
    return hmac.compare_digest(candidate, expected)
