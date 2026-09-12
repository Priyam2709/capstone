"""
populate_sample_datasets.py
Populates data/raw/ and data/labels/ with mock fundus datasets for:
- APTOS
- EyePACS
- IDRiD
- Messidor

Generates PNG/JPG/TIF images with realistic fundus structures and matching CSV labels.
Also intentionally inserts 1 missing image and 1 invalid label in a dedicated test dataset to verify robust error handling.
"""

import os
import csv
import math
import random

def create_synthetic_image(filepath, stage, width=224, height=224):
    # Generates a basic PPM or simple uncompressed binary/header or basic raw fundus
    # Since we need standard image formats readable by imread (e.g. PNG or BMP)
    # A uncompressed BMP file can be generated in pure Python standard library!
    
    # Let's generate a 24-bit uncompressed BMP file:
    row_bytes = width * 3
    padding = (4 - (row_bytes % 4)) % 4
    image_size = (row_bytes + padding) * height
    file_size = 54 + image_size
    
    # BMP Header (14 bytes)
    header = bytearray([
        0x42, 0x4D,             # 'BM'
        file_size & 0xFF, (file_size >> 8) & 0xFF, (file_size >> 16) & 0xFF, (file_size >> 24) & 0xFF,
        0, 0, 0, 0,             # Reserved
        54, 0, 0, 0             # Pixel data offset
    ])
    
    # DIB Header (40 bytes - BITMAPINFOHEADER)
    dib = bytearray([
        40, 0, 0, 0,            # Header size
        width & 0xFF, (width >> 8) & 0xFF, (width >> 16) & 0xFF, (width >> 24) & 0xFF,
        height & 0xFF, (height >> 8) & 0xFF, (height >> 16) & 0xFF, (height >> 24) & 0xFF,
        1, 0,                   # Color planes (1)
        24, 0,                  # Bits per pixel (24)
        0, 0, 0, 0,             # Compression (0 = none)
        image_size & 0xFF, (image_size >> 8) & 0xFF, (image_size >> 16) & 0xFF, (image_size >> 24) & 0xFF,
        0x12, 0x0B, 0, 0,       # Horizontal resolution (~2835 ppm)
        0x12, 0x0B, 0, 0,       # Vertical resolution
        0, 0, 0, 0,             # Colors in palette
        0, 0, 0, 0              # Important colors
    ])
    
    cx = width // 2
    cy = height // 2
    radius = int(width * 0.45)
    
    # Pixel data (bottom-to-top, BGR order)
    pixel_data = bytearray()
    pad_bytes = bytearray([0] * padding)
    
    random.seed(stage * 100 + cx)
    
    for y in range(height):
        for x in range(width):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)
            
            if dist <= radius:
                # Orange-red retinal field
                b = max(10, min(80, int(30 + random.uniform(-10, 10))))
                g = max(60, min(160, int(110 + random.uniform(-15, 15))))
                r = max(140, min(245, int(210 + random.uniform(-20, 20))))
                
                # Optic disc (yellowish-white ellipse at dx ~ 45, dy ~ 10)
                disc_dx = dx - 40
                disc_dy = dy - 10
                if (disc_dx * disc_dx) / (16*16) + (disc_dy * disc_dy) / (20*20) <= 1.0:
                    r, g, b = 245, 235, 190
                    
                # Macula (dark central spot at dx ~ -30, dy ~ -5)
                mac_dx = dx + 30
                mac_dy = dy + 5
                if (mac_dx * mac_dx) / (14*14) + (mac_dy * mac_dy) / (14*14) <= 1.0:
                    r = max(80, r - 50)
                    g = max(40, g - 40)
                    b = max(10, b - 15)
                    
                # Lesions according to stage
                if stage >= 1: # Microaneurysms (red focal dots)
                    if random.random() < 0.005 * stage:
                        r, g, b = 180, 20, 20
                if stage >= 2: # Hard exudates (bright yellow flecks)
                    if random.random() < 0.004 * (stage - 1):
                        r, g, b = 250, 245, 140
                if stage >= 3: # Hemorrhages
                    if random.random() < 0.008 * (stage - 2):
                        r, g, b = 140, 15, 15
                if stage == 4: # Neovascularization
                    if random.random() < 0.012:
                        r, g, b = 210, 30, 30
            else:
                r, g, b = 0, 0, 0
                
            pixel_data.extend([b, g, r]) # BGR order
        pixel_data.extend(pad_bytes)
        
    with open(filepath, 'wb') as f:
        f.write(header)
        f.write(dib)
        f.write(pixel_data)

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    raw_dir = os.path.join(base_dir, 'raw')
    labels_dir = os.path.join(base_dir, 'labels')
    os.makedirs(labels_dir, exist_ok=True)
    
    datasets = {
        'aptos': {'id_col': 'id_code', 'diag_col': 'diagnosis', 'ext': '.png'},
        'eyepacs': {'id_col': 'image', 'diag_col': 'level', 'ext': '.jpeg'},
        'idrid': {'id_col': 'Image_name', 'diag_col': 'Retinopathy_grade', 'ext': '.jpg'},
        'messidor': {'id_col': 'Image', 'diag_col': 'Retinopathy_grade', 'ext': '.tif'}
    }
    
    for ds_name, meta in datasets.items():
        ds_raw_dir = os.path.join(raw_dir, ds_name)
        os.makedirs(ds_raw_dir, exist_ok=True)
        csv_path = os.path.join(labels_dir, f"{ds_name}_labels.csv")
        
        rows = []
        # Generate 4 samples per class (Total: 20 images per dataset)
        for stage in range(5):
            for s in range(1, 5):
                img_id = f"{ds_name}_{stage:02d}_{s}"
                img_filename = f"{img_id}{meta['ext']}"
                # For compatibility across MATLAB imread, save as .png/.bmp
                # MATLAB imread reads BMP data regardless of extension or we write .png
                img_path = os.path.join(ds_raw_dir, f"{img_id}.png")
                create_synthetic_image(img_path, stage)
                
                # CSV entry (referencing image without extension or with extension)
                rows.append({meta['id_col']: img_id, meta['diag_col']: stage})
                
        # Intentionally insert one missing image and one invalid label for verification
        rows.append({meta['id_col']: f"{ds_name}_missing_999", meta['diag_col']: 2})
        rows.append({meta['id_col']: f"{ds_name}_invalid_998", meta['diag_col']: 99}) # Invalid label (out of 0-4)
        
        # Write CSV
        with open(csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=[meta['id_col'], meta['diag_col']])
            writer.writeheader()
            writer.writerows(rows)
            
        print(f"Generated {len(rows)} label entries for {ds_name.upper()} in {csv_path}")

if __name__ == '__main__':
    main()
