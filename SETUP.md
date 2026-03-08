# BikeValue — Complete Setup Guide

## What's Fixed & New
- ✅ **Login bug fixed** — Users can now log in multiple times (was only allowing one login before)
- ✅ **Separate User Login button** added on homepage (was only Admin before)
- ✅ **MySQL database** replaces JSON files — all data stored properly
- ✅ **ML model integration** — your Python model connects via a Flask API
- ✅ **Admin dashboard** shows real data from MySQL

---

## Step 1 — Set Up the Database

1. Open **phpMyAdmin** → `http://localhost/phpmyadmin`
2. Click **Import** tab
3. Upload & run `setup_db.sql`
4. You should see `bikevalue` database created with `users` and `predictions` tables

**Default admin login:**
- Email: `admin@bikevalue.com`
- Password: `password` ← change this! (it's a standard bcrypt hash, update in phpMyAdmin)

---

## Step 2 — Run the PHP Site

1. Copy the whole `bikevalue` folder to: `C:\xampp\htdocs\bikevalue`
2. Start Apache in XAMPP Control Panel
3. Open: `http://localhost/bikevalue/`

---

## Step 3 — Connect Your ML Model

### In VS Code, install dependencies:
```bash
pip install flask flask-cors joblib scikit-learn pandas
```

### Save your trained model:
At the end of your training script, add:
```python
import joblib
joblib.dump(model, 'bike_model.pkl')
```
Then copy `bike_model.pkl` to the `bikevalue` folder (same folder as `ml_api.py`).

### Edit `ml_api.py` (important!):
Open `ml_api.py` and update the `features` array to match your training columns exactly.
The exact column order must match what you used during training.

If your model uses different features, update that section.

### Run the Flask API:
```bash
python ml_api.py
```
You should see: `* Running on http://127.0.0.1:5000`

### Test it:
Open `http://localhost:5000/health` — should show `{"status": "ok", "model_loaded": true}`

When users predict on the website, it will call your model and show the ML price only.

---

## Step 4 — Change Admin Password

1. In phpMyAdmin, open `bikevalue` → `users` table
2. Edit the admin row
3. In the `password` field, paste a new hash from: `https://bcrypt-generator.com/`
4. Or just run in PHP: `echo password_hash('yourNewPassword', PASSWORD_DEFAULT);`

---

## File Structure
```
bikevalue/
├── index.php        ← Landing page (Signup + Login + Admin buttons)
├── auth.php         ← Handles all login/signup/logout
├── predict.php      ← Bike prediction form + result
├── admin.php        ← Admin dashboard
├── config.php       ← Database connection settings
├── setup_db.sql     ← Run this ONCE in phpMyAdmin
├── ml_api.py        ← Flask server for your Python ML model
└── SETUP.md         ← This file
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Database not connected" | Run `setup_db.sql` in phpMyAdmin |
| ML price not showing | Make sure `python ml_api.py` is running |
| Can't log in | Check email/password match exactly what was used at signup |
| Admin login fails | Default: `admin@bikevalue.com` / `password` |
| White page / PHP error | Enable error display: add `ini_set('display_errors',1);` to top of `config.php` |

---

## For Your Teachers — What to Show

1. **Homepage** — three modals: Sign Up, User Login, Admin Login
2. **Predict page** — fill the form → shows ML price (if running)
3. **Admin dashboard** → Users tab (shows all registered users) → Predictions tab (full log of all bike valuations)
4. **MySQL database** → show the `predictions` table in phpMyAdmin with all stored values

**Impressive talking points:**
- Real MySQL database (not flat files)
- Python ML model connected via REST API
- JWT-less but secure session auth with bcrypt passwords
- Separate user and admin authentication flows
