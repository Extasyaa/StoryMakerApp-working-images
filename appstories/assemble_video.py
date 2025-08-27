import os, math
from moviepy.editor import ImageClip, AudioFileClip, concatenate_videoclips, CompositeVideoClip
from config import FPS, RESOLUTION

def ken_burns_clip(image_path, duration, start_scale=1.0, end_scale=1.08):
    w, h = map(int, RESOLUTION.split("x"))
    base = ImageClip(image_path).set_duration(duration)
    # scale as a function of time
    zoomed = base.resize(lambda t: start_scale + (end_scale - start_scale) * (t / max(duration, 0.001)))
    # center-crop to target resolution
    zoomed = zoomed.on_color(size=(w, h), color=(0,0,0), pos=("center","center"))
    return zoomed

def assemble(slides, narration_wav, out_mp4, crossfade=0.8):
    narration = AudioFileClip(narration_wav)
    total = narration.duration
    per = total / max(1, len(slides))
    clips = [ken_burns_clip(p, per) for p in slides]
    v = concatenate_videoclips(clips, method="compose")
    v = v.set_audio(narration)
    v.write_videofile(out_mp4, codec="libx264", audio_codec="aac", fps=FPS, threads=4)
    return out_mp4
