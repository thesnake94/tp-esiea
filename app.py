from flask import Flask, jsonify, request
import os
import shlex
import subprocess
import sqlite3
import ast
import yaml

app = Flask(__name__)

@app.get("/")
def home():
    return jsonify(message="Hello ESIEA 👋", status="ok")

@app.get("/health")
def health():
    return jsonify(health="pass")


# ===================== PATCHES SÉCURITÉ =====================

# 1) Command Injection: exécuter SANS shell + whitelist de commandes autorisées
ALLOWED_CMDS = {"date", "whoami", "id", "uname"}

@app.get("/vuln/shell")
def vuln_shell():
    cmd_raw = request.args.get("cmd", "").strip()
    if not cmd_raw:
        return {"error": "missing cmd"}, 400

    parts = shlex.split(cmd_raw)
    if not parts:
        return {"error": "invalid cmd"}, 400

    cmd = parts[0]
    args = parts[1:]

    if cmd not in ALLOWED_CMDS:
        return {"error": "command not allowed"}, 403

    try:
        # exécution sans shell=True
        out = subprocess.run([cmd] + args, capture_output=True, text=True, timeout=5)
        return {"cmd": cmd_raw, "returncode": out.returncode, "stdout": out.stdout[:200]}
    except subprocess.TimeoutExpired:
        return {"error": "command timeout"}, 500
    except Exception as e:
        return {"error": str(e)}, 500


# 2) Eval utilisateur: remplacer par ast.literal_eval (littéraux seulement)
@app.get("/vuln/eval")
def vuln_eval():
    expr = request.args.get("expr", "")
    if expr == "":
        return {"error": "missing expr"}, 400
    try:
        result = ast.literal_eval(expr)  # sécurisé: n'évalue que des littéraux Python
        return {"expr": expr, "result": result}
    except (ValueError, SyntaxError) as e:
        return {"error": "invalid expression", "detail": str(e)}, 400
    except Exception as e:
        return {"error": str(e)}, 500


# 3) Path Traversal / File Read: limiter à un dossier sûr
from pathlib import Path

BASE_SAFE_DIR = Path("safe_files").resolve()
BASE_SAFE_DIR.mkdir(parents=True, exist_ok=True)

@app.get("/vuln/read")
def vuln_read():
    path = request.args.get("path", "")
    if not path:
        return {"error": "missing path"}, 400

    # Interdire chemins absolus fournis par l'utilisateur (optionnel)
    if os.path.isabs(path):
        return {"error": "absolute paths not allowed"}, 403

    # Construire le chemin et le résoudre (canonicalize)
    candidate = (BASE_SAFE_DIR / path).resolve()

    # Vérification explicite : le chemin résolu doit être dans BASE_SAFE_DIR
    try:
        # .resolve() lève parfois si path non valide; on entourera l'accès
        if BASE_SAFE_DIR not in candidate.parents and candidate != BASE_SAFE_DIR:
            return {"error": "path traversal detected"}, 403

        if not candidate.exists() or not candidate.is_file():
            return {"error": "file not found"}, 404

        # Ouvrir le fichier **seulement après** toutes les vérifications
        with candidate.open("r", encoding="utf-8", errors="ignore") as f:
            return {"path": path, "content": f.read(200)}
    except (RuntimeError, OSError) as e:
        return {"error": str(e)}, 500



# 4) Unsafe YAML load: utiliser safe_load et gérer les erreurs
@app.post("/vuln/yaml")
def vuln_yaml():
    data = request.data.decode("utf-8", errors="ignore")
    try:
        obj = yaml.safe_load(data)  # safe_load empêche la désérialisation dangereuse
        return {"loaded": str(obj)}
    except yaml.YAMLError as e:
        return {"error": "invalid yaml", "detail": str(e)}, 400


# 5) SQL Injection: requêtes paramétrées
@app.get("/vuln/user")
def vuln_user():
    name = request.args.get("name", "")
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()
    cur.execute("CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT);")
    cur.executemany("INSERT INTO users(name) VALUES(?)", [('alice',), ('bob',), ('charlie',)])
    query = "SELECT id, name FROM users WHERE name = ?;"
    rows = list(cur.execute(query, (name,)))
    return {"query": query, "rows": rows}


# ============================================================

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
