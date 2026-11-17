"""
tests/test_python_suite.py
==========================
Comprehensive Automated Test Suite for Python DRISHTI-AI Codebase.
Runs with `python -m unittest tests/test_python_suite.py`.
"""

import unittest
import os
import sys
import numpy as np

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

class TestClassification(unittest.TestCase):
    def test_build_model_spec(self):
        from classification.build_model import build_model
        model = build_model("resnet152", num_classes=5)
        self.assertIsNotNone(model)

    def test_predict_dr_mock(self):
        from classification.predict_dr import predict_dr
        dummy_img = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
        res = predict_dr(dummy_img, architecture="resnet152")
        self.assertEqual(res["status"], "SUCCESS")
        self.assertIn(res["stageCode"], [0, 1, 2, 3, 4])
        self.assertEqual(len(res["classProbabilities"]), 5)
        self.assertGreaterEqual(res["confidencePercent"], 0.0)

    def test_evaluate_metrics(self):
        from classification.evaluate_metrics import evaluate_metrics, compute_quadratic_weighted_kappa
        y_true = [0, 1, 2, 3, 4]
        y_pred = [0, 1, 2, 3, 4]
        kappa = compute_quadratic_weighted_kappa(y_true, y_pred)
        self.assertAlmostEqual(kappa, 1.0, places=3)
        metrics = evaluate_metrics(y_true, y_pred)
        self.assertEqual(metrics["accuracy"], 1.0)
        self.assertEqual(metrics["referableSensitivity"], 1.0)

class TestPreprocessing(unittest.TestCase):
    def test_clahe(self):
        from preprocessing.apply_clahe import apply_clahe
        img = np.random.randint(0, 255, (100, 100, 3), dtype=np.uint8)
        out = apply_clahe(img)
        self.assertEqual(out.shape, img.shape)

    def test_illumination_correction(self):
        from preprocessing.correct_illumination import correct_illumination
        img = np.random.randint(0, 255, (100, 100, 3), dtype=np.uint8)
        out = correct_illumination(img, disk_radius=10)
        self.assertEqual(out.shape, img.shape)

    def test_pipeline(self):
        from preprocessing.preprocess_pipeline import preprocess_pipeline
        img = np.random.randint(0, 255, (150, 150, 3), dtype=np.uint8)
        res = preprocess_pipeline(img, target_size=(224, 224))
        self.assertEqual(res["status"], "SUCCESS")
        self.assertGreater(res["psnrDb"], 20.0)

class TestQualityAssessment(unittest.TestCase):
    def test_blur_estimator(self):
        from quality_assessment.compute_blur import compute_blur
        img = np.random.randint(0, 255, (100, 100, 3), dtype=np.uint8)
        score = compute_blur(img)
        self.assertTrue(0.0 <= score <= 1.0)

    def test_brightness_estimator(self):
        from quality_assessment.compute_brightness import compute_brightness
        img = np.full((100, 100, 3), 120, dtype=np.uint8)
        score = compute_brightness(img)
        self.assertTrue(0.0 <= score <= 1.0)

    def test_composite_iqa(self):
        from quality_assessment.assess_quality import assess_image_quality
        img = np.random.randint(40, 200, (100, 100, 3), dtype=np.uint8)
        res = assess_image_quality(img)
        self.assertIn(res["verdict"], ["Good", "Needs Enhancement", "Retake Image"])
        self.assertTrue(0.0 <= res["overallScore"] <= 100.0)

class TestExplainability(unittest.TestCase):
    def test_gradcam(self):
        from explainability.grad_cam import compute_gradcam
        img = np.random.randint(0, 255, (224, 224, 3), dtype=np.uint8)
        res = compute_gradcam(img, target_class=2)
        self.assertTrue(any(q in res["primaryQuadrant"] for q in ["Temporal", "Superotemporal", "Nasal"]))
        self.assertGreater(res["lesionCount"], 0)

class TestReportsAndSimulation(unittest.TestCase):
    def test_abdm_fhir_export(self):
        from reports.export_fhir import export_abdm_fhir_json
        pred = {"stageCode": 2, "stageName": "2 - Moderate NPDR", "confidencePercent": 81.3}
        bundle = export_abdm_fhir_json("PAT-001", pred)
        self.assertEqual(bundle["resourceType"], "Bundle")
        self.assertEqual(len(bundle["entry"]), 1)

    def test_camp_simulation(self):
        from simulation.camp_queue_simulation import simulate_camp_throughput
        res1 = simulate_camp_throughput(120, num_cameras=1)
        res2 = simulate_camp_throughput(120, num_cameras=2)
        self.assertGreater(res1["averageWaitTimeMinutes"], res2["averageWaitTimeMinutes"])
        self.assertGreater(res2["estimatedDailyCapacity"], res1["estimatedDailyCapacity"])

class TestIDRiDDataset(unittest.TestCase):
    def test_idrid_annotations_loading(self):
        from data.idrid_dataset import load_idrid_annotations, DEFAULT_TRAIN_CSV
        items = load_idrid_annotations(DEFAULT_TRAIN_CSV)
        self.assertGreaterEqual(len(items), 400)
        self.assertIn("retinopathy_grade", items[0])
        self.assertIn(items[0]["retinopathy_grade"], [0, 1, 2, 3, 4])

    def test_idrid_class_weights(self):
        from data.idrid_dataset import calculate_class_weights, load_idrid_annotations, DEFAULT_TRAIN_CSV
        items = load_idrid_annotations(DEFAULT_TRAIN_CSV)
        weights = calculate_class_weights(items, num_classes=5)
        self.assertEqual(len(weights), 5)
        for w in weights:
            self.assertGreater(w, 0.0)

    def test_idrid_sample_query(self):
        from data.idrid_dataset import get_real_sample
        sample = get_real_sample(grade=3)
        self.assertIsNotNone(sample)
        self.assertEqual(sample["retinopathy_grade"], 3)
        self.assertTrue(os.path.exists(sample["image_path"]))

    def test_idrid_segmentation_loading(self):
        from data.idrid_dataset import load_idrid_segmentation_annotations, DEFAULT_SEG_TRAIN_CSV
        items = load_idrid_segmentation_annotations(DEFAULT_SEG_TRAIN_CSV)
        self.assertEqual(len(items), 54)
        self.assertIn("masks", items[0])
        self.assertIn("ma_mask", items[0]["masks"])

    def test_idrid_localization_loading(self):
        from data.idrid_dataset import load_idrid_localization_annotations, DEFAULT_FOV_TRAIN_CSV, DEFAULT_OD_TRAIN_CSV
        items = load_idrid_localization_annotations(DEFAULT_FOV_TRAIN_CSV, DEFAULT_OD_TRAIN_CSV)
        self.assertEqual(len(items), 413)
        self.assertIn("fovea_xy", items[0])
        self.assertIn("optic_disc_xy", items[0])
        self.assertGreater(items[0]["fovea_xy"][0], 0.0)

    def test_idrid_dataset_factory(self):
        from data.idrid_dataset import get_idrid_dataset
        ds_grading = get_idrid_dataset("disease_grading", split="train")
        self.assertEqual(len(ds_grading), 413)
        ds_seg = get_idrid_dataset("segmentation", split="train")
        self.assertEqual(len(ds_seg), 54)
        ds_loc = get_idrid_dataset("localization", split="train")
        self.assertEqual(len(ds_loc), 413)

if __name__ == "__main__":
    unittest.main()
