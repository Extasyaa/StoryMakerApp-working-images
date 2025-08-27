"""Simple wrapper around macOS notifications."""
from __future__ import annotations

import subprocess


def notify(title: str, message: str) -> None:
    """Send a user notification on macOS.

    Falls back to printing when notification utilities are unavailable."""
    script = f'display notification "{message}" with title "{title}"'
    try:
        subprocess.run(["osascript", "-e", script], check=True)
    except Exception:
        # Fallback for non-macOS environments
        print(f"{title}: {message}")
