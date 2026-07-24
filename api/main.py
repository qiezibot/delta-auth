"""
Delta Auth API - 微信扫码授权系统
独立项目，跟茄子数据完全分开。
Railway 部署版本
"""
import secrets, os, sys, json
from datetime import datetime
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, Response
from pydantic import BaseModel
import sqlite3

# --- 配置 ---
SECRET_KEY = os.environ.get("AUTH_SECRET", secrets.token_hex(32))
DB_DIR = os.path.join(os.path.dirname(__file__), "data")
os.makedirs(DB_DIR, exist_ok=True)
DB_PATH = os.path.join(DB_DIR, "delta_auth.db")

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("""
        CREATE TABLE IF NOT EXISTS auth_codes (
            code TEXT PRIMARY KEY,
            status TEXT DEFAULT 'pending',
            credential TEXT,
            created_at TEXT,
            confirmed_at TEXT,
            consumed_at TEXT
        )
    """)
    conn.commit()
    return conn

# --- FastAPI ---
app = FastAPI(title="Delta Auth API", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True,
                   allow_methods=["*"], allow_headers=["*"])

# 挂载前端页面
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/static", StaticFiles(directory=static_dir), name="static")

class WebClaimRequest(BaseModel):
    code: str

def _now():
    return datetime.utcnow().isoformat()

# --- 路由 ---

from fastapi import Request

@app.api_route("/", methods=["GET", "HEAD"])
def root(request: Request):
    """返回前端页面"""
    if request.method == "HEAD":
        return Response(status_code=200)
    idx = os.path.join(static_dir, "index.html")
    if os.path.exists(idx):
        return FileResponse(idx, media_type="text/html", headers={
            "Cache-Control": "no-cache, no-store, must-revalidate",
            "Pragma": "no-cache",
            "Expires": "0"
        })
    return {"status": "ok", "version": "1.0.0", "name": "Delta Auth API"}

@app.api_route("/scan", methods=["GET", "HEAD"])
def scan_page(request: Request):
    """扫码确认页面（避免 ?code=xxx 导致 405）"""
    if request.method == "HEAD":
        return Response(status_code=200)
    idx = os.path.join(static_dir, "index.html")
    if os.path.exists(idx):
        return FileResponse(idx, media_type="text/html", headers={
            "Cache-Control": "no-cache, no-store, must-revalidate",
            "Pragma": "no-cache",
            "Expires": "0"
        })
    return {"status": "ok"}

@app.get("/api/status")
def api_status():
    return {"status": "ok", "version": "1.0.0", "secret_set": bool(os.environ.get("AUTH_SECRET"))}

@app.post("/api/auth/create")
def create_auth():
    """创建授权码"""
    code = secrets.token_hex(16)
    now = _now()
    db = get_db()
    db.execute("INSERT INTO auth_codes (code, status, created_at) VALUES (?, 'pending', ?)", (code, now))
    db.commit()
    db.close()
    return {"code": code, "created_at": now}

@app.get("/api/auth/qrcode/{code}")
def get_qrcode(code: str):
    db = get_db()
    row = db.execute("SELECT * FROM auth_codes WHERE code=?", (code,)).fetchone()
    db.close()
    if not row:
        raise HTTPException(404, "授权码不存在")
    return {"code": row["code"], "status": row["status"], "created_at": row["created_at"]}

@app.api_route("/api/auth/confirm/{code}", methods=["GET", "POST"])
def confirm_auth(code: str, credential: str = ""):
    """确认授权，存储凭证（支持 GET 和 POST，方便微信扫码后调用）"""
    db = get_db()
    row = db.execute("SELECT * FROM auth_codes WHERE code=?", (code,)).fetchone()
    if not row:
        db.close()
        raise HTTPException(404, "授权码不存在")
    if row["status"] != "pending":
        db.close()
        raise HTTPException(400, "授权码已使用")
    now = _now()
    if not credential:
        credential = f"wechat_user_{now}_{secrets.token_hex(8)}"
    db.execute("UPDATE auth_codes SET status='confirmed', credential=?, confirmed_at=? WHERE code=?",
               (credential, now, code))
    db.commit()
    db.close()
    return {"status": "confirmed", "code": code}

@app.post("/api/auth/claim/{code}")
def claim_auth(code: str):
    """网页端领取凭证（扫码确认后调用，不暴露密钥）"""
    db = get_db()
    row = db.execute("SELECT * FROM auth_codes WHERE code=?", (code,)).fetchone()
    db.close()
    if not row:
        raise HTTPException(404, "授权码不存在")
    if row["status"] != "confirmed":
        raise HTTPException(400, "未授权")
    return {"code": code, "credential": row["credential"]}

@app.get("/api/auth/verify/{code}")
def verify_auth(code: str):
    """轮询授权状态"""
    db = get_db()
    row = db.execute("SELECT * FROM auth_codes WHERE code=?", (code,)).fetchone()
    db.close()
    if not row:
        raise HTTPException(404, "授权码不存在")
    return {"code": code, "status": row["status"]}

@app.get("/api/auth/token/{code}")
def get_token(code: str, secret: str = ""):
    """获取授权凭证"""
    if secret != SECRET_KEY:
        raise HTTPException(403, "密钥错误")
    db = get_db()
    row = db.execute("SELECT * FROM auth_codes WHERE code=?", (code,)).fetchone()
    db.close()
    if not row:
        raise HTTPException(404, "授权码不存在")
    if row["status"] != "confirmed":
        raise HTTPException(400, "未授权或已消耗")
    return {"code": code, "credential": row["credential"]}

@app.post("/api/auth/consume/{code}")
def consume_auth(code: str, secret: str = ""):
    """消耗凭证"""
    if secret != SECRET_KEY:
        raise HTTPException(403, "密钥错误")
    db = get_db()
    row = db.execute("SELECT * FROM auth_codes WHERE code=?", (code,)).fetchone()
    if not row:
        db.close()
        raise HTTPException(404, "授权码不存在")
    db.execute("UPDATE auth_codes SET status='consumed', consumed_at=? WHERE code=?",
               (_now(), code))
    db.commit()
    db.close()
    return {"status": "consumed"}

@app.get("/api/auth/list")
def list_auths(secret: str = ""):
    """管理后台 - 列出所有授权"""
    if secret != SECRET_KEY:
        raise HTTPException(403, "密钥错误")
    db = get_db()
    rows = db.execute("SELECT * FROM auth_codes ORDER BY created_at DESC LIMIT 100").fetchall()
    db.close()
    return [dict(r) for r in rows]

# --- 启动 ---
if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    print(f"Delta Auth API v1.0.0")
    print(f"  Port: {port}")
    print(f"  Secret: {SECRET_KEY[:8]}...")
    print(f"  DB: {DB_PATH}")
    print(f"  Web: http://0.0.0.0:{port}/")
    uvicorn.run(app, host="0.0.0.0", port=port)
