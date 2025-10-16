#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${PWD}/mini-ctf"

echo "Création de l'arborescence dans : ${ROOT_DIR}"
mkdir -p "${ROOT_DIR}/challenges/sqli/web"
mkdir -p "${ROOT_DIR}/challenges/upload/web/uploads"
mkdir -p "${ROOT_DIR}/challenges/rce/web"

echo "Ecriture des fichiers..."

# docker-compose.yml
cat > "${ROOT_DIR}/docker-compose.yml" <<'YAML'
version: '3.8'
services:
  mysql:
    image: mysql:5.7
    container_name: ctf_mysql
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: ctf
      MYSQL_USER: ctfuser
      MYSQL_PASSWORD: ctfpass
    volumes:
      - db_data:/var/lib/mysql
      - ./challenges/sqli/db_init.sql:/docker-entrypoint-initdb.d/db_init.sql:ro
    ports:
      - "3306:3306"

  web:
    image: php:8.1-apache
    container_name: ctf_web
    volumes:
      - ./challenges:/var/www/html/challenges:cached
    ports:
      - "8080:80"
    depends_on:
      - mysql

volumes:
  db_data:
YAML

# README.md
cat > "${ROOT_DIR}/README.md" <<'MD'
Mini-CTF (local) - 3 challenges
- SQLi : http://localhost:8080/challenges/sqli/web/index.php
- Upload : http://localhost:8080/challenges/upload/web/upload.php
- RCE  : http://localhost:8080/challenges/rce/web/ping.php

Démarrage :
  docker-compose up -d

Réinitialiser la DB :
  docker exec -i ctf_mysql mysql -uroot -prootpass < challenges/sqli/db_init.sql

Attention : n'exposez PAS ces services en production / sur Internet.
MD

# SQLi index.php
cat > "${ROOT_DIR}/challenges/sqli/web/index.php" <<'PHP'
<?php
// challenges/sqli/web/index.php
$conn = new mysqli('mysql','ctfuser','ctfpass','ctf');
if ($conn->connect_error) { die("DB error"); }

if (isset($_POST['user']) && isset($_POST['pass'])) {
    $user = $_POST['user'];
    $pass = $_POST['pass'];
    // VULN volontaire : concaténation -> SQL injection
    $sql = "SELECT id, username FROM users WHERE username = '$user' AND password = '$pass' LIMIT 1";
    $res = $conn->query($sql);
    if ($res && $res->num_rows > 0) {
        $row = $res->fetch_assoc();
        echo "Bienvenue " . htmlspecialchars($row['username']) . "<br>";
        echo "<p>Indice : essayez d'injecter dans les champs pour bypass.</p>";
        echo "<p>Pour avancer, regardez la table <code>flags</code>.</p>";
    } else {
        echo "Login incorrect.<br>";
    }
}
?>

<h3>Login</h3>
<form method="post">
  User: <input name="user"><br>
  Pass: <input name="pass"><br>
  <button>Login</button>
</form>
PHP

# SQL init
cat > "${ROOT_DIR}/challenges/sqli/db_init.sql" <<'SQL'
DROP DATABASE IF EXISTS ctf;
CREATE DATABASE ctf;
USE ctf;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50),
  password VARCHAR(50)
);
INSERT INTO users (username,password) VALUES ('alice','alicepass'),('bob','bobpass');

CREATE TABLE flags (
  id INT AUTO_INCREMENT PRIMARY KEY,
  flag VARCHAR(255)
);
INSERT INTO flags (flag) VALUES ('FLAG{sql_injection_success}');
SQL

# Upload
cat > "${ROOT_DIR}/challenges/upload/web/upload.php" <<'PHP'
<?php
// challenges/upload/web/upload.php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!isset($_FILES['file'])) { echo "No file uploaded"; exit; }
    $f = $_FILES['file'];
    $ext = strtolower(pathinfo($f['name'], PATHINFO_EXTENSION));

    // naive check : only by extension (intentionally insecure)
    $allowed = ['jpg','png','pdf'];
    if (!in_array($ext, $allowed)) {
        echo "Type non autorisé";
        exit;
    }

    $uploads_dir = __DIR__ . '/uploads';
    if (!is_dir($uploads_dir)) mkdir($uploads_dir, 0777, true);

    $dest = $uploads_dir . '/' . basename($f['name']);
    if (move_uploaded_file($f['tmp_name'], $dest)) {
        echo "Upload OK. Accédez au fichier ici: /challenges/upload/web/uploads/" . htmlspecialchars(basename($f['name']));
    } else {
        echo "Upload échoué";
    }
}
?>

<h3>Upload (jpg/png/pdf only)</h3>
<form enctype="multipart/form-data" method="post">
  File: <input type="file" name="file"><br>
  <button>Upload</button>
</form>
PHP

cat > "${ROOT_DIR}/challenges/upload/FLAG.txt" <<'FLAG'
FLAG{upload_shell_success}
FLAG

# RCE ping.php
cat > "${ROOT_DIR}/challenges/rce/web/ping.php" <<'PHP'
<?php
// challenges/rce/web/ping.php
if (isset($_GET['host'])) {
    $host = $_GET['host'];
    // VULN volontaire: passthrough to shell
    $cmd = "ping -c 1 " . $host;
    echo "<pre>";
    echo shell_exec($cmd);
    echo "</pre>";
}
?>

<h3>Ping</h3>
<form>
 Host: <input name="host" value="127.0.0.1"><button>Ping</button>
</form>
PHP

cat > "${ROOT_DIR}/challenges/rce/FLAG.txt" <<'FLAG'
FLAG{command_injection_success}
FLAG

# Permissions
chmod -R 0777 "${ROOT_DIR}/challenges/upload/web/uploads" || true

echo "Tous les fichiers ont été créés dans : ${ROOT_DIR}"
echo ""
echo "Prochaines étapes :"
echo "1) cd ${ROOT_DIR}"
echo "2) docker-compose up -d"
echo "3) Ouvre dans ton navigateur :"
echo "   - SQLi : http://localhost:8080/challenges/sqli/web/index.php"
echo "   - Upload: http://localhost:8080/challenges/upload/web/upload.php"
echo "   - RCE: http://localhost:8080/challenges/rce/web/ping.php"
echo ""
echo "Si tu veux que le script lance directement docker-compose, ré-exécute le script avec --run"
echo ""
# Optionnel : lancer docker-compose si argument --run donné
if [[ "${1:-}" == "--run" ]]; then
  echo "Lancement de docker-compose up -d..."
  (cd "${ROOT_DIR}" && docker-compose up -d)
  echo "Containers démarrés. Vérifie avec 'docker ps'."
fi

echo "Script terminé."

