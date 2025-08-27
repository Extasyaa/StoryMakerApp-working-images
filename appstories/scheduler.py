"""Launchd-based scheduling utilities."""
from __future__ import annotations

import os
import pathlib
import plistlib
import subprocess
from dataclasses import dataclass, field
from typing import List

LAUNCH_AGENTS = pathlib.Path.home() / "Library" / "LaunchAgents"
BUNDLE_PREFIX = "com.storymaker"


@dataclass
class ScheduleRule:
    profile_id: str
    time: str  # HH:MM
    days: List[str] = field(default_factory=lambda: ["*"])
    enabled: bool = True

    @property
    def plist_path(self) -> pathlib.Path:
        return LAUNCH_AGENTS / f"{BUNDLE_PREFIX}.{self.profile_id}.plist"


DAY_MAP = {
    "mon": 1,
    "tue": 2,
    "wed": 3,
    "thu": 4,
    "fri": 5,
    "sat": 6,
    "sun": 0,
}


def _day_to_int(day: str) -> int:
    return DAY_MAP.get(day.lower(), -1)


def install_rule(rule: ScheduleRule) -> None:
    """Create and load a launchd plist for the rule."""
    LAUNCH_AGENTS.mkdir(parents=True, exist_ok=True)
    hour, minute = [int(x) for x in rule.time.split(":", 1)]
    interval = {"Hour": hour, "Minute": minute}
    weekdays = [_day_to_int(d) for d in rule.days if d != "*"]
    if weekdays:
        interval["Weekday"] = weekdays
    plist = {
        "Label": f"{BUNDLE_PREFIX}.{rule.profile_id}",
        "ProgramArguments": ["/usr/local/bin/storymaker", f"--run-pipeline={rule.profile_id}"],
        "StartCalendarInterval": interval,
    }
    with open(rule.plist_path, "wb") as fh:
        plistlib.dump(plist, fh)
    if rule.enabled:
        try:
            subprocess.run(["launchctl", "load", str(rule.plist_path)], check=True)
        except Exception:
            pass


def remove_rule(profile_id: str) -> None:
    plist = LAUNCH_AGENTS / f"{BUNDLE_PREFIX}.{profile_id}.plist"
    if plist.exists():
        try:
            subprocess.run(["launchctl", "unload", str(plist)], check=True)
        except Exception:
            pass
        plist.unlink()


def run_now(profile_id: str) -> None:
    """Run the pipeline immediately for the given profile."""
    try:
        subprocess.run(["launchctl", "start", f"{BUNDLE_PREFIX}.{profile_id}"], check=True)
    except Exception:
        # Fallback to running the binary directly
        subprocess.run(["/usr/local/bin/storymaker", f"--run-pipeline={profile_id}"])
