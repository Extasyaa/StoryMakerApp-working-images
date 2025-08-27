"""Place-holder integrations for future uploads."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict


@dataclass
class IntegrationBase:
    enabled: bool = False
    oauth: Dict[str, str] = field(default_factory=dict)

    def run(self, *_, **__):  # pragma: no cover - placeholder
        raise RuntimeError("Integration disabled")


class YouTubeUpload(IntegrationBase):
    pass


class DriveUpload(IntegrationBase):
    pass


class TelegramIntegration(IntegrationBase):
    pass
