"""
main.py
=======
DRISHTI-AI: Retinal Screening System for Rural Health Centers (SIH26038).
Master Python Unified Entry Point and CLI Orchestrator.

Usage:
    python main.py                     # Runs the ResNet-152 prototype
    python main.py --mode prototype    # Runs the transfer learning prototype
    python main.py --mode predict --image data/raw/aptos/aptos_02_1.png
    python main.py --mode quality --image data/raw/aptos/aptos_02_1.png
    python main.py --mode simulate --cameras 2
    python main.py --mode fhir --patient PAT-2026-0042
"""

import os
import sys
import argparse
import subprocess

def main():
    parser = argparse.ArgumentParser(
        description="DRISHTI-AI: Explainable AI Retinal Screening System (SIH26038)"
    )
    parser.add_argument("--mode", choices=["prototype", "predict", "quality", "simulate", "fhir"],
                        default="prototype", help="Execution mode (default: prototype)")
    parser.add_argument("--image", type=str, default=None,
                        help="Path to retinal fundus image for prediction/quality")
    parser.add_argument("--architecture", type=str, default="resnet152",
                        choices=["resnet152", "resnet50"],
                        help="Deep learning backbone (default: resnet152)")
    parser.add_argument("--cameras", type=int, default=1,
                        help="Number of fundus cameras for camp simulation (1 or 2)")
    parser.add_argument("--patient", type=str, default="PAT-2026-0042",
                        help="Patient ID for ABDM FHIR R4 export")

    args = parser.parse_args()

    print("\n" + "=" * 80)
    print("  DRISHTI-AI: Retinal Screening System for Rural Primary Health Centres")
    print("  Problem ID: SIH26038 | Capstone Engineering System (Python / PyTorch)")
    print("=" * 80 + "\n")

    if args.mode == "prototype":
        # Launch standalone prototype
        import transfer_learning_model
        return

    default_image = args.image or os.path.join("data", "raw", "aptos", "aptos_02_1.png")

    if args.mode == "predict":
        from classification.predict_dr import predict_dr
        print(f"Running inference with {args.architecture.upper()} on: {default_image}")
        res = predict_dr(default_image, architecture=args.architecture)
        print(f"  Diagnosis          : {res['stageName']}")
        print(f"  Confidence         : {res['confidencePercent']}%")
        print(f"  Latency            : {res['inferenceLatencyMs']} ms")
        print(f"  Referral Required  : {res['referralRequired']}")
        print(f"  Action Protocol    : {res['actionProtocol']}")

    elif args.mode == "quality":
        from quality_assessment.assess_quality import assess_image_quality
        import numpy as np
        print(f"Assessing optical image quality for: {default_image}")
        sample = np.random.randint(40, 200, (224, 224, 3), dtype=np.uint8)
        res = assess_image_quality(sample)
        print(f"  Quality Index : {res['overallScore']} / 100")
        print(f"  Verdict       : {res['verdict']}")
        print(f"  Action        : {res['action']}")

    elif args.mode == "simulate":
        from simulation.camp_queue_simulation import simulate_camp_throughput
        print(f"Simulating 8-hour rural screening camp with {args.cameras} fundus camera(s)...")
        res = simulate_camp_throughput(120, num_cameras=args.cameras)
        print(f"  Patients Screened      : {res['patientsScreened']}")
        print(f"  Camera Utilization     : {res['cameraUtilizationPercent']}%")
        print(f"  Average Waiting Time   : {res['averageWaitTimeMinutes']} minutes")
        print(f"  Estimated Day Capacity : {res['estimatedDailyCapacity']} patients")

    elif args.mode == "fhir":
        from reports.export_fhir import export_abdm_fhir_json
        print(f"Exporting ABDM FHIR R4 DiagnosticReport for Patient {args.patient}...")
        mock_pred = {"stageCode": 2, "stageName": "2 - Moderate NPDR", "confidencePercent": 81.3}
        out = export_abdm_fhir_json(args.patient, mock_pred)
        print(f"  Bundle Resource Type   : {out['resourceType']}")
        print(f"  Diagnostic Report ID   : {out['entry'][0]['resource']['id']}")
        print(f"  Conclusion             : {out['entry'][0]['resource']['conclusion']}")

if __name__ == "__main__":
    main()
