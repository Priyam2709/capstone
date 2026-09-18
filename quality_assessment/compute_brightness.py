"""
quality_assessment/compute_brightness.py
======================================
Retinal Illumination & 4-Quadrant Uniformity Analyzer.
"""

import numpy as np

def compute_brightness(image: np.ndarray) -> float:
    """
    Computes normalized mean luminance and quadrant uniformity score.
    Returns composite illumination score in [0, 1].
    Ideal range: mean pixel intensity between 40 and 215.
    """
    if image.ndim == 3:
        gray = np.mean(image, axis=2)
    else:
        gray = image.astype(np.float32)

    mean_val = float(np.mean(gray))
    
    # 4-quadrant balance
    h, w = gray.shape
    q1 = np.mean(gray[:h//2, :w//2])
    q2 = np.mean(gray[:h//2, w//2:])
    q3 = np.mean(gray[h//2:, :w//2])
    q4 = np.mean(gray[h//2:, w//2:])
    
    quadrant_std = float(np.std([q1, q2, q3, q4]))
    uniformity = max(0.0, 1.0 - (quadrant_std / 50.0))
    
    # Luminance penalty for under/over exposure
    if 40 <= mean_val <= 215:
        lum_score = 1.0
    else:
        lum_score = max(0.0, 1.0 - abs(mean_val - 128) / 128.0)
        
    composite = 0.6 * lum_score + 0.4 * uniformity
    return round(float(composite), 4)

if __name__ == "__main__":
    test_img = np.full((224, 224, 3), 120, dtype=np.uint8)
    print("Brightness score:", compute_brightness(test_img))
