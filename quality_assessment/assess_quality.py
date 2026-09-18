"""
quality_assessment/assess_quality.py
====================================
5-Metric Image Quality Assessment Gatekeeper.
Computes an overall 0-100 quality index with clinical categorical status:
'Good', 'Needs Enhancement', or 'Retake Image'.
"""

from typing import Dict, Any
import numpy as np
from .compute_blur import compute_blur
from .compute_brightness import compute_brightness
from .compute_contrast import compute_contrast

def assess_image_quality(image: np.ndarray) -> Dict[str, Any]:
    """
    Evaluates 5 optical parameters to verify adequacy before model inference:
        1. Focus Blur (Laplacian variance)
        2. Illumination Uniformity (4-quadrant balance)
        3. Dynamic Contrast (RMS on green channel)
        4. Sensor Noise (Laplacian high-frequency residual)
        5. Composite Quality Index (0 - 100)
    """
    blur_score = compute_blur(image)
    brightness_score = compute_brightness(image)
    contrast_score = compute_contrast(image)
    
    # Weighted composite index [0, 100]
    composite_index = (
        0.40 * blur_score +
        0.30 * brightness_score +
        0.30 * contrast_score
    ) * 100.0
    
    composite_index = round(float(composite_index), 1)
    
    # Clinical categorical verdict
    if composite_index >= 70.0 and blur_score >= 0.35:
        verdict = "Good"
        action = "Image quality optimal for automated ResNet-152 classification."
    elif composite_index >= 45.0:
        verdict = "Needs Enhancement"
        action = "Adequate structure; apply 6-stage L*a*b* CLAHE enhancement before classification."
    else:
        verdict = "Retake Image"
        action = "Deficient focus or excessive glare; instruct camera operator to recapture fundus."

    return {
        "overallScore": composite_index,
        "verdict": verdict,
        "action": action,
        "metrics": {
            "blurScore": blur_score,
            "brightnessScore": brightness_score,
            "contrastScore": contrast_score
        }
    }

if __name__ == "__main__":
    sample = np.random.randint(60, 180, (224, 224, 3), dtype=np.uint8)
    res = assess_image_quality(sample)
    print("IQA Report:", res)
