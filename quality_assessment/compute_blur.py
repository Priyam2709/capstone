"""
quality_assessment/compute_blur.py
==================================
Modified Laplacian Variance Focus Estimator.
Quantifies retinal edge crispness to intercept defocus blur.
"""

import numpy as np

def compute_blur(image: np.ndarray) -> float:
    """
    Calculates the Modified Laplacian Variance across the green/grayscale channel.
    Higher values indicate sharp, in-focus captures. Score < 0.35 flags defocus.
    """
    try:
        import cv2
        if image.ndim == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)
        else:
            gray = image
        lap = cv2.Laplacian(gray, cv2.CV_64F)
        var = float(lap.var())
        # Normalized score into [0, 1]
        score = float(min(1.0, var / 500.0))
        return round(score, 4)
    except ImportError:
        # NumPy gradient fallback
        gx, gy = np.gradient(image[:, :, 1] if image.ndim == 3 else image)
        grad_var = float(np.var(gx) + np.var(gy))
        return round(min(1.0, grad_var / 300.0), 4)

if __name__ == "__main__":
    test_img = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
    print("Blur score:", compute_blur(test_img))
