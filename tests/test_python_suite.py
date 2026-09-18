"""
tests/test_python_suite.py
==========================
Comprehensive Automated Test Suite for Python DRISHTI-AI Codebase.
Runs with `python -m unittest tests/test_python_suite.py`.
"""

import unittest
import numpy as np

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
        self.assertIn("Superotemporal", res["primaryQuadrant"])
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

if __name__ == "__main__":
    unittest.main()
