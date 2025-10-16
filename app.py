from flask import Flask, jsonify, request

app = Flask(__name__)

@app.get("/")
def home():
    return jsonify(message="Hello ESIEA 👋", status="ok")

@app.get("/health")
def health():
    return jsonify(health="pass")


# --- VULN: Command Injection (RCE) via shell=True ---
import subprocess

@app.get("/vuln/shell")
def vuln_shell():
    cmd = request.args.get("cmd", "")
    out = subprocess.run(cmd, shell=True, capture_output=True, text=True)  # VULNERABLE
    return {"cmd": cmd, "returncode": out.returncode, "stdout": out.stdout[:200]}

# --- VULN: Eval de l'entrée utilisateur ---
@app.get("/vuln/eval")
def vuln_eval():
    expr = request.args.get("expr", "")
    try:
        return {"expr": expr, "result": eval(expr)}  # VULNERABLE
    except Exception as e:
        return {"error": str(e)}, 400

# --- VULN: Path Traversal / File Read ---
import os
@app.get("/vuln/read")
def vuln_read():
    path = request.args.get("path", "")
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:  # VULNERABLE
            return {"path": path, "content": f.read(200)}
    except Exception as e:
        return {"error": str(e)}, 400

# --- VULN: Unsafe YAML load ---
import yaml
@app.post("/vuln/yaml")
def vuln_yaml():
    data = request.data.decode("utf-8", errors="ignore")
    obj = yaml.load(data, Loader=yaml.Loader)  # VULNERABLE (unsafe loader)
    return {"loaded": str(obj)}

# --- VULN: SQL injection (concaténation) ---
import sqlite3
@app.get("/vuln/user")
def vuln_user():
    name = request.args.get("name", "")
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()
    cur.execute("CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT);")
    cur.execute("INSERT INTO users(name) VALUES('alice'),('bob'),('charlie');")
    # VULNERABLE: injection
    query = "SELECT id, name FROM users WHERE name = '" + name + "';"
    rows = list(cur.execute(query))
    return {"query": query, "rows": rows}



if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
