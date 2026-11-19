"""
localization package
====================
Retinal anatomical landmark localization (Optic Disc & Fovea Centralis).
"""

from .localize_landmarks import localize_retinal_landmarks, evaluate_idrid_localization

__all__ = ["localize_retinal_landmarks", "evaluate_idrid_localization"]
