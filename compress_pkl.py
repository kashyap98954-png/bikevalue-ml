import joblib
import os

files_to_compress = [
    'model_price.pkl',
    'model_adjusted.pkl',
    'model_price_new.pkl'
]

print("Starting compression...")
for filename in files_to_compress:
    if os.path.exists(filename):
        print(f"Loading {filename}...")
        model = joblib.load(filename)
        
        # Save it with compression level 3 (good balance of speed and size)
        compressed_filename = f"compressed_{filename}"
        print(f"Compressing into {compressed_filename}...")
        joblib.dump(model, compressed_filename, compress=3)
        
        old_size = os.path.getsize(filename) / (1024 * 1024)
        new_size = os.path.getsize(compressed_filename) / (1024 * 1024)
        print(f"Done! Original: {old_size:.2f} MB -> New: {new_size:.2f} MB\n")
        
        # Replace the original file with the compressed one
        os.replace(compressed_filename, filename)
        print(f"Replaced {filename} with the compressed version.\n")
    else:
        print(f"{filename} not found.")

print("All done!")
