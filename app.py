from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/")
def home():
    return jsonify(message="Hello ESIEA 👋", status="ok")

@app.get("/health")
def health():
    return jsonify(health="pass")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
