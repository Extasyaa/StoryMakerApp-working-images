"""Utilities to manage release artifacts for generated videos."""
from __future__ import annotations

import os
import pathlib
import shutil
import subprocess
from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class ReleaseInfo:
    """Metadata about a generated release."""

    slug: str
    path: pathlib.Path
    status: str


class ReleaseManager:
    """Create folders with artifacts of generated stories."""

    def __init__(self, base_dir: str = "releases") -> None:
        self.base_dir = pathlib.Path(base_dir)
        self.base_dir.mkdir(parents=True, exist_ok=True)

    def create_release(
        self,
        story_path: str,
        images_dir: Optional[str],
        audio_path: Optional[str],
        video_path: Optional[str],
        scenes: int,
        audio_duration: float,
        status: str,
    ) -> ReleaseInfo:
        slug = datetime.now().strftime("%Y%m%d_%H%M%S")
        target = self.base_dir / slug
        target.mkdir(parents=True, exist_ok=True)

        # Copy story
        if story_path and os.path.exists(story_path):
            shutil.copy(story_path, target / "story.json")

        # Copy images directory
        if images_dir and os.path.isdir(images_dir):
            shutil.copytree(images_dir, target / "images")

        # Copy/convert audio
        if audio_path and os.path.exists(audio_path):
            audio_out = target / "audio.mp3"
            self._convert_to_mp3(audio_path, audio_out)

        # Copy video
        if video_path and os.path.exists(video_path):
            shutil.copy(video_path, target / "video.mp4")

        # Write report
        report = target / "report.md"
        with open(report, "w", encoding="utf-8") as fh:
            fh.write("# Release report\n\n")
            fh.write(f"Date: {datetime.now().isoformat()}\n")
            fh.write(f"Scenes: {scenes}\n")
            fh.write(f"Audio duration: {audio_duration:.2f} sec\n")
            if story_path:
                fh.write(f"Story: {target / 'story.json'}\n")
            if images_dir:
                fh.write(f"Images: {target / 'images'}\n")
            if audio_path:
                fh.write(f"Audio: {target / 'audio.mp3'}\n")
            if video_path:
                fh.write(f"Video: {target / 'video.mp4'}\n")
            fh.write(f"Status: {status}\n")

        return ReleaseInfo(slug=slug, path=target, status=status)

    def open_in_finder(self, release_path: str) -> None:
        """Open the given release directory in Finder (macOS)."""
        try:
            subprocess.run(["open", release_path], check=True)
        except Exception:
            pass

    def _convert_to_mp3(self, src: str, dst: pathlib.Path) -> None:
        try:
            subprocess.run(
                ["ffmpeg", "-y", "-i", src, dst],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            # Fallback to just copying if ffmpeg is unavailable
            shutil.copy(src, dst.with_suffix(".wav"))
