"""
quality_assessment/compute_contrast.py
======================================
Root-Mean-Square (RMS) Dynamic Range Contrast Estimator on Green Channel.
"""

import numpy as np

def compute_contrast(image: np.ndarray) -> float:
    """
    Computes RMS contrast across the green vascular channel:
        C_RMS = sqrt( (1/N) * sum( (I(x,y) - I_bar)^2 ) )
    Target standard: C_RMS >= 25.
    Returns normalized contrast score in [0, 1].
    """
    if image.ndim == 3:
        green = image[:, :, 1].astype(np.float32)
    else:
        green = image.astype(np.float32)

    rms = float(np.std(green))
    score = min(1.0, rms / 60.0)
    return round(float(score), 4)

if __name__ == "__main__":
    test_img = np.random.randint(50, 200, (224, 224, 3), dtype=np.uint8)
    print("Contrast score:", compute_contrast(test_img))
