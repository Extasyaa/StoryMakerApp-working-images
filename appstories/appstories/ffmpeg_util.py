import shutil
def resolve_ffmpeg() -> str:
    p = shutil.which("ffmpeg")
    if p: return p
    from imageio_ffmpeg import get_ffmpeg_exe
    return get_ffmpeg_exe()
