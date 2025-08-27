import os, json, pathlib, requests
API_KEY = os.getenv("OPENAI_API_KEY","")
url="https://api.openai.com/v1/audio/speech"
payload={"model":"gpt-4o-mini-tts","voice":"verse","input":"Привет! Это тест озвучки истории."}
r=requests.post(url, headers={"Authorization":f"Bearer {API_KEY}","Content-Type":"application/json"}, data=json.dumps(payload))
r.raise_for_status()
out="story.mp3"
pathlib.Path(out).write_bytes(r.content)
print(out)
