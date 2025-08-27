import subprocess, shlex, os, pathlib
from config import PIPER_BIN, PIPER_MODEL, PIPER_SPEAKER_ID, PIPER_NOISE_SCALE, PIPER_LENGTH_SCALE, PIPER_NOISE_W
def synthesize(text: str, out_wav: str):
    pathlib.Path(os.path.dirname(out_wav)).mkdir(parents=True, exist_ok=True)
    cmd = f'"{PIPER_BIN}" -m "{PIPER_MODEL}" -f "{out_wav}" -s {PIPER_SPEAKER_ID} --noise-scale {PIPER_NOISE_SCALE} --length-scale {PIPER_LENGTH_SCALE} --noise-w {PIPER_NOISE_W}'
    p = subprocess.Popen(shlex.split(cmd), stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    _out, err = p.communicate(input=text.encode("utf-8"))
    if p.returncode != 0:
        raise RuntimeError(f"Piper failed: {err.decode('utf-8', 'ignore')}")
    return out_wav
