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
