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
