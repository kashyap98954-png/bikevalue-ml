<?php
// ═══════════════════════════════════════════════════
// BikeValue — api.php  (Flutter JSON API Bridge)
// Place this file in your bikevalue/ folder alongside
// config.php, auth.php, predict.php etc.
// ═══════════════════════════════════════════════════

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

require_once __DIR__ . '/config.php';

$action = $_POST['action'] ?? $_GET['action'] ?? '';

// ── SIGNUP ──────────────────────────────────────────
if ($action === 'signup') {
    $user_id  = trim($_POST['user_id']  ?? '');
    $email    = strtolower(trim($_POST['email'] ?? ''));
    $password = $_POST['password'] ?? '';

    if (strlen($user_id) < 3) { echo json_encode(['success'=>false,'message'=>'Username must be at least 3 characters.']); exit; }
    if (strlen($password) < 6) { echo json_encode(['success'=>false,'message'=>'Password must be at least 6 characters.']); exit; }
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) { echo json_encode(['success'=>false,'message'=>'Invalid email address.']); exit; }

    $pdo = db();
    $stmt = $pdo->prepare('SELECT id FROM users WHERE user_id=? OR email=?');
    $stmt->execute([$user_id, $email]);
    if ($stmt->fetch()) { echo json_encode(['success'=>false,'message'=>'Username or Email already registered.']); exit; }

    $hash = password_hash($password, PASSWORD_DEFAULT);
    $pdo->prepare('INSERT INTO users (user_id,email,password,role) VALUES (?,?,?,"user")')->execute([$user_id,$email,$hash]);
    echo json_encode(['success'=>true,'user_id'=>$user_id,'email'=>$email,'role'=>'user']);
    exit;
}

// ── USER LOGIN ───────────────────────────────────────
if ($action === 'login') {
    $email    = strtolower(trim($_POST['email'] ?? ''));
    $password = $_POST['password'] ?? '';
    $pdo  = db();
    $stmt = $pdo->prepare('SELECT * FROM users WHERE email=? AND role="user"');
    $stmt->execute([$email]);
    $user = $stmt->fetch();
    if ($user && password_verify($password, $user['password'])) {
        echo json_encode(['success'=>true,'user_id'=>$user['user_id'],'email'=>$user['email'],'role'=>'user']);
    } else {
        echo json_encode(['success'=>false,'message'=>'Invalid email or password.']);
    }
    exit;
}

// ── ADMIN LOGIN ──────────────────────────────────────
if ($action === 'admin_login') {
    $email    = strtolower(trim($_POST['email'] ?? ''));
    $password = $_POST['password'] ?? '';
    $pdo  = db();
    $stmt = $pdo->prepare('SELECT * FROM users WHERE email=? AND role="admin"');
    $stmt->execute([$email]);
    $admin = $stmt->fetch();
    if ($admin && password_verify($password, $admin['password'])) {
        echo json_encode(['success'=>true,'user_id'=>$admin['user_id'],'email'=>$admin['email'],'role'=>'admin']);
    } else {
        echo json_encode(['success'=>false,'message'=>'Invalid admin credentials.']);
    }
    exit;
}

// ── SAVE PREDICTION ──────────────────────────────────
if ($action === 'save_prediction') {
    $pdo = db();
    $pdo->prepare('INSERT INTO predictions (user_id,bike_name,brand,engine_cc,bike_age,owner_type,km_driven,accident_count,accident_history,predicted_price,ml_price) VALUES (?,?,?,?,?,?,?,?,?,?,?)')
        ->execute([
            $_POST['user_id'], $_POST['bike_name'], $_POST['brand'],
            (int)$_POST['engine_cc'], (int)$_POST['bike_age'],
            $_POST['owner_type'] ?? '1st',
            (int)$_POST['km_driven'], (int)$_POST['accident_count'],
            $_POST['accident_history'] ?? 'none',
            (float)$_POST['predicted_price'],
            isset($_POST['ml_price']) && $_POST['ml_price'] !== '' ? (float)$_POST['ml_price'] : null,
        ]);
    echo json_encode(['success'=>true,'id'=>$pdo->lastInsertId()]);
    exit;
}

// ── PREDICTION HISTORY ───────────────────────────────
if ($action === 'history') {
    $pdo  = db();
    $stmt = $pdo->prepare('SELECT * FROM predictions WHERE user_id=? ORDER BY created_at DESC LIMIT 30');
    $stmt->execute([$_GET['user_id'] ?? '']);
    echo json_encode(['success'=>true,'data'=>$stmt->fetchAll()]);
    exit;
}

// ── ADMIN STATS ──────────────────────────────────────
if ($action === 'admin_stats') {
    $pdo = db();
    $stats = [
        'total_users' => $pdo->query('SELECT COUNT(*) FROM users WHERE role="user"')->fetchColumn(),
        'total_preds' => $pdo->query('SELECT COUNT(*) FROM predictions')->fetchColumn(),
        'with_acc'    => $pdo->query('SELECT COUNT(*) FROM predictions WHERE accident_count>0')->fetchColumn(),
        'avg_price'   => round($pdo->query('SELECT AVG(predicted_price) FROM predictions')->fetchColumn() ?? 0),
        'ml_count'    => $pdo->query('SELECT COUNT(*) FROM predictions WHERE ml_price IS NOT NULL')->fetchColumn(),
        'brand_data'  => $pdo->query('SELECT brand,COUNT(*) AS cnt FROM predictions GROUP BY brand ORDER BY cnt DESC')->fetchAll(),
        'recent_preds'=> $pdo->query('SELECT * FROM predictions ORDER BY created_at DESC LIMIT 10')->fetchAll(),
        'users'       => $pdo->query('SELECT user_id,email,created_at FROM users WHERE role="user" ORDER BY created_at DESC')->fetchAll(),
    ];
    echo json_encode(['success'=>true,'data'=>$stats]);
    exit;
}

// ── ALL PREDICTIONS (admin) ───────────────────────────
if ($action === 'all_predictions') {
    $pdo = db();
    $rows = $pdo->query('SELECT * FROM predictions ORDER BY created_at DESC LIMIT 100')->fetchAll();
    echo json_encode(['success'=>true,'data'=>$rows]);
    exit;
}

echo json_encode(['error'=>'Unknown action']);
