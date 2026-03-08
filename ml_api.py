"""
ml_api.py  —  BikeValue ML Bridge
======================================
MATCHES YOUR EXACT TRAINED MODEL:
  Features: bike_name, kms_driven, owner, age, city,
            engine_capacity, accident_count, brand, accident_history

Run in VS Code terminal:
  pip install flask flask-cors joblib scikit-learn pandas
  python ml_api.py

BEFORE RUNNING: Add these 3 lines at the END of your training script, then run it once:
  import joblib
  joblib.dump(model_price,    'model_price.pkl')
  joblib.dump(model_adjusted, 'model_adjusted.pkl')

Then copy both .pkl files into this same folder.
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import pandas as pd
import numpy as np
import os

app = Flask(__name__)
CORS(app)

BASE = os.path.dirname(__file__)

# Load both models (price = before accident, price_adjusted = after accident)
model_price    = None
model_adjusted = None

price_path    = os.path.join(BASE, 'model_price.pkl')
adjusted_path = os.path.join(BASE, 'model_adjusted.pkl')

if os.path.exists(price_path):
    model_price = joblib.load(price_path)
    print("✅ model_price loaded")
else:
    print(f"⚠  model_price.pkl not found at {price_path}")
    print("   Run your training script with joblib.dump(model_price, 'model_price.pkl') at the end.")

if os.path.exists(adjusted_path):
    model_adjusted = joblib.load(adjusted_path)
    print("✅ model_adjusted loaded")
else:
    print(f"⚠  model_adjusted.pkl not found at {adjusted_path}")


@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'ok',
        'model_price_loaded':    model_price    is not None,
        'model_adjusted_loaded': model_adjusted is not None,
    })


@app.route('/predict', methods=['POST'])
def predict():
    if model_price is None:
        return jsonify({'error': 'model_price.pkl not loaded. See instructions at top of ml_api.py'}), 503

    data = request.get_json()

    accident_count   = float(data.get('accident_count', 0))
    accident_history = data.get('accident_history', 'none').strip().lower()

    # Mirror your training logic: 0 accidents → force history to 'none'
    if accident_count == 0:
        accident_history = 'none'

    # Build DataFrame for BASE PRICE (always with NO accidents)
    # This ensures the base value is consistent regardless of accident input
    base_input_df = pd.DataFrame({
        'bike_name':        [data.get('bike_name', '').strip().lower()],
        'kms_driven':       [float(data.get('kms_driven', 0))],
        'owner':            [float(data.get('owner', 1))],
        'age':              [float(data.get('age', 0))],
        'city':             [data.get('city', '').strip().lower()],
        'engine_capacity':  [float(data.get('engine_capacity', 0))],
        'accident_count':   [0],  # ALWAYS 0 for base price
        'brand':            [data.get('brand', '').strip().lower()],
        'accident_history': ['none'],  # ALWAYS 'none' for base price
    })

    # Build DataFrame for ADJUSTED PRICE (with actual accident values)
    adjusted_input_df = pd.DataFrame({
        'bike_name':        [data.get('bike_name', '').strip().lower()],
        'kms_driven':       [float(data.get('kms_driven', 0))],
        'owner':            [float(data.get('owner', 1))],
        'age':              [float(data.get('age', 0))],
        'city':             [data.get('city', '').strip().lower()],
        'engine_capacity':  [float(data.get('engine_capacity', 0))],
        'accident_count':   [accident_count],  # Actual accident count
        'brand':            [data.get('brand', '').strip().lower()],
        'accident_history': [accident_history],  # Actual accident history
    })

    try:
        # Base price is ALWAYS calculated with no accidents
        predicted_price = float(model_price.predict(base_input_df)[0])
        result = {
            'status':          'success',
            'predicted_price': round(predicted_price, 2),
            'accident_count':  accident_count,
        }

        # Show adjusted (post-accident) price when accidents exist
        if accident_count > 0 and model_adjusted is not None:
            # Use adjusted_input_df with actual accident values
            predicted_adjusted = float(model_adjusted.predict(adjusted_input_df)[0])
            result['predicted_adjusted'] = round(predicted_adjusted, 2)
            result['accident_impact']    = round(predicted_price - predicted_adjusted, 2)

        return jsonify(result)

    except Exception as e:
        return jsonify({'error': str(e)}), 400


if __name__ == '__main__':
    print("\n🏍  BikeValue ML API running at http://localhost/bikevalue/")
    print("   POST /predict  — get price prediction")
    print("   GET  /health   — check model status\n")
    app.run(debug=True, port=5000)




















