<?php
session_start();
require_once __DIR__ . '/config.php';
if (empty($_SESSION['user_id']) || $_SESSION['role'] !== 'user') {
    header('Location: index.php'); exit;
}

$brands = ['Royal Enfield','Yamaha','Honda','Bajaj','TVS','KTM','Suzuki','Kawasaki','Hero','Triumph'];
$bike_names_by_brand = [
    'Royal Enfield' => ['Classic 350','Classic 500','Bullet 350','Bullet 500','Thunderbird 350','Thunderbird 500','Himalayan','Meteor 350','Hunter 350'],
    'Yamaha'        => ['FZ-S V3','FZ25','R15 V4','MT-15','R3','FZS-FI','Fazer 25','YZF R15','Ray ZR','Fascino','Alpha','SZ-RR'],
    'Honda'         => ['CB Shine','CB Hornet 160R','CB350','CB500F','CBR650R','Activa 6G','Unicorn','Livo','SP 125','Shine SP','CB200X','NX200'],
    'Bajaj'         => ['Pulsar 150','Pulsar 180','Pulsar 220F','Pulsar NS200','Pulsar RS200','Dominar 400','Avenger 220','CT100','Platina','Pulsar N250','Pulsar F250','Dominar 250'],
    'TVS'           => ['Apache RTR 160','Apache RTR 200','Apache RR 310','Jupiter','NTorq 125','Raider 125','Ronin','iQube Electric','Star City+','Sport','HLX 125','Radeon'],
    'KTM'           => ['Duke 200','Duke 250','Duke 390','RC 200','RC 390','Adventure 250','Adventure 390','Duke 125','RC 125'],
    'Suzuki'        => ['Gixxer SF','Gixxer 250','V-Strom 650','Access 125','Burgman Street','Intruder 150','Avenis 125'],
    'Kawasaki'      => ['Ninja 300','Ninja 400','Ninja 650','Z650','Versys 650','W175','Vulcan S'],
    'Hero'          => ['Splendor Plus','Passion Pro','HF Deluxe','Glamour','Xtreme 160R','Xpulse 200','Maestro Edge','Destini 125','Super Splendor'],
    'Triumph'       => ['Tiger 660','Trident 660'],
];
$cities    = ['Mumbai','Delhi','Bangalore','Chennai','Hyderabad','Pune','Kolkata','Ahmedabad','Jaipur','Lucknow','Chandigarh','Kochi'];
$acc_types = ['none','minor','major','severe'];

// Pull saved form for back/edit
$prev   = $_SESSION['last_form'] ?? [];
$isEdit = isset($_GET['edit']) && !empty($prev);
$pv     = $isEdit ? $prev : [];

$prediction = $ml_price = $ml_adjusted = $ml_impact = $ml_error = $city_adjustment = $city_adjustment_amount = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $brand           = $_POST['brand']            ?? '';
    $bike_name       = $_POST['bike_name']         ?? '';
    $engine_capacity = (float)($_POST['engine_capacity'] ?? 0);
    $age             = (float)($_POST['age']        ?? 0);
    $owner           = (float)($_POST['owner']      ?? 1);
    $kms_driven      = (float)($_POST['kms_driven'] ?? 0);
    $city            = $_POST['city']              ?? '';
    $accident_count  = (float)($_POST['accident_count'] ?? 0);
    $accident_history = $accident_count == 0 ? 'none' : trim($_POST['accident_history'] ?? 'none');

    // Save for back/edit pre-fill
    $_SESSION['last_form'] = compact('brand','bike_name','engine_capacity','age','owner','kms_driven','city','accident_count','accident_history');

    if ($engine_capacity <= 0) $ml_error = 'Please enter a valid engine capacity (cc).';

    // Fallback city pricing (no database query - simpler and more reliable)
    $fallback_cities = [
        'mumbai' => 8500, 'delhi' => 6500, 'bangalore' => 7200, 'chennai' => 5800,
        'hyderabad' => 6200, 'pune' => 7100, 'kolkata' => 5500, 'ahmedabad' => 6800,
        'jaipur' => 5900, 'lucknow' => 5300, 'chandigarh' => 7800, 'kochi' => 6100
    ];
    $city_adjustment_amount = $fallback_cities[strtolower($city)] ?? null;
    $city_adjustment = $city;

    if (function_exists('curl_init')) {
        $payload = [
            'bike_name' => strtolower($bike_name), 'kms_driven' => $kms_driven,
            'owner' => $owner, 'age' => $age, 'city' => strtolower($city),
            'engine_capacity' => $engine_capacity, 'accident_count' => $accident_count,
            'brand' => strtolower($brand), 'accident_history' => $accident_history,
        ];
        $raw = json_encode($payload);
        $ch  = curl_init('http://localhost:5000/predict');
        
        if ($ch !== false) {
            curl_setopt_array($ch, [CURLOPT_POST => true, CURLOPT_RETURNTRANSFER => true,
                CURLOPT_TIMEOUT => 3, CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                CURLOPT_POSTFIELDS => $raw, CURLOPT_CONNECTTIMEOUT => 2]);
            $res  = curl_exec($ch);
            $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            if ($code === 200 && $res) {
                $d = json_decode($res, true);
                $ml_price    = isset($d['predicted_price'])    ? (float)$d['predicted_price']    : null;
                $ml_adjusted = isset($d['predicted_adjusted']) ? (float)$d['predicted_adjusted'] : null;
                $ml_impact   = ($ml_price !== null && $ml_adjusted !== null) ? round($ml_price - $ml_adjusted, 2) : (isset($d['accident_impact']) ? (float)$d['accident_impact'] : null);
                $prediction['debug_payload']  = $raw;
                $prediction['debug_response'] = $res;
            } else { 
                $ml_error = 'Using fallback price calculation (ML API offline)'; 
            }
        } else {
            $ml_error = 'Using fallback price calculation (ML API unreachable)';
        }
    }

    // ══════════════════════════════════════════════════════════════
    // FALLBACK PRICE CALCULATION (when ML API is offline)
    // ══════════════════════════════════════════════════════════════
    if ($ml_price === null) {
        // Base price calculation using simple formula
        // Price = Engine CC * Base Rate - Age Depreciation + Owner Penalty - KM Depreciation
        $base_rate = 120; // ₹ per cc
        $ml_price = $engine_capacity * $base_rate;
        
        // Age depreciation: 15% per year
        $ml_price -= ($ml_price * 0.15 * $age);
        
        // KM depreciation: ₹1 per 100km
        $ml_price -= ($kms_driven / 100);
        
        // Owner penalty: Each owner adds 5% depreciation
        $ml_price -= ($ml_price * 0.05 * ($owner - 1));
        
        // Ensure price is reasonable (minimum 50k)
        $ml_price = max($ml_price, 50000);
        
        // Accident adjustment
        if ($accident_count > 0) {
            $accident_deduction = 0;
            if ($accident_history === 'minor') $accident_deduction = 0.10;
            if ($accident_history === 'major') $accident_deduction = 0.20;
            if ($accident_history === 'severe') $accident_deduction = 0.35;
            
            $ml_adjusted = $ml_price * (1 - $accident_deduction);
            $ml_impact = round($ml_price - $ml_adjusted, 0);
        }
    }

    $final_price = $ml_price !== null ? $ml_price : 0;
    
    // Apply city pricing adjustment to final price
    $final_price_with_city = $final_price;
    if ($city_adjustment_amount !== null && $final_price > 0) {
        $final_price_with_city = $final_price + $city_adjustment_amount;
    }
    
    if (empty($ml_error) && function_exists('curl_init')) {
        $chh = curl_init('http://localhost:5000/health');
        if ($chh !== false) {
            curl_setopt_array($chh, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 1, CURLOPT_CONNECTTIMEOUT => 1]);
            curl_exec($chh);
            curl_close($chh);
        }
    }

    $db_ml = ($ml_adjusted !== null) ? $ml_adjusted : $ml_price;
    
    // Try to save to database, but don't fail if DB is down
    try {
        db()->prepare('INSERT INTO predictions(user_id,bike_name,brand,engine_cc,bike_age,owner_type,km_driven,accident_history,accident_count,predicted_price,ml_price)VALUES(?,?,?,?,?,?,?,?,?,?,?)')
            ->execute([$_SESSION['user_id'],$bike_name,$brand,(int)$engine_capacity,(int)$age,"Owner $owner",(int)$kms_driven,(int)($accident_count>0),(int)$accident_count,$final_price_with_city,$db_ml]);
    } catch (Exception $e) {
        // Database not available - continue anyway, show results
        // User can still see prediction without saving
    }

    $prediction = [
        'ml_price' => $ml_price, 'ml_adjusted' => $ml_adjusted,
        'ml_impact' => $ml_impact, 'final_price' => $final_price_with_city,
        'ml_error' => $ml_error, 'has_accident' => $accident_count > 0,
        'brand' => $brand, 'bike_name' => $bike_name,
        'city' => ucfirst($city), 'city_adjustment' => $city_adjustment_amount,
        'params' => [
            ['label'=>'Brand',            'val'=>$brand,                                          'impact'=>'High'],
            ['label'=>'Model',            'val'=>$bike_name,                                      'impact'=>'Medium'],
            ['label'=>'Engine',           'val'=>$engine_capacity.' cc',                          'impact'=>'High'],
            ['label'=>'Age',              'val'=>$age.' yr'.($age!=1?'s':''),                     'impact'=>$age<=2?'Low':'High'],
            ['label'=>'Ownership',        'val'=>'Owner '.(int)$owner,                            'impact'=>$owner==1?'Low':'High'],
            ['label'=>'Odometer',         'val'=>number_format($kms_driven).' km',                'impact'=>$kms_driven<30000?'Low':'High'],
            ['label'=>'City',             'val'=>ucfirst($city).($city_adjustment_amount!==null ? ' (+₹'.number_format($city_adjustment_amount).')' : ''), 'impact'=>'Medium'],
            ['label'=>'Accident Severity','val'=>ucfirst($accident_history),                      'impact'=>$accident_count>0?'High':'Low'],
            ['label'=>'Accident Count',   'val'=>(int)$accident_count,                            'impact'=>$accident_count>0?'High':'Low'],
        ],
    ];
}

// Pre-fill helpers
$pBrand    = htmlspecialchars($pv['brand']            ?? '');
$pCC       = htmlspecialchars($pv['engine_capacity']  ?? '');
$pAge      = htmlspecialchars($pv['age']              ?? '');
$pOwner    = htmlspecialchars($pv['owner']            ?? 1);
$pKms      = htmlspecialchars($pv['kms_driven']       ?? '');
$pCity     = htmlspecialchars($pv['city']             ?? '');
$pAccCnt   = htmlspecialchars($pv['accident_count']   ?? 0);
$pAccHist  = htmlspecialchars($pv['accident_history'] ?? 'none');
$pBikeName = strtolower($pv['bike_name'] ?? '');
?>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= $prediction ? 'Valuation Result' : 'Predict Value' ?> — BikeValue</title>
<link rel="stylesheet" href="theme.css">
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,600;1,300;1,600&display=swap" rel="stylesheet">
<style>

/* ══════════════════════════════════════
   PREDICT PAGE — TRIUMPH PREMIUM LOGO BG
══════════════════════════════════════ */
.moto-bg::before {
    background:
        url('https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Triumph_Motorcycles_Logo.svg/1200px-Triumph_Motorcycles_Logo.svg.png')
        center 50% / contain no-repeat !important;
    opacity: 0.08;
    animation: slowDrift 25s ease-in-out infinite alternate !important;
}

@keyframes slowDrift {
    from { transform: scale(1.0) translateX(0px); }
    to   { transform: scale(1.08) translateX(-20px); }
}

.moto-bg::after {
    background:
        linear-gradient(135deg,
            rgba(15,10,5,0.98)   0%,
            rgba(25,10,15,0.92)  30%,
            rgba(40,10,25,0.75)  55%,
            rgba(10,5,15,0.95)   80%,
            rgba(15,10,5,0.98)   100%),
        radial-gradient(ellipse 70% 80% at 70% 45%,
            rgba(229,57,53,0.2) 0%,
            transparent 65%) !important;
}

main {
  position: relative; z-index: 10;
  max-width: 940px; margin: 0 auto;
  padding: 3rem 1.5rem 6rem;
}

/* Eyebrow label */
.page-eyebrow {
  display: flex; align-items: center; gap: 1rem;
  margin-bottom: 2.2rem;
  font-family: 'Space Mono', monospace;
  font-size: .6rem; letter-spacing: 4px;
  text-transform: uppercase; color: var(--muted);
}
.page-eyebrow span { color: var(--v2); }
.page-eyebrow::before { content: ''; width: 24px; height: 1px; background: linear-gradient(90deg, var(--v1), transparent); }
.page-eyebrow::after  { content: ''; flex: 1; height: 1px; background: linear-gradient(90deg, rgba(229,57,53,.2), transparent); }

/* Section dividers */
.section-divider {
  display: flex; align-items: center; gap: 1rem;
  margin: .6rem 0 .2rem; grid-column: span 2;
}
.section-divider span {
  font-size: .6rem; letter-spacing: 3.5px; text-transform: uppercase;
  color: var(--v2); white-space: nowrap; font-weight: 700;
}
.section-divider::before,
.section-divider::after { content: ''; flex: 1; height: 1px; background: rgba(240,98,146,.14); }

/* ══ PREMIUM BACK / REFINE BUTTON ══ */
.btn-refine {
  display: inline-flex; align-items: center; gap: .8rem;
  font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-size: 1.05rem; font-weight: 600;
  letter-spacing: 1px; color: #c9a84c;
  background: transparent;
  border: 1px solid rgba(201,168,76,.3);
  border-radius: 4px;
  padding: .72rem 1.8rem .72rem 1.2rem;
  text-decoration: none; cursor: pointer;
  position: relative; overflow: hidden;
  transition: color .3s, border-color .35s, box-shadow .35s;
}
.btn-refine::before {
  content: ''; position: absolute; inset: 0;
  background: linear-gradient(135deg, rgba(201,168,76,.06), transparent 60%);
  opacity: 0; transition: opacity .3s;
}
.btn-refine:hover { color: #e8c96a; border-color: rgba(201,168,76,.7); box-shadow: 0 0 28px rgba(201,168,76,.18), inset 0 0 20px rgba(201,168,76,.04); }
.btn-refine:hover::before { opacity: 1; }
.btn-refine .arrow-ring {
  width: 26px; height: 26px;
  border: 1px solid rgba(201,168,76,.45); border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: .88rem; font-style: normal; flex-shrink: 0;
  transition: transform .35s cubic-bezier(.34,1.56,.64,1), border-color .3s;
}
.btn-refine:hover .arrow-ring { transform: translateX(-4px); border-color: rgba(201,168,76,.85); }

/* Edit mode banner */
.edit-banner {
  display: flex; align-items: flex-start; gap: 1rem;
  background: linear-gradient(135deg, rgba(201,168,76,.07), rgba(201,168,76,.02));
  border: 1px solid rgba(201,168,76,.22);
  border-left: 3px solid #c9a84c;
  border-radius: 6px; padding: 1rem 1.4rem;
  margin-bottom: 2rem; font-size: .83rem;
  letter-spacing: .4px; line-height: 1.65;
  color: rgba(201,168,76,.88);
}
.edit-banner .edit-icon { font-size: 1.05rem; margin-top: .05rem; flex-shrink: 0; }
.edit-banner strong { color: #c9a84c; }

/* ══ RESULT HEADER ══ */
.result-header {
  display: flex; align-items: center; gap: 1.8rem;
  margin-bottom: 2.4rem; padding-bottom: 2rem;
  border-bottom: 1px solid rgba(229,57,53,.12);
}
.bike-id-badge {
  flex-shrink: 0; width: 70px; height: 70px; border-radius: 50%;
  background: linear-gradient(135deg, rgba(229,57,53,.18), rgba(13,71,161,.1));
  border: 1px solid rgba(229,57,53,.38);
  display: flex; align-items: center; justify-content: center;
  font-size: 1.9rem;
  box-shadow: 0 0 36px rgba(229,57,53,.18);
}
.result-meta h2 {
  font-family: 'Playfair Display', serif;
  font-size: 1.9rem; font-weight: 700; line-height: 1.18; color: var(--text);
}
.result-sub {
  font-size: .68rem; letter-spacing: 3px; text-transform: uppercase;
  color: var(--muted); margin-top: .35rem;
}

/* Price cards */
.price-cards {
  display: grid; grid-template-columns: repeat(auto-fit, minmax(220px,1fr));
  gap: 1.2rem; margin-bottom: 2.6rem;
}
.price-box {
  border-radius: 14px; padding: 2rem 1.6rem; text-align: center;
  position: relative; overflow: hidden;
  transition: transform .3s cubic-bezier(.34,1.56,.64,1), box-shadow .3s;
}
.price-box:hover { transform: translateY(-5px) scale(1.015); }
.price-box--main {
  background: linear-gradient(145deg, rgba(229,57,53,.16), rgba(13,71,161,.08));
  border: 1px solid rgba(229,57,53,.42);
  box-shadow: 0 0 48px rgba(229,57,53,.1), inset 0 1px 0 rgba(229,57,53,.2);
}
.price-box--main::before {
  content: ''; position: absolute; top: 0; left: 0; right: 0; height: 2px;
  background: linear-gradient(90deg, var(--v3), var(--v1), var(--b1));
}
.price-box--main::after {
  content: ''; position: absolute; top: -40px; right: -40px;
  width: 120px; height: 120px;
  background: radial-gradient(circle, rgba(229,57,53,.2), transparent 70%);
}
.price-box--adj {
  background: linear-gradient(145deg, rgba(248,113,113,.09), rgba(239,68,68,.04));
  border: 1px solid rgba(248,113,113,.26);
}
.price-box--adj::before {
  content: ''; position: absolute; top: 0; left: 0; right: 0; height: 2px;
  background: linear-gradient(90deg, #f87171, #fca5a5, transparent);
}
.price-label { font-size: .62rem; letter-spacing: 3.5px; text-transform: uppercase; color: var(--muted); margin-bottom: 1rem; }
.price-value {
  font-family: 'Playfair Display', serif; font-size: 2.5rem; font-weight: 700; line-height: 1;
  background: linear-gradient(135deg, var(--v2), var(--b2), var(--cyan));
  -webkit-background-clip: text; background-clip: text; -webkit-text-fill-color: transparent;
}
.price-note  { font-size: .72rem; color: var(--muted); margin-top: .6rem; }
.price-impact { font-size: .84rem; color: #fca5a5; margin-top: .5rem; font-weight: 700; letter-spacing: .5px; }
.ml-badge {
  display: inline-flex; align-items: center; gap: .4rem;
  background: linear-gradient(135deg, rgba(52,211,153,.12), rgba(34,211,238,.08));
  border: 1px solid rgba(52,211,153,.28); color: #6ee7b7;
  font-size: .58rem; letter-spacing: 2px; padding: .22rem .9rem;
  border-radius: 20px; margin-bottom: .8rem;
}
.ml-badge::before { content: '●'; font-size: .5rem; animation: pulseGlow 1.8s ease-in-out infinite; }


/* Table */
.breakdown-title {
  font-size: .62rem; letter-spacing: 3.5px; text-transform: uppercase;
  color: var(--v2); margin-bottom: 1.1rem; font-weight: 700;
  display: flex; align-items: center; gap: .8rem;
}
.breakdown-title::after { content: ''; flex: 1; height: 1px; background: linear-gradient(90deg, rgba(229,57,53,.3), transparent); }
table { width: 100%; border-collapse: collapse; }
th, td { padding: .9rem 1.1rem; text-align: left; font-size: .88rem; }
th { font-size: .6rem; letter-spacing: 2.5px; text-transform: uppercase; color: var(--muted); border-bottom: 1px solid rgba(229,57,53,.12); background: rgba(229,57,53,.03); }
tr:not(:last-child) td { border-bottom: 1px solid rgba(229,57,53,.06); }
tr:hover td { background: rgba(229,57,53,.04); }
td:first-child { color: var(--muted); font-size: .82rem; letter-spacing: .5px; }
td:nth-child(2) { font-weight: 600; color: var(--text); }

/* ml-offline */
.ml-offline {
  background: rgba(248,113,113,.07); border: 1px solid rgba(248,113,113,.2);
  border-left: 3px solid #f87171; color: #fca5a5;
  padding: .9rem 1.2rem; border-radius: 6px;
  font-size: .84rem; margin-bottom: 1.8rem; letter-spacing: .3px;
}

/* Actions */
.actions { display: flex; gap: 1rem; margin-top: 2.6rem; align-items: center; flex-wrap: wrap; }
.actions-divider { width: 1px; height: 34px; background: rgba(124,92,252,.2); }

/* Scrollbar */
::-webkit-scrollbar { width: 5px; }
::-webkit-scrollbar-track { background: var(--bg); }
::-webkit-scrollbar-thumb { background: rgba(124,92,252,.3); border-radius: 3px; }

@media (max-width: 680px) {
  .result-header { flex-direction: column; gap: 1rem; }
  .section-divider { grid-column: span 1; }
  .actions { flex-direction: column; align-items: stretch; }
  .actions-divider { display: none; }
  .btn-refine { justify-content: center; }
}
</style>
</head>
<body>
<div class="moto-bg"></div>
<div class="light-bleed"></div>
<div class="grain"></div>
<div class="grid-overlay"></div>

<nav class="navbar">
  <a class="nav-brand" href="index.php">⚡ BIKE<span>VALUE</span></a>
  <div style="display:flex;align-items:center;gap:1.2rem">
    <span class="nav-user">Rider: <strong><?= htmlspecialchars($_SESSION['user_id']) ?></strong></span>
    <form action="auth.php" method="POST" style="margin:0">
      <input type="hidden" name="action" value="logout">
      <button class="btn btn-danger">Logout</button>
    </form>
  </div>
</nav>

<main>
<?php if (!$prediction): ?>

<!-- ══════════ FORM VIEW ══════════ -->
<div class="glass-card anim-1">

  <div class="page-eyebrow"><span>Valuation Engine</span> // ML Precision Model</div>

  <h2 class="card-title" style="font-size:2.25rem;line-height:1.15">
    <?= $isEdit
      ? 'Refine Your <em style="font-style:italic;color:var(--v2)">Inputs</em>'
      : 'Predict Your Bike\'s <em style="font-style:italic;color:var(--v2)">Value</em>'
    ?>
  </h2>
  <p class="card-sub" style="margin-bottom:1.6rem">
    <?= $isEdit ? 'Previous inputs restored — adjust and re-run' : 'Fill every field for maximum ML accuracy' ?>
  </p>

  <?php if ($isEdit): ?>
  <div class="edit-banner">
    <span class="edit-icon">✎</span>
    <div>
      <strong>Editing your previous entry.</strong> Every field has been restored exactly as you left it.
      Adjust anything you need and hit <strong>Predict</strong> to get a fresh valuation.
    </div>
  </div>
  <?php endif; ?>

  <div class="info-banner">
    ✦ Keep <code style="background:rgba(124,92,252,.15);padding:.1rem .4rem;border-radius:4px;font-size:.82rem">python ml_api.py</code> running in VS Code for live ML predictions.
  </div>

  <form action="predict.php" method="POST">
    <div class="form-grid">

      <div class="section-divider"><span>Bike Details</span></div>

      <div class="form-group">
        <label class="form-label">Brand</label>
        <select name="brand" id="brandSelect" class="form-input" required onchange="updateBikeNames()">
          <option value="" disabled <?= !$pBrand ? 'selected' : '' ?>>Select Brand</option>
          <?php foreach ($brands as $b): ?>
            <option <?= $pBrand === htmlspecialchars($b) ? 'selected' : '' ?>><?= $b ?></option>
          <?php endforeach; ?>
        </select>
      </div>

      <div class="form-group">
        <label class="form-label">Model (Select or Enter Custom)</label>
        <div style="display:flex;gap:0.8rem;align-items:flex-start">
          <select name="bike_name_select" id="bikeNameSelect" class="form-input" style="flex:1" onchange="updateBikeNameFromSelect(); updateEngineCC()">
            <option value="" selected>Select from List or Type Below</option>
          </select>
        </div>
        <input type="text" name="bike_name" id="bikeNameInput" class="form-input" 
               placeholder="Or enter any bike model name" 
               value="<?= $pBikeName ?>" required
               style="margin-top:0.6rem">
        <span id="model-hint" style="font-size:.7rem;letter-spacing:.5px;margin-top:.3rem;color:var(--muted);transition:color .3s;"></span>
      </div>

      <?php echo '<script>const bikeNamesByBrand=' . json_encode($bike_names_by_brand) . ';</script>'; ?>

      <div class="form-group">
        <label class="form-label">Engine Capacity (cc)</label>
        <input type="number" name="engine_capacity" id="engineCC" class="form-input"
               placeholder="Auto-filled or enter manually" min="0" max="3000"
               value="<?= $pCC ?>" required>
        <span id="cc-hint" style="font-size:.7rem;letter-spacing:.5px;margin-top:.3rem;transition:color .3s;"></span>
      </div>

      <div class="form-group">
        <label class="form-label">Bike Age (Years)</label>
        <input type="number" name="age" class="form-input" placeholder="e.g. 3"
               min="0" max="30" value="<?= $pAge ?>" required>
      </div>

      <div class="form-group">
        <label class="form-label">Owner Number</label>
        <input type="number" name="owner" class="form-input" placeholder="1 = first owner"
               min="1" max="5" value="<?= $pOwner ?: 1 ?>" required>
      </div>

      <div class="form-group">
        <label class="form-label">Kilometers Driven</label>
        <input type="number" name="kms_driven" class="form-input" placeholder="e.g. 15000"
               min="0" value="<?= $pKms ?>" required>
      </div>

      <div class="form-group">
        <label class="form-label">City</label>
        <select name="city" class="form-input" required>
          <option value="" disabled <?= !$pCity ? 'selected' : '' ?>>Select City</option>
          <?php foreach ($cities as $c): ?>
            <option value="<?= strtolower($c) ?>" <?= $pCity === strtolower($c) ? 'selected' : '' ?>><?= $c ?></option>
          <?php endforeach; ?>
        </select>
      </div>

      <div class="form-group"></div>

      <div class="section-divider"><span>Accident History</span></div>

      <div class="form-group">
        <label class="form-label">Number of Accidents</label>
        <input type="number" name="accident_count" id="accCnt" class="form-input"
               placeholder="0" min="0" value="<?= $pAccCnt ?>" oninput="toggleAcc()">
      </div>

      <div class="form-group" id="accHistGroup" style="display:<?= (int)$pAccCnt > 0 ? 'flex' : 'none' ?>">
        <label class="form-label">Accident Severity</label>
        <select name="accident_history" class="form-input">
          <?php foreach ($acc_types as $a): ?>
            <option value="<?= $a ?>" <?= $pAccHist === $a ? 'selected' : '' ?>><?= ucfirst($a) ?></option>
          <?php endforeach; ?>
        </select>
      </div>

    </div>
    <div class="form-submit">
      <button type="submit" class="btn btn-primary btn-lg">⚡ &nbsp;Predict Price Now →</button>
    </div>
  </form>
</div>

<?php else: ?>

<!-- ══════════ RESULT VIEW ══════════ -->
<div class="glass-card anim-1">

  <div class="page-eyebrow"><span>Valuation Complete</span> // Random Forest · High Confidence</div>

  <!-- Bike identity header -->
  <div class="result-header">
    <div class="bike-id-badge">🏍</div>
    <div class="result-meta">
      <h2>
        <?= htmlspecialchars(ucwords($prediction['bike_name'] ?? 'Your Bike')) ?>
        <span style="color:var(--muted);font-family:'Cormorant Garamond',serif;font-style:italic;font-weight:300;font-size:1.4rem">
          &nbsp;by <?= htmlspecialchars(ucwords($prediction['brand'] ?? '')) ?>
        </span>
      </h2>
      <p class="result-sub">ML Model Valuation &nbsp;·&nbsp; Random Forest Regressor</p>
    </div>
  </div>

  <?php if ($prediction['ml_error']): ?>
    <div class="ml-offline">⚠ &nbsp;<?= htmlspecialchars($prediction['ml_error']) ?></div>
  <?php endif; ?>

  <!-- Price cards -->
  <div class="price-cards">
    <div class="price-box price-box--main">
      <?php if ($prediction['ml_price']): ?>
        <div class="ml-badge">ML Model Result</div>
      <?php endif; ?>
      <div class="price-label">Market Valuation</div>
      <div class="price-value">₹<?= number_format($prediction['final_price'] ?? 0) ?></div>
      <div class="price-note">Base price before accident adjustment</div>
    </div>

    <?php if ($prediction['has_accident'] && $prediction['ml_adjusted']): ?>
    <div class="price-box price-box--adj">
      <div class="price-label">Post-Accident Price</div>
      <div class="price-value" style="-webkit-text-fill-color:#fca5a5;background:none;color:#fca5a5">
        ₹<?= number_format($prediction['ml_adjusted']) ?>
      </div>
      <div class="price-impact">↓ ₹<?= number_format($prediction['ml_impact']) ?> value loss</div>
      <div class="price-note">Adjusted for accident history</div>
    </div>
    <?php endif; ?>
  </div>


  <!-- Debug (collapsed) -->
  <?php if (!empty($prediction['debug_payload'])): ?>
    <div style="margin-bottom:1.8rem;font-size:.78rem;">
      <details style="color:var(--muted)">
        <summary style="cursor:pointer;letter-spacing:1px;font-size:.68rem;user-select:none">🔍 &nbsp;ML API Debug</summary>
        <pre style="margin-top:.7rem;background:rgba(0,0,0,.3);padding:1rem;border-radius:6px;overflow-x:auto;font-size:.72rem;line-height:1.6"><?= htmlspecialchars($prediction['debug_payload']) ?></pre>
        <pre style="margin-top:.4rem;background:rgba(0,0,0,.3);padding:1rem;border-radius:6px;overflow-x:auto;font-size:.72rem;line-height:1.6"><?= htmlspecialchars($prediction['debug_response']) ?></pre>
      </details>
    </div>
  <?php endif; ?>

  <!-- Parameter breakdown -->
  <div class="breakdown-title">Parameter Breakdown</div>
  <table>
    <thead><tr><th>Parameter</th><th>Value</th><th>Price Impact</th></tr></thead>
    <tbody>
    <?php foreach ($prediction['params'] as $p): ?>
      <tr>
        <td><?= htmlspecialchars($p['label']) ?></td>
        <td><?= htmlspecialchars($p['val']) ?></td>
        <td><span class="badge badge--<?= strtolower($p['impact']) ?>"><?= $p['impact'] ?></span></td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table>

  <!-- ═══ ACTIONS ═══ -->
  <div class="actions">

    <!-- ★ BACK / REFINE BUTTON ★ -->
    <a href="predict.php?edit=1" class="btn-refine">
      <span class="arrow-ring">←</span>
      <em>Refine Inputs</em>
    </a>

    <div class="actions-divider"></div>

    <a href="predict.php" class="btn btn-primary btn-lg">⚡ &nbsp;New Valuation →</a>

    <form action="auth.php" method="POST" style="margin:0;margin-left:auto">
      <input type="hidden" name="action" value="logout">
      <button class="btn btn-ghost">Logout</button>
    </form>
  </div>

</div>
<?php endif; ?>
</main>

<script>
const engineCC = {
  'classic 350':350,'classic 500':500,'bullet 350':346,'bullet 500':499,
  'thunderbird 350':346,'thunderbird 500':499,'himalayan':411,'meteor 350':349,
  'hunter 350':349,'super meteor 650':648,'continental gt 650':648,'interceptor 650':648,
  'fz-s v3':149,'fz25':249,'r15 v4':155,'mt-15':155,'r3':321,'fzs-fi':149,
  'fazer 25':249,'yzf r15':155,'ray zr':125,'fascino':125,'alpha':113,'sz-rr':153,
  'cb shine':124,'cb hornet 160r':163,'cb350':348,'cb500f':471,'cbr650r':649,
  'activa 6g':109,'unicorn':162,'livo':109,'sp 125':124,'shine sp':124,'cb200x':184,'nx200':184,
  'pulsar 150':149,'pulsar 180':178,'pulsar 220f':220,'pulsar ns200':199,'pulsar rs200':199,
  'dominar 400':373,'avenger 220':220,'ct100':102,'platina':102,'pulsar n250':250,
  'pulsar f250':250,'dominar 250':248,
  'apache rtr 160':159,'apache rtr 200':197,'apache rr 310':312,'jupiter':109,'ntorq 125':124,
  'raider 125':124,'ronin':225,'iqube electric':0,'star city+':109,'sport':99,'hlx 125':124,'radeon':109,
  'duke 200':199,'duke 250':248,'duke 390':373,'rc 200':199,'rc 390':373,
  'adventure 250':248,'adventure 390':373,'duke 125':124,'rc 125':124,
  'gixxer sf':155,'gixxer 250':249,'v-strom 650':645,'access 125':124,'burgman street':124,
  'intruder 150':154,'hayabusa':1340,'gsx-s750':749,'avenis 125':124,
  'ninja 300':296,'ninja 400':399,'ninja 650':649,'z650':649,'z900':948,
  'versys 650':649,'w175':177,'vulcan s':649,'ninja zx-10r':998,
  'splendor plus':97,'passion pro':97,'hf deluxe':97,'glamour':124,'xtreme 160r':163,
  'xpulse 200':199,'maestro edge':110,'destini 125':124,'super splendor':124,
  'street triple r':765,'speed triple 1200':1160,'tiger 900':888,'bonneville t100':900,
  'bonneville t120':1200,'scrambler 1200':1200,'rocket 3':2458,'tiger 660':660,
  'trident 660':660,'speed twin 900':900,'thruxton rs':1200,'tiger 1200':1160,
};

function updateBikeNames() {
  const brand = document.getElementById('brandSelect').value;
  const sel   = document.getElementById('bikeNameSelect');
  sel.innerHTML = '<option value="">Select from List or Type Below</option>';
  if (bikeNamesByBrand[brand]) {
    bikeNamesByBrand[brand].forEach(n => {
      const o = document.createElement('option');
      o.value = n.toLowerCase(); o.textContent = n; sel.appendChild(o);
    });
    sel.disabled = false;
  }
  document.getElementById('engineCC').value = '';
  document.getElementById('model-hint').textContent = '';
}

function updateBikeNameFromSelect() {
  const selected = document.getElementById('bikeNameSelect').value;
  if (selected) {
    document.getElementById('bikeNameInput').value = selected;
  }
}

function updateEngineCC() {
  const bikeText = document.getElementById('bikeNameInput').value.toLowerCase().trim();
  const cc   = document.getElementById('engineCC');
  const hint = document.getElementById('model-hint');
  
  if (!bikeText) {
    cc.value = '';
    hint.textContent = '';
    return;
  }
  
  if (engineCC[bikeText] !== undefined && engineCC[bikeText] > 0) {
    cc.value = engineCC[bikeText];
    hint.innerHTML = '✓ &nbsp;Auto-filled: <strong>' + engineCC[bikeText] + ' cc</strong>';
    hint.style.color = 'var(--v2)';
    cc.style.borderColor = 'rgba(229,57,53,0.8)';
    cc.style.boxShadow   = '0 0 0 3px rgba(229,57,53,0.15)';
    setTimeout(() => { cc.style.borderColor = ''; cc.style.boxShadow = ''; }, 2200);
  } else if (engineCC[bikeText] === 0) {
    cc.value = ''; hint.textContent = 'Electric — enter 0 or leave blank'; hint.style.color = 'var(--muted)';
  } else {
    hint.textContent = 'Enter CC manually'; hint.style.color = 'var(--muted)';
  }
}

function toggleAcc() {
  const n = parseInt(document.getElementById('accCnt').value) || 0;
  document.getElementById('accHistGroup').style.display = n > 0 ? 'flex' : 'none';
}
toggleAcc();

// Add event listener for bike name input to update CC when user types
document.getElementById('bikeNameInput').addEventListener('input', function() {
  updateEngineCC();
});

/* ═══════════════════════════════════════════
   BLOCK BROWSER BACK BUTTON (Chrome & all)
   Pushes a phantom history state so pressing
   back stays on this page instead of leaving.
═══════════════════════════════════════════ */
<?php if ($prediction): ?>
(function blockBrowserBack() {
  // Only active on the RESULT page — not the form.
  // Prevents Chrome back from leaving the result UI.
  history.pushState({ bvBlocked: true }, '', location.href);
  window.addEventListener('popstate', function() {
    history.pushState({ bvBlocked: true }, '', location.href);
  });
})();
<?php endif; ?>

/* ═══════════════════════════════════════════
   EDIT MODE — PRE-FILL brand + bike name
═══════════════════════════════════════════ */
<?php if (!empty($pBrand)): ?>
(function prefill() {
  const savedBrand = <?= json_encode($pBrand) ?>;
  const savedBike  = <?= json_encode($pBikeName) ?>;

  // Set brand
  const bSel = document.getElementById('brandSelect');
  for (let o of bSel.options) {
    if (o.text === savedBrand || o.value === savedBrand) { o.selected = true; break; }
  }
  updateBikeNames();

  // Set bike name in text input
  const bikeInput = document.getElementById('bikeNameInput');
  bikeInput.value = savedBike;
  
  // Set bike name in select if it matches
  const mSel = document.getElementById('bikeNameSelect');
  for (let o of mSel.options) {
    if (o.value === savedBike) { o.selected = true; break; }
  }

  // CC hint
  const ccVal = document.getElementById('engineCC').value;
  if (ccVal && parseInt(ccVal) > 0) {
    const h = document.getElementById('model-hint');
    h.innerHTML = '✓ &nbsp;Restored: <strong>' + ccVal + ' cc</strong>';
    h.style.color = 'var(--v2)';
  }
  
  setTimeout(updateEngineCC, 50);
})();
<?php endif; ?>
</script>
</body>
</html>
