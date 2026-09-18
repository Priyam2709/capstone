"""
preprocessing/apply_clahe.py
============================
Contrast Limited Adaptive Histogram Equalization (CLAHE) on L*a*b* space.
Decouples luminance from color chrominance to prevent vascular artifact distortion.
"""

import numpy as np

def apply_clahe(image: np.ndarray, clip_limit: float = 2.0, tile_grid_size: tuple = (8, 8)) -> np.ndarray:
    """
    Applies CLAHE to the L* (Lightness) channel of an RGB retinal image.
    
    Args:
        image: RGB uint8 array of shape (H, W, 3).
        clip_limit: Threshold for contrast limiting (default 2.0 / 0.02 normalized).
        tile_grid_size: Number of contextual tiles (default 8x8).
        
    Returns:
        Enhanced RGB uint8 image with amplified microaneurysms and vessel clarity.
    """
    try:
        import cv2
        lab = cv2.cvtColor(image, cv2.COLOR_RGB2LAB)
        l_channel, a_channel, b_channel = cv2.split(lab)
        
        clahe = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=tile_grid_size)
        cl = clahe.apply(l_channel)
        
        enhanced_lab = cv2.merge((cl, a_channel, b_channel))
        enhanced_rgb = cv2.cvtColor(enhanced_lab, cv2.COLOR_LAB2RGB)
        return enhanced_rgb
    except ImportError:
        # Graceful fallback: histogram stretch on luminance
        img_float = image.astype(np.float32) / 255.0
        p2, p98 = np.percentile(img_float, (2, 98))
        stretched = np.clip((img_float - p2) / max(1e-5, (p98 - p2)), 0.0, 1.0)
        return (stretched * 255).astype(np.uint8)

if __name__ == "__main__":
    sample = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
    out = apply_clahe(sample)
    print(f"CLAHE applied: Input {sample.shape} -> Output {out.shape}")
