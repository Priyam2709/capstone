# Rural Screening Workflow & Operational Flowchart

**Smart India Hackathon Problem Statement:** SIH26038  
**Operational Context:** Primary Health Centres (PHC), Sub-Centres, and Mobile Eye Screening Camps in Rural India

---

## 1. End-to-End Operational Flowchart

The screening process follows a sequential, fail-safe clinical workflow designed for non-specialist community health workers (ASHA / ANM) with remote ophthalmologist escalation.

```mermaid
flowchart TD
    START([Patient Registration at Rural PHC / Camp]) --> Vitals[Record Age, Gender, Blood Glucose & Vitals]
    Vitals --> Acq[Fundus Camera Image Acquisition\n(Non-mydriatic handheld/tabletop camera)]
    
    Acq --> Load[utils/loadImage.m\nAuto-crop borders, RGB verification, 224x224 resize]
    Load --> IQA{Image Quality Assessment\nqualityAssessment/assessImageQuality.m}
    
    IQA -- "Overall Score < 50\n(Severe Blur / Glare / Dark)" --> RetakeAlert[Audible Alert to Operator\n'Retake Image: Adjust angle & illumination']
    RetakeAlert --> Acq
    
    IQA -- "Score 50-74\n(Needs Enhancement)" --> Preproc[Preprocessing Pipeline\nMedian Filter + Illum Corr + CLAHE]
    IQA -- "Score >= 75\n(Good Quality)" --> Preproc
    
    Preproc --> Infer[Deep Learning Inference\nclassification/predictDR.m\nBackbone: ResNet50 / MobileNetV2]
    
    Infer --> OutputClass[Classification Output:\n- Predicted Stage (0 to 4)\n- Softmax Probabilities\n- Confidence Score]
    
    OutputClass --> XAI[Explainable AI Engine\nexplainability/computeGradCAM.m]
    XAI --> Saliency[Generate Grad-CAM Saliency Heatmap\n+ Microaneurysm/Exudate Overlay\n+ Natural Language Clinical Justification]
    
    Saliency --> TriageDecision{Stage Severity Triage\nThreshold: Stage >= 2}
    
    TriageDecision -- "Stage 0 (No DR) or\nStage 1 (Mild NPDR)" --> NonReferral[Print Community Screening Summary\nSchedule Routine Annual/6-Month Follow-up\nDietary & Glycemic Counseling at PHC]
    
    TriageDecision -- "Stage 2 (Moderate NPDR) or\nStage 3 (Severe NPDR) or\nStage 4 (Proliferative DR)" --> ReferralQueue[Trigger Priority Referral Protocol]
    
    ReferralQueue --> RepGen[Compile Clinical PDF Report\nreports/generatePatientReport.m]
    
    RepGen --> CloudSync{Internet Connectivity\nAvailable at PHC?}
    
    CloudSync -- "Yes (Broadband / 4G)" --> TeleDoc[Upload to District Tele-Ophthalmology Portal\nSpecialist Confirms Diagnosis]
    CloudSync -- "No (Offline Camp)" --> LocalExport[Export Encrypted PDF to USB Flash Drive\nHand Physical Printed Report to Patient]
    
    TeleDoc --> DistrictHosp[District Eye Hospital Referral\nLaser Photocoagulation / Anti-VEGF / Vitrectomy]
    LocalExport --> DistrictHosp
    
    NonReferral --> AuditLog[Append Record to results/logs/audit_trail.json]
    DistrictHosp --> AuditLog
    AuditLog --> Complete([Screening Completed for Patient])
```

---

## 2. Decision Logic & Quality Gateways

### Gateway 1: Image Quality Assessment (IQA) Gate
- Evaluates blur via Laplacian variance, brightness uniformity, RMS contrast, high-frequency noise, and edge sharpness.
- **Fail-Safe Mechanism:** If an image is flagged as `Retake Image` (overall score $< 50$), the system blocks diagnostic inference. This eliminates false-negative errors caused by corneal cataracts or camera motion.

### Gateway 2: Automated Preprocessing & Contrast Equalization
- Rural non-mydriatic cameras often capture dim fundus fields with dark peripheries.
- The **L\*a\*b\* CLAHE** algorithm dynamically redistributes localized luminance without distorting colorimetric markers of retinal hemorrhages.

### Gateway 3: Referral Threshold Gate
- **Stages 0 & 1:** Deemed non-sight-threatening. Patients remain managed at the primary care level, saving tertiary hospitals from overcrowding.
- **Stages 2, 3 & 4:** Deemed sight-threatening diabetic retinopathy (STDR). Automatic triage assigns referral urgency:
  - Moderate NPDR: Non-urgent (within 30 days)
  - Severe NPDR: Priority (within 7–14 days)
  - Proliferative DR: Emergency (within 48 hours)
