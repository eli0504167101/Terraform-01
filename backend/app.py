import os
import sqlite3
from datetime import datetime, timezone

from flask import Flask, jsonify, request

app = Flask(__name__)

DATABASE_PATH = os.getenv(
    "DATABASE_PATH",
    "/data/visitors.db"
)


def get_database_connection():
    connection = sqlite3.connect(DATABASE_PATH)
    connection.row_factory = sqlite3.Row
    return connection


def initialize_database():
    database_directory = os.path.dirname(DATABASE_PATH)
    os.makedirs(database_directory, exist_ok=True)

    with get_database_connection() as connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS visitors (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                age INTEGER NOT NULL,
                created_at TEXT NOT NULL
            )
            """
        )


@app.get("/")
def index():
    return jsonify(
        message="Hello from the private backend",
        service="backend"
    )


@app.get("/health")
def health():
    return jsonify(
        status="ok",
        service="backend"
    )


@app.post("/visitors")
def create_visitor():
    data = request.get_json(silent=True) or {}

    name = str(data.get("name", "")).strip()
    age = data.get("age")

    if not name:
        return jsonify(error="Name is required"), 400

    if len(name) > 100:
        return jsonify(error="Name is too long"), 400

    try:
        age = int(age)
    except (TypeError, ValueError):
        return jsonify(error="Age must be a number"), 400

    if age < 1 or age > 120:
        return jsonify(error="Age must be between 1 and 120"), 400

    created_at = datetime.now(timezone.utc).isoformat()

    with get_database_connection() as connection:
        cursor = connection.execute(
            """
            INSERT INTO visitors (name, age, created_at)
            VALUES (?, ?, ?)
            """,
            (name, age, created_at)
        )

        visitor_id = cursor.lastrowid

    return jsonify(
        id=visitor_id,
        name=name,
        age=age,
        created_at=created_at
    ), 201


initialize_database()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)