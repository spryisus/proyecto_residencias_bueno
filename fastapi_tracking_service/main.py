import json
import os
import sqlite3
import time
from contextlib import contextmanager
from typing import Any, Dict, List, Optional

import httpx
from bs4 import BeautifulSoup
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field


PORT = int(os.getenv("PORT", "8000"))
CACHE_DB_PATH = os.getenv("CACHE_DB_PATH", "cache.db")
CACHE_TTL_SECONDS = int(os.getenv("CACHE_TTL_SECONDS", "1800"))
UPSTREAM_TIMEOUT_SECONDS = float(os.getenv("UPSTREAM_TIMEOUT_SECONDS", "10"))
DHL_URL_TEMPLATE = os.getenv(
    "DHL_URL_TEMPLATE",
    "https://www.dhl.com/mx-es/home/tracking/tracking-data.html?tracking-id={tracking_number}&submit=1",
)
PUPPETEER_PROXY_URL = os.getenv("PUPPETEER_PROXY_URL")
ALLOWED_ORIGINS = [
    origin.strip()
    for origin in os.getenv("ALLOWED_ORIGINS", "*").split(",")
    if origin.strip()
] or ["*"]


def ensure_db():
    with sqlite3.connect(CACHE_DB_PATH) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS tracking_cache (
                tracking TEXT PRIMARY KEY,
                payload TEXT NOT NULL,
                updated_at INTEGER NOT NULL
            )
            """
        )
        conn.commit()


@contextmanager
def db_conn():
    conn = sqlite3.connect(CACHE_DB_PATH)
    try:
        yield conn
    finally:
        conn.close()


def get_cache(tracking: str) -> Optional[Dict[str, Any]]:
    now = int(time.time())
    with db_conn() as conn:
        cur = conn.execute(
            "SELECT payload, updated_at FROM tracking_cache WHERE tracking = ?", (tracking,)
        )
        row = cur.fetchone()
        if not row:
            return None
        payload, updated_at = row
        if now - updated_at > CACHE_TTL_SECONDS:
            conn.execute("DELETE FROM tracking_cache WHERE tracking = ?", (tracking,))
            conn.commit()
            return None
        try:
            return json.loads(payload)
        except json.JSONDecodeError:
            return None


def set_cache(tracking: str, payload: Dict[str, Any]) -> None:
    now = int(time.time())
    with db_conn() as conn:
        conn.execute(
            """
            INSERT INTO tracking_cache (tracking, payload, updated_at)
            VALUES (?, ?, ?)
            ON CONFLICT(tracking) DO UPDATE SET
                payload = excluded.payload,
                updated_at = excluded.updated_at
            """,
            (tracking, json.dumps(payload), now),
        )
        conn.commit()


def cleanup_expired() -> None:
    now = int(time.time())
    with db_conn() as conn:
        conn.execute(
            "DELETE FROM tracking_cache WHERE updated_at < ?", (now - CACHE_TTL_SECONDS,)
        )
        conn.commit()


class TrackingEvent(BaseModel):
    description: str
    timestamp: Optional[str] = None
    location: Optional[str] = None
    status: Optional[str] = None


class TrackingData(BaseModel):
    trackingNumber: str
    status: str = "Desconocido"
    events: List[TrackingEvent] = Field(default_factory=list)
    origin: Optional[str] = None
    destination: Optional[str] = None
    currentLocation: Optional[str] = None
    estimatedDelivery: Optional[str] = None
    raw: Optional[Dict[str, Any]] = None


class TrackingResponse(BaseModel):
    success: bool
    source: str
    data: TrackingData


app = FastAPI(title="DHL Tracking Ligero", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS if ALLOWED_ORIGINS != ["*"] else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

ensure_db()


async def fetch_direct(tracking_number: str) -> TrackingData:
    url = DHL_URL_TEMPLATE.format(tracking_number=tracking_number)
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/122.0.0.0 Safari/537.36"
        ),
        "Accept": "application/json, text/html;q=0.9,*/*;q=0.8",
        "Accept-Language": "es-ES,es;q=0.9,en;q=0.8",
        "Cache-Control": "no-cache",
        "Pragma": "no-cache",
    }

    async with httpx.AsyncClient(timeout=UPSTREAM_TIMEOUT_SECONDS, follow_redirects=True) as client:
        resp = await client.get(url, headers=headers)

    if resp.status_code == 404:
        raise HTTPException(status_code=404, detail="Guía no encontrada en DHL")
    if resp.status_code >= 500:
        raise HTTPException(status_code=502, detail="Error aguas arriba DHL")

    # Intentar JSON directo
    try:
        data = resp.json()
        parsed = parse_tracking_payload(tracking_number, data)
        parsed.raw = data  # type: ignore
        return parsed
    except Exception:
        pass

    # Intentar HTML ligero con BeautifulSoup
    try:
        soup = BeautifulSoup(resp.text, "html.parser")
        script_ld_json = soup.find("script", {"type": "application/ld+json"})
        if script_ld_json and script_ld_json.text:
            ld_data = json.loads(script_ld_json.text)
            parsed = parse_tracking_payload(tracking_number, ld_data)
            parsed.raw = ld_data  # type: ignore
            return parsed
    except Exception:
        pass

    # Como último recurso, retornar raw texto
    return TrackingData(
        trackingNumber=tracking_number,
        status="Sin parsear",
        events=[],
        raw={"rawText": resp.text[:2000]},
    )


def parse_tracking_payload(tracking_number: str, payload: Dict[str, Any]) -> TrackingData:
    """
    Parser defensivo: intenta múltiples formas comunes de respuesta.
    Ajustar según el endpoint interno real si cambia el formato.
    """
    # Caso 1: payload estilo {results: [{checkpoints: [...]}]}
    if isinstance(payload, dict) and "results" in payload:
        results = payload.get("results")
        if isinstance(results, list) and results:
            first = results[0]
            checkpoints = first.get("checkpoints") or []
            events = []
            for item in checkpoints:
                events.append(
                    TrackingEvent(
                        description=item.get("description") or item.get("status") or "Evento",
                        timestamp=item.get("timestamp") or item.get("date"),
                        location=item.get("location"),
                        status=item.get("status"),
                    )
                )
            return TrackingData(
                trackingNumber=first.get("id") or tracking_number,
                status=first.get("status") or "En tránsito",
                events=events,
                origin=first.get("origin"),
                destination=first.get("destination"),
                currentLocation=first.get("currentLocation"),
                estimatedDelivery=first.get("estimatedDelivery"),
            )

    # Caso 2: payload con claves directas
    events_payload = payload.get("events") if isinstance(payload, dict) else None
    events = []
    if isinstance(events_payload, list):
        for item in events_payload:
            events.append(
                TrackingEvent(
                    description=item.get("description") or item.get("status") or "Evento",
                    timestamp=item.get("timestamp") or item.get("date"),
                    location=item.get("location"),
                    status=item.get("status"),
                )
            )

    status = (
        payload.get("status")
        or payload.get("currentStatus")
        or payload.get("result")
        or "Desconocido"
        if isinstance(payload, dict)
        else "Desconocido"
    )

    return TrackingData(
        trackingNumber=payload.get("trackingNumber") if isinstance(payload, dict) else tracking_number,
        status=status,
        events=events,
        origin=payload.get("origin") if isinstance(payload, dict) else None,
        destination=payload.get("destination") if isinstance(payload, dict) else None,
        currentLocation=payload.get("currentLocation") if isinstance(payload, dict) else None,
        estimatedDelivery=payload.get("estimatedDelivery") if isinstance(payload, dict) else None,
    )


async def fetch_via_proxy(tracking_number: str) -> TrackingData:
    if not PUPPETEER_PROXY_URL:
        raise HTTPException(status_code=502, detail="Proxy Puppeteer no configurado")
    base = PUPPETEER_PROXY_URL.rstrip("/")
    url = f"{base}/api/track/{tracking_number}"
    # El proxy puede tardar hasta ~300s por los delays de anti-bot; damos margen mayor
    proxy_timeout = max(int(UPSTREAM_TIMEOUT_SECONDS * 3), 300)
    try:
        async with httpx.AsyncClient(timeout=proxy_timeout) as client:
            resp = await client.get(url)
    except httpx.ReadTimeout:
        raise HTTPException(status_code=504, detail="Proxy timeout")
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Error al llamar proxy: {exc}") from exc
    if resp.status_code == 404:
        raise HTTPException(status_code=404, detail="Guía no encontrada en proxy")
    if resp.status_code >= 500:
        raise HTTPException(status_code=502, detail="Proxy devolvió error")
    data = resp.json()
    if not data.get("success"):
        raise HTTPException(status_code=502, detail=data.get("error") or "Fallo en proxy")
    # Ajustar a TrackingData
    payload = data.get("data") or {}
    events = []
    for item in payload.get("events", []):
        events.append(
            TrackingEvent(
                description=item.get("description") or item.get("status") or "Evento",
                timestamp=item.get("timestamp"),
                location=item.get("location"),
                status=item.get("status"),
            )
        )
    return TrackingData(
        trackingNumber=payload.get("trackingNumber") or tracking_number,
        status=payload.get("status") or "En tránsito",
        events=events,
        origin=payload.get("origin"),
        destination=payload.get("destination"),
        currentLocation=payload.get("currentLocation"),
        estimatedDelivery=payload.get("estimatedDelivery"),
        raw=payload,
    )


@app.get("/health")
async def health():
    cleanup_expired()
    return {"status": "ok", "cache_ttl_seconds": CACHE_TTL_SECONDS}


@app.get("/tracking/{tracking_number}", response_model=TrackingResponse)
async def track(tracking_number: str, use_proxy_fallback: bool = True):
    tracking_number = tracking_number.strip()
    if not tracking_number or len(tracking_number) < 8:
        raise HTTPException(status_code=400, detail="Número de guía inválido")

    cached = get_cache(tracking_number)
    if cached:
        return TrackingResponse(
            success=True,
            source=cached.get("source", "cache"),
            data=TrackingData(**cached["data"]),
        )

    try:
        data = await fetch_direct(tracking_number)
        response = TrackingResponse(success=True, source="direct", data=data)
        set_cache(tracking_number, response.model_dump())
        return response
    except HTTPException as http_exc:
        # Si DHL responde 404, respetar
        if http_exc.status_code == 404:
            raise
        # Intentar fallback si está habilitado
        if use_proxy_fallback and PUPPETEER_PROXY_URL:
            data = await fetch_via_proxy(tracking_number)
            response = TrackingResponse(success=True, source="proxy", data=data)
            set_cache(tracking_number, response.model_dump())
            return response
        raise
    except Exception:
        # fallback genérico
        if use_proxy_fallback and PUPPETEER_PROXY_URL:
            data = await fetch_via_proxy(tracking_number)
            response = TrackingResponse(success=True, source="proxy", data=data)
            set_cache(tracking_number, response.model_dump())
            return response
        raise HTTPException(status_code=502, detail="No se pudo obtener tracking")


if __name__ == "__main__":
    import uvicorn

    # Solo usar reload en desarrollo (no en producción)
    is_dev = os.getenv("ENV", "production") == "development"
    uvicorn.run("main:app", host="0.0.0.0", port=PORT, reload=is_dev)

