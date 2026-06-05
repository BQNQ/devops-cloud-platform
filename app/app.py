import os
import time
import json
import logging
import psycopg2
from psycopg2.extras import RealDictCursor
from flask import Flask, request, jsonify, g
from prometheus_client import Counter, Histogram, generate_latest

app = Flask(__name__)


logging.getLogger("werkzeug").setLevel(logging.ERROR)

class JsonFormatter(logging.Formatter):
    def format(self, record):
        log = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "message": record.getMessage(),
            "method": getattr(record, "method", None),
            "path": getattr(record, "path", None),
            "status": getattr(record, "status", None),
            "latency_ms": getattr(record, "latency_ms", None),
            "ip": getattr(record, "ip", None),
            "user_agent": getattr(record, "user_agent", None),
        }
        return json.dumps(log)

handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())

logger = logging.getLogger("app")
logger.setLevel(logging.INFO)
logger.handlers = [handler]

DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "port": os.getenv("DB_PORT", "5432"),
    "dbname": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
}

def get_conn():
    return psycopg2.connect(**DB_CONFIG)


REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "Request latency",
    ["endpoint"]
)

def normalize_path(path: str) -> str:
    parts = path.strip("/").split("/")

    if len(parts) == 2 and parts[0] == "items":
        return "/items/:id"

    return path


@app.before_request
def start_timer():
    g.start = time.time()

@app.after_request
def metrics_and_logs(response):
    latency = time.time() - g.start
    endpoint = normalize_path(request.path)

    logger.info(
        "http_request",
        extra={
                "method": request.method,
                "path": request.path,
                "endpoint": endpoint,
                "status": response.status_code,
                "latency_ms": round(latency * 1000, 2),
                "ip": request.remote_addr,
                "user_agent": request.headers.get("User-Agent"),
        },
    )

    REQUEST_COUNT.labels(
        request.method,
        endpoint,
        response.status_code
    ).inc()

    REQUEST_LATENCY.labels(endpoint).observe(latency)

    return response

@app.route("/")
def home():
    return {"message": "welcome to api"}

@app.route("/health")
def health():
    return {"status":"ok"}, 200

@app.route("/items", methods=["GET"])
def get_items():
    conn = get_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute("SELECT * FROM items;")
    items = cur.fetchall()

    cur.close()
    conn.close()

    return jsonify(items)

@app.route("/items", methods=["POST"])
def create_item():
    data = request.json

    conn = get_conn()
    cur = conn.cursor()

    cur.execute(
        "INSERT INTO items (name, description) VALUES (%s, %s) RETURNING id;",
        (data["name"], data.get("description")),
    )

    item_id = cur.fetchone()[0]

    conn.commit()
    cur.close()
    conn.close()

    return {"id": item_id}, 201

@app.route("/items/<int:item_id>", methods=["GET"])
def get_item(item_id):
    conn = get_conn()
    cur = conn.cursor(cursor_factory=RealDictCursor)

    cur.execute("SELECT * FROM items WHERE id=%s;", (item_id,))
    item = cur.fetchone()

    cur.close()
    conn.close()

    if not item:
        return {"error": "not found"}, 404

    return jsonify(item)

@app.route("/items/<int:item_id>", methods=["PUT"])
def update_item(item_id):
    data = request.json

    conn = get_conn()
    cur = conn.cursor()

    cur.execute(
        "UPDATE items SET name=%s, description=%s WHERE id=%s;",
        (data["name"], data.get("description"), item_id),
    )

    conn.commit()
    cur.close()
    conn.close()

    return {"status": "updated"}

@app.route("/items/<int:item_id>", methods=["DELETE"])
def delete_item(item_id):
    conn = get_conn()
    cur = conn.cursor()

    cur.execute("DELETE FROM items WHERE id=%s;", (item_id,))

    conn.commit()
    cur.close()
    conn.close()

    return {"status": "deleted"}


@app.route("/metrics")
def metrics():
    return generate_latest(), 200, {"Content-Type": "text/plain"}

# DEV ONLY
app.run(host="0.0.0.0", port=5000)