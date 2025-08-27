from __future__ import annotations
import argparse, os, tempfile
from pathlib import Path
from importlib.metadata import version, PackageNotFoundError
from typing import List

from .video import smoke_render, render_images_to_video
from .images import generate_image_bytes


# ----------------------------- utils ----------------------------- #

def _ver(pkg: str) -> str:
    try:
        return version(pkg)
    except PackageNotFoundError:
        return "<not installed>"


# ----------------------------- commands ----------------------------- #

def cmd_doctor(_args) -> int:
    import sys
    print("Python:", sys.executable, sys.version)
    for p in ("moviepy", "decorator", "numpy", "pillow", "imageio", "imageio-ffmpeg", "audioop-lts", "requests"):
        print(f"{p}: {_ver(p)}")
    from .ffmpeg_util import resolve_ffmpeg
    try:
        print("ffmpeg:", resolve_ffmpeg())
        print("Doctor: OK")
        return 0
    except Exception as e:
        print("Doctor: FAIL", e)
        return 2


def cmd_smoke(args) -> int:
    p = smoke_render(args.out)
    print("Rendered:", p)
    return 0


def _split_prompts_semicolon(s: str) -> List[str]:
    """
    Делит одну длинную строку по ';'.
    Игнорирует пустые элементы. Переводы строк допустимы — они сохраняются
    внутри каждого отдельного промта (т.е. промт может быть многострочным).
    """
    # Нормализуем разные типы переносов строк, убираем BOM и пр.
    s = s.replace("\r\n", "\n").replace("\r", "\n").strip("\ufeff")
    parts = [p.strip() for p in s.split(";")]
    return [p for p in parts if p]  # убираем пустые


def cmd_render_images(args) -> int:
    """
    Генерация картинок и сборка в mp4.

    Варианты входа:
      • --prompt "один общий prompt"  + --num N
      • --prompts  "p1; p2; p3"       (список промтов через ';', промты могут быть многострочными)

    Дополнительно:
      • --aspect       → уходит провайдеру (для Grok важнее, чем size)
      • --durations    → список секунд для каждого кадра
      • --seconds      → общая длительность одного кадра (если durations не задан)
      • --fps, --size, --provider, --out
    """
    provider: str = args.provider
    size: str = args.size
    aspect = args.aspect if args.aspect else None

    # 1) Собираем список промтов и число кадров
    if args.prompts is not None:
        prompts: List[str] = _split_prompts_semicolon(args.prompts)
        if not prompts:
            raise SystemExit("No prompts provided (after splitting by ';').")
        num = len(prompts)
    else:
        prompts = [args.prompt]
        num = int(args.num)

    seconds: float = float(args.seconds)
    fps: int = int(args.fps)
    out: str = args.out

    # 2) Генерация картинок
    tmp = Path(tempfile.mkdtemp(prefix="appstories_imgs_"))
    paths: List[str] = []
    for i in range(num):
        pr = prompts[i] if i < len(prompts) else prompts[-1]
        img = generate_image_bytes(pr, provider=provider, image_size=size, aspect_ratio=aspect)
        p = tmp / f"img_{i:02d}.png"
        p.write_bytes(img)
        paths.append(str(p))
        print("saved:", p)

    # 3) Длительности (опционально)
    durations = [float(x) for x in (args.durations or [])] if args.durations else None

    # 4) Сборка видео
    video = render_images_to_video(paths, out, each_sec=seconds, fps=fps, durations=durations)
    print("Video:", video)
    return 0


# ----------------------------- entrypoint ----------------------------- #

def main(argv=None) -> int:
    ap = argparse.ArgumentParser("appstories")
    sub = ap.add_subparsers(dest="cmd", required=True)

    s1 = sub.add_parser("doctor")
    s1.add_argument("--out", default="releases/doctor.txt")
    s1.set_defaults(func=cmd_doctor)

    s2 = sub.add_parser("smoke")
    s2.add_argument("--out", default="releases/smoke_test.mp4")
    s2.set_defaults(func=cmd_smoke)

    s3 = sub.add_parser("render-images", help="Generate images then assemble to mp4")

    # Взаимоисключающая группа: либо один общий prompt, либо список через ';'
    mg = s3.add_mutually_exclusive_group(required=True)
    mg.add_argument("--prompt", help="один общий prompt")
    mg.add_argument("--prompts", help="список промтов через ';' (каждый промт может быть многострочным)")

    s3.add_argument("--num", type=int, default=3, help="кол-во кадров (используется только с --prompt)")
    s3.add_argument("--seconds", type=float, default=2.0, help="общая длительность кадра, если --durations не задан")
    s3.add_argument("--fps", type=int, default=24)
    s3.add_argument("--durations", nargs="+", type=float,
                    help="перечень секунд для каждого кадра (через пробел/запятые, пример: 2 1.5 3)")
    s3.add_argument("--size", default=os.getenv("XAI_IMAGE_SIZE", os.getenv("OPENAI_IMAGE_SIZE", "1024x1024")))
    s3.add_argument("--aspect", default=os.getenv("XAI_ASPECT_RATIO", os.getenv("OPENAI_ASPECT_RATIO", "")))
    s3.add_argument("--provider", choices=["grok", "openai", "fallback"], default=os.getenv("IMAGE_PROVIDER", "grok"))
    s3.add_argument("--out", default="releases/out.mp4")
    s3.set_defaults(func=cmd_render_images)

    a = ap.parse_args(argv)
    return a.func(a)


if __name__ == "__main__":
    raise SystemExit(main())
