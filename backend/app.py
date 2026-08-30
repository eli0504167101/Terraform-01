from flask import Flask, jsonify

app = Flask(__name__)


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


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)