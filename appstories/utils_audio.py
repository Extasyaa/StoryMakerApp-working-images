import os
from pydub import AudioSegment
def mix_music(narration_wav, music_path, out_wav, duck_db=-12.0):
    speech = AudioSegment.from_file(narration_wav)
    music = AudioSegment.from_file(music_path)
    if len(music) < len(speech):
        times = (len(speech) // len(music)) + 2
        music = music * times
    music = music[:len(speech)]
    music = music + duck_db
    mixed = music.overlay(speech)
    mixed.export(out_wav, format="wav")
    return out_wav
