import json, time, os, requests, uuid, pathlib
from config import COMFY_BASE_URL, COMFY_WORKFLOW_PATH
def generate_images(prompts, out_dir, images_per_prompt=1):
    pathlib.Path(out_dir).mkdir(parents=True, exist_ok=True)
    workflow = json.load(open(COMFY_WORKFLOW_PATH, "r", encoding="utf-8"))
    results = []
    for idx, prompt in enumerate(prompts):
        wf = json.loads(json.dumps(workflow))
        for node_id, node in wf.items():
            if node.get("class_type") in ("CLIPTextEncode", "CLIPTextEncodeSDXL", "GLIGENTextBoxApply"):
                if "inputs" in node and "text" in node["inputs"]:
                    node["inputs"]["text"] = prompt
        client_id = str(uuid.uuid4())
        payload = {"prompt": wf, "client_id": client_id}
        r = requests.post(f"{COMFY_BASE_URL}/prompt", json=payload, timeout=300)
        r.raise_for_status()
        prompt_id = r.json().get("prompt_id")
        for _ in range(180):
            time.sleep(2)
            h = requests.get(f"{COMFY_BASE_URL}/history/{prompt_id}", timeout=60)
            if h.status_code == 200:
                data = h.json()
                for k, item in data.get(prompt_id, {}).get("outputs", {}).items():
                    if "images" in item:
                        count = 0
                        for im in item["images"]:
                            img_name = im["filename"]
                            sub = im.get("subfolder", "")
                            get_url = f"{COMFY_BASE_URL}/view?filename={img_name}&subfolder={sub}&type=output"
                            img = requests.get(get_url, timeout=120)
                            if img.status_code == 200:
                                dest = os.path.join(out_dir, f"scene{idx+1}_{count+1}.png")
                                open(dest, "wb").write(img.content)
                                results.append(dest)
                                count += 1
                                if count >= images_per_prompt:
                                    break
                if len([p for p in results if f"scene{idx+1}_" in p]) >= images_per_prompt:
                    break
    return results
