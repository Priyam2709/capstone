"""
reports/export_fhir.py
======================
Ayushman Bharat Digital Mission (ABDM) FHIR R4 JSON Exporter.
Serializes patient diagnostic reports and screening observations
using SNOMED-CT and LOINC clinical ontologies.
"""

import json
from datetime import datetime, timezone
from typing import Dict, Any

def export_abdm_fhir_json(patient_id: str,
                          prediction_result: Dict[str, Any],
                          output_filepath: str = None) -> Dict[str, Any]:
    """
    Constructs an ABDM FHIR R4 compliant DiagnosticReport Bundle.
    """
    timestamp = datetime.now(timezone.utc).isoformat()
    stage_code = prediction_result.get("stageCode", 0)
    stage_name = prediction_result.get("stageName", "Unknown")
    confidence = prediction_result.get("confidencePercent", 0.0)

    snomed_codes = {
        0: {"code": "23986001", "display": "No diabetic retinopathy"},
        1: {"code": "312991008", "display": "Mild nonproliferative diabetic retinopathy"},
        2: {"code": "312992001", "display": "Moderate nonproliferative diabetic retinopathy"},
        3: {"code": "312993006", "display": "Severe nonproliferative diabetic retinopathy"},
        4: {"code": "422034002", "display": "Proliferative diabetic retinopathy"}
    }

    snomed_entry = snomed_codes.get(stage_code, {"code": "4855003", "display": "Diabetic retinopathy"})

    bundle = {
        "resourceType": "Bundle",
        "type": "collection",
        "timestamp": timestamp,
        "entry": [
            {
                "fullUrl": f"urn:uuid:diagnosticreport-{patient_id}",
                "resource": {
                    "resourceType": "DiagnosticReport",
                    "id": f"dr-report-{patient_id}",
                    "status": "final",
                    "category": [
                        {
                            "coding": [
                                {
                                    "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                                    "code": "OPH",
                                    "display": "Ophthalmology"
                                }
                            ]
                        }
                    ],
                    "code": {
                        "coding": [
                            {
                                "system": "http://loinc.org",
                                "code": "59282-4",
                                "display": "Automated retinal fundus screening study"
                            }
                        ]
                    },
                    "subject": {"reference": f"Patient/{patient_id}"},
                    "effectiveDateTime": timestamp,
                    "conclusion": f"{stage_name} (Confidence: {confidence}%)",
                    "conclusionCode": [
                        {
                            "coding": [
                                {
                                    "system": "http://snomed.info/sct",
                                    "code": snomed_entry["code"],
                                    "display": snomed_entry["display"]
                                }
                            ]
                        }
                    ]
                }
            }
        ]
    }

    if output_filepath:
        with open(output_filepath, "w", encoding="utf-8") as f:
            json.dump(bundle, f, indent=2)

    return bundle

if __name__ == "__main__":
    mock_pred = {"stageCode": 2, "stageName": "2 - Moderate NPDR", "confidencePercent": 81.3}
    out = export_abdm_fhir_json("PAT-2026-0042", mock_pred)
    print("ABDM FHIR R4 JSON generated successfully:")
    print(json.dumps(out, indent=2)[:400] + "...\n")
