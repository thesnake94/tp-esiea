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
