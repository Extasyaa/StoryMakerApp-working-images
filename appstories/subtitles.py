import pysrt, os, pathlib
from moviepy.editor import AudioFileClip
def srt_from_chunks(chunks, out_srt):
    """
    chunks: list of dicts with keys: text, wav_path
    This function estimates naive durations from audio files.
    """
    subs = pysrt.SubRipFile()
    current = 0.0
    for i, ch in enumerate(chunks, 1):
        dur = AudioFileClip(ch["wav_path"]).duration
        start_s = current
        end_s = current + dur
        current = end_s
        subs.append(pysrt.SubRipItem(index=i,
                                     start=pysrt.SubRipTime(seconds=start_s),
                                     end=pysrt.SubRipTime(seconds=end_s),
                                     text=ch["text"]))
    pathlib.Path(os.path.dirname(out_srt)).mkdir(parents=True, exist_ok=True)
    subs.save(out_srt, encoding="utf-8")
    return out_srt
