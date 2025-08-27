from pathlib import Path
import json, requests, subprocess

API_KEY = ""

text = Path("story_for_tts.txt").read_text(encoding="utf-8")
chunks = [text[i:i+3500] for i in range(0, len(text), 3500)]

url = "https://api.openai.com/v1/audio/speech"
headers = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}

files = []
for i, chunk in enumerate(chunks, 1):
    out = f"story_part_{i:02d}.mp3"
    r = requests.post(url, headers=headers, data=json.dumps({
        "model": "gpt-4o-mini-tts",
        "voice": "onyx",
        "input": chunk
    }))
    r.raise_for_status()
    Path(out).write_bytes(r.content)
    print(out)
    files.append(out)

with open("filelist.txt", "w", encoding="utf-8") as f:
    for fn in files:
        f.write(f"file '{fn}'\n")

subprocess.run(["ffmpeg", "-y", "-f", "concat", "-safe", "0", "-i", "filelist.txt", "-c", "copy", "full_story.mp3"], check=True)
print("full_story.mp3")

