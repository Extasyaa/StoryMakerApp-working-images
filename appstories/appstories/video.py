from __future__ import annotations
import os
from typing import List, Optional

from moviepy.editor import ColorClip, ImageClip, concatenate_videoclips
from .ffmpeg_util import resolve_ffmpeg


def _ensure_ffmpeg_env():
    ff = resolve_ffmpeg()
    os.environ.setdefault("IMAGEIO_FFMPEG_EXE", ff)


def smoke_render(out_path: str) -> str:
    _ensure_ffmpeg_env()
    clip = ColorClip(size=(320, 240), color=(20, 20, 20), duration=2)
    clip.write_videofile(out_path, fps=24, codec="libx264",
                         audio=False, verbose=False, logger=None)
    return out_path


def render_images_to_video(
    image_paths: List[str],
    out_path: str,
    each_sec: float = 2.0,
    fps: int = 24,
    durations: Optional[List[float]] = None,
) -> str:
    """
    Склеиваем изображения в mp4.
    - Если durations передан, его длина должна соответствовать количеству кадров;
      лишнее игнорируем, недостающее добиваем значением each_sec.
    - Иначе используется равномерная длительность each_sec.
    """
    _ensure_ffmpeg_env()

    clips: List[ImageClip] = []
    if durations:
        durs = list(durations) + [each_sec] * max(0, len(image_paths) - len(durations))
        for p, d in zip(image_paths, durs):
            clips.append(ImageClip(p).set_duration(float(d)))
    else:
        for p in image_paths:
            clips.append(ImageClip(p).set_duration(each_sec))

    final = concatenate_videoclips(clips, method="compose")
    final.write_videofile(out_path, fps=fps, codec="libx264",
                          audio=False, verbose=False, logger=None)
    return out_path
