from __future__ import annotations
import base64, io, os, math
from typing import Optional, Tuple

import requests
from PIL import Image, ImageDraw, ImageFont


class ImageGenError(RuntimeError):
    pass


def _log(msg: str):
    print(msg, flush=True)


def _ratio_from_size(size: str) -> str:
    """
    "1024x1024" -> "1:1"
    "1920x1080" -> "16:9"
    если не удаётся распарсить — вернём "1:1"
    """
    try:
        w_str, h_str = size.lower().split("x")
        w, h = int(w_str), int(h_str)
        if w <= 0 or h <= 0:
            return "1:1"
        g = math.gcd(w, h)
        return f"{w//g}:{h//g}"
    except Exception:
        return "1:1"


# ----------------------------- #
# Grok (xAI)
# ----------------------------- #

def _grok_generate_png(
    prompt: str,
    model: str = "grok-2-vision",
    size: str = "1024x1024",
    aspect_ratio: Optional[str] = None,
) -> bytes:
    api_key = os.getenv("XAI_API_KEY")
    if not api_key:
        raise ImageGenError("XAI_API_KEY not set")

    base_url = os.getenv("XAI_BASE_URL", "https://api.x.ai")
    url = f"{base_url.rstrip('/')}/v1/images/generations"

    # Grok не поддерживает size → всегда передаём aspect_ratio
    ar = aspect_ratio or os.getenv("XAI_ASPECT_RATIO") or _ratio_from_size(size)

    payload = {
        "model": model,
        "prompt": prompt,
        "aspect_ratio": ar,
    }

    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    _log(f"GROK: POST {url} model={model} aspect={ar}")
    resp = requests.post(url, json=payload, headers=headers, timeout=60)
    if resp.status_code >= 400:
        raise ImageGenError(f"Grok HTTP {resp.status_code}: {resp.text[:200]}")

    j = resp.json()
    data = j.get("data")
    if not data or not isinstance(data, list):
        raise ImageGenError(f"Grok bad payload: {str(j)[:200]}")

    item = data[0]
    # base64?
    b64 = item.get("b64_json")
    if b64:
        _log("GROK: got b64_json")
        return base64.b64decode(b64)
    # url?
    u = item.get("url")
    if u:
        _log(f"GROK: downloading {u}")
        r = requests.get(u, timeout=60)
        r.raise_for_status()
        return r.content

    raise ImageGenError("Grok: neither b64_json nor url present")


# ----------------------------- #
# OpenAI (fallback provider)
# ----------------------------- #

def _openai_generate_png(
    prompt: str,
    model: str = "gpt-image-1",
    size: str = "1024x1024",
    aspect_ratio: Optional[str] = None,
) -> bytes:
    try:
        import openai  # type: ignore
        client_ctor = getattr(openai, "OpenAI", None)
        client = client_ctor(api_key=os.getenv("OPENAI_API_KEY")) if client_ctor else openai
    except Exception as e:
        raise ImageGenError(f"OpenAI SDK not installed: {e}")

    try:
        _log(f"OPENAI: generate model={model} size={size}")
        resp = client.images.generate(model=model, prompt=prompt, size=size)
        data = getattr(resp, "data", None) or resp.get("data")
        b64 = data[0].get("b64_json") if isinstance(data, list) else None
        if not b64:
            raise KeyError("b64_json missing")
        return base64.b64decode(b64)
    except TypeError:
        if not aspect_ratio:
            raise
        _log(f"OPENAI: generate model={model} aspect={aspect_ratio}")
        resp = client.images.generate(model=model, prompt=prompt, aspect_ratio=aspect_ratio)
        data = getattr(resp, "data", None) or resp.get("data")
        b64 = data[0].get("b64_json") if isinstance(data, list) else None
        if not b64:
            raise KeyError("b64_json missing")
        return base64.b64decode(b64)


# ----------------------------- #
# Local fallback (no network)
# ----------------------------- #

def _fallback_png(prompt: str, size: Tuple[int, int]) -> bytes:
    _log("FALLBACK: drawing local placeholder")
    w, h = size
    img = Image.new("RGB", (w, h), (26, 28, 34))
    d = ImageDraw.Draw(img)
    d.rectangle([4, 4, w - 5, h - 5], outline=(80, 85, 95), width=2)

    text = (prompt[:120] + "…") if len(prompt) > 120 else prompt
    try:
        font = ImageFont.truetype("Menlo.ttc", 28)
    except Exception:
        font = ImageFont.load_default()

    bbox = d.multiline_textbbox((0, 0), text, font=font, align="center")
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.multiline_text(((w - tw) / 2, (h - th) / 2),
                     text, fill=(200, 200, 210), font=font, align="center")

    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


# ----------------------------- #
# Public API
# ----------------------------- #

def generate_image_bytes(
    prompt: str,
    provider: str = "grok",
    image_size: str = "1024x1024",
    aspect_ratio: Optional[str] = None,
) -> bytes:
    provider = (provider or "grok").lower().strip()

    if provider == "grok" and os.getenv("XAI_API_KEY"):
        try:
            return _grok_generate_png(
                prompt=prompt,
                model=os.getenv("XAI_IMAGE_MODEL", "grok-2-vision"),
                size=image_size,
                aspect_ratio=aspect_ratio,
            )
        except Exception as e:
            _log(f"GROK ERROR: {e}")

    if provider == "openai" and os.getenv("OPENAI_API_KEY"):
        try:
            return _openai_generate_png(
                prompt=prompt,
                model=os.getenv("OPENAI_IMAGE_MODEL", "gpt-image-1"),
                size=image_size,
                aspect_ratio=aspect_ratio,
            )
        except Exception as e:
            _log(f"OPENAI ERROR: {e}")

    # local fallback
    try:
        w, h = (int(x) for x in image_size.split("x"))
    except Exception:
        w, h = (1024, 1024)
    return _fallback_png(prompt, (w, h))
