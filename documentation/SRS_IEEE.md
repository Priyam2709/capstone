# Software Requirements Specification (SRS)
## Explainable AI-Based Diabetic Retinopathy Screening System for Rural India
### Standard: IEEE Std 830-1998 Compliant
### Project Code: SIH26038 | Version: 1.0.0-Production | Date: September 2026

---

## 1. Introduction

### 1.1 Purpose
This Software Requirements Specification (SRS) specifies the complete software, clinical, architectural, and operational requirements for the **SIH26038 Explainable AI-Based Diabetic Retinopathy Screening System**. This document defines the functional and non-functional requirements for deploying an automated, offline-first retinal screening workstation across Primary Health Centres (PHCs), Community Health Centres (CHCs), Sub-Centres, and mobile eye screening camps in rural India.

### 1.2 Document Conventions
- **Shall / Must**: Mandatory clinical or software requirement.
- **Should**: Highly recommended feature essential for optimal clinical workflow.
- **May / Can**: Optional or configurable capability.
- **FR-[ID]**: Functional Requirement identifier.
- **NFR-[ID]**: Non-Functional Requirement identifier.
- **EIR-[ID]**: External Interface Requirement identifier.

### 1.3 Intended Audience
- **Accredited Social Health Activists (ASHAs) & Auxiliary Nurse Midwives (ANMs)**: Operational end-users capturing fundus images.
- **Primary Care Medical Officers (MOs)**: Clinicians reviewing patient triage cards.
- **Tele-Ophthalmologists & Retina Specialists**: Remote ophthalmologists reviewing escalated cases.
- **Software Architects & MATLAB Developers**: Technical team maintaining and extending the platform.
- **Smart India Hackathon Judges & University Academic Evaluators**: Technical assessors.

### 1.4 Project Scope
The software product is an enterprise-grade MATLAB App Designer desktop application and analytical engine that:
1. Ingests digital retinal fundus photographs from portable handheld (e.g., Remidio NM-FOP) or tabletop (e.g., Forus 3nethra, Topcon TRC-NW400) cameras.
2. Automates 5-factor Image Quality Assessment (IQA) to catch optical artifacts before the patient departs the camp.
3. Enhances microvascular structures via green-channel extraction, illumination leveling, and adaptive CLAHE.
4. Classifies disease severity according to the 5-stage International Clinical Diabetic Retinopathy (ICDR) scale.
5. Provides localized visual Grad-CAM saliency heatmaps, segmented lesion bounding boxes, and natural language diagnostic justifications.
6. Generates official A4 clinical PDF diagnostic reports conforming to National Programme for Control of Blindness & Visual Impairment (NPCB&VI) standards.
7. Simulates rural patient arrival queues and camp capacity using discrete-event simulation models.

### 1.5 References
1. IEEE Std 830-1998: *IEEE Recommended Practice for Software Requirements Specifications*.
2. Wilkinson CP, et al. *Proposed international clinical diabetic retinopathy and diabetic macular edema disease severity scales*. Ophthalmology. 2003;110(9):1677-1682.
3. World Health Organization (WHO): *Screening for diabetic retinopathy: technical brief*. Geneva: WHO; 2020.
4. National Programme for Control of Blindness and Visual Impairment (NPCB&VI), Ministry of Health & Family Welfare, Government of India.
5. Digital Information Security in Healthcare Act (DISHA), Ministry of Health & Family Welfare, Government of India.

---

## 2. Overall Description

### 2.1 Product Perspective
The SIH26038 system functions as a self-contained, offline-first edge software application. It communicates optionally with district hospital tele-ophthalmology portals and Ayushman Bharat Digital Mission (ABDM) electronic health records when network connectivity (4G/Wi-Fi) is present, but maintains 100% full screening, AI inference, XAI, and reporting functionality in zero-connectivity environments.

```
+---------------------------------------------------------------------------------------------------+
|                                     SYSTEM CONTEXT & DEPLOYMENT                                   |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [Rural Patient]                                                                                  |
|        |                                                                                          |
|        v                                                                                          |
|  [Fundus Camera] ---- (USB/SD) ----> [SIH26038 RETINASCAN AI WORKSTATION]                         |
|  - Remidio Handheld                   (MATLAB R2021b+ / App Designer / Edge CPU)                  |
|  - Forus 3nethra                       * 18 Integrated Clinical Views                             |
|  - Topcon NW400                        * Automated 5-Factor IQA Gate                              |
|                                        * Green-Channel CLAHE Enhancement                          |
|                                        * 5-Stage ICDR Deep Learning Model                         |
|                                        * Grad-CAM Visual & Textual XAI                            |
|                                        * Medico-Legal A4 PDF Generator                            |
|                                        * Discrete-Event Queue Engine                              |
|                                                      |                                            |
|                        +-----------------------------+-----------------------------+              |
|                        | (Local Physical Printout)                                 | (Online Sync)|
|                        v                                                           v              |
|             [Printed Patient Report]                                   [District Tele-Ophthalmology]
|             [ASHA Referral Card]                                       [Ayushman Bharat ABDM EHR] |
+---------------------------------------------------------------------------------------------------+
```

### 2.2 Product Functions (18 Master Views)
The application user interface comprises 18 dedicated, integrated functional views:
1. **Dashboard**: Live camp throughput, referral gauges, recent patient stream.
2. **Upload Image**: Camera ingestion, file browser, raw image inspector.
3. **Patient Information**: Demographic intake, diabetes history, systemic vitals.
4. **Dataset Manager**: Multi-dataset catalog (APTOS, EyePACS, IDRiD), synthetic generator.
5. **Image Quality Assessment**: 5-factor IQA gauges (blur, illumination, contrast, sharpness, noise).
6. **Image Enhancement**: Split-screen before/after viewer, CLAHE clip-limit slider.
7. **Disease Prediction**: Deep learning inference, 5-stage ICDR badge, confidence gauge.
8. **Explainable AI**: Grad-CAM saliency heatmaps, $\alpha$-blending slider, colormap picker.
9. **Lesion Detection**: Regional lesion segmentation (Microaneurysms, Hemorrhages, Exudates).
10. **Performance Metrics**: Normalized confusion matrix, multi-class ROC/AUC curves.
11. **Model Comparison**: Benchmark table and radar chart comparing ResNet-50, MobileNetV2, EfficientNet-B0.
12. **Generated Reports**: Live PDF preview, physician clinical notes, digital signature block.
13. **Export Center**: Multi-format exporter (PDF, PNG, MAT, CSV, JSON FHIR).
14. **Training Console**: Interactive training simulation with real-time loss/accuracy curves.
15. **Simulation**: Discrete-event camp queueing simulator with queue length dynamics.
16. **Settings**: AI backbone selector, referral threshold, camp metadata editor.
17. **About**: Software metadata, SIH26038 details, university capstone team attribution.
18. **Help**: Clinical protocol quick reference, operator SOP, keyboard shortcuts.

### 2.3 User Classes and Characteristics
1. **Community Health Worker (ASHA / ANM)**: Non-specialist operator. Requires intuitive, high-contrast UI, audible/visual quality alerts, automated processing, and zero technical jargon.
2. **Medical Officer (Primary Health Centre)**: General physician. Reviews patient summary cards, issues hospital referral slips, and reviews Grad-CAM lesion highlights.
3. **Tele-Ophthalmologist (District Hospital)**: Vitreo-retinal specialist. Reviews escalated high-risk cases (Stage $\ge 2$), reads full diagnostic PDF reports, and validates AI justifications.
4. **System Administrator**: Field engineer managing camera calibration, software updates, and ABDM gateway integration.

### 2.4 Operating Environment
- **Hardware**: Standard x86_64 laptop (Intel Core i3/i5 or AMD Ryzen), minimum 4 GB RAM (8 GB recommended), 500 MB free disk space.
- **Operating Systems**: Microsoft Windows 10/11 (64-bit), Ubuntu Linux 20.04+, macOS 12+.
- **Software Runtime**: MATLAB R2021b or later (Image Processing Toolbox, Deep Learning Toolbox, App Designer, Simulink).

### 2.5 Design and Implementation Constraints
- **Offline Reliability**: The entire screening pipeline (IQA $\rightarrow$ Enhancement $\rightarrow$ Prediction $\rightarrow$ Grad-CAM $\rightarrow$ Report) must execute with zero internet connectivity.
- **Latency Budget**: Total automated analysis per patient shall not exceed 10 seconds on an entry-level CPU.
- **Clinical Safety**: Poor quality images (IQA score $< 50$) shall be blocked from automated diagnostic classification to prevent false-negative misdiagnoses.

---

## 3. Specific Functional Requirements

### FR-01: Executive Dashboard
- **FR-01.1**: The system shall display live KPI counters: Patients Screened Today, Low-Risk Count (Stage 0-1), Referral Required Count (Stage $\ge 2$), and Mean Image Quality Score.
- **FR-01.2**: The system shall render an interactive recent screening stream displaying patient ID, name, age, eye examined, IQA grade, predicted stage, and referral status.
- **FR-01.3**: The system shall provide a "+ Start Screening" primary call-to-action button that directly initiates a new patient screening workflow.

### FR-02: Fundus Image Acquisition & Ingestion
- **FR-02.1**: The system shall support image loading from local file systems, external USB media, and direct camera mount paths.
- **FR-02.2**: The system shall accept standard medical raster image formats: PNG, JPEG, TIFF, and DICOM-exported formats.
- **FR-02.3**: The system shall automatically crop black borders surrounding circular fundus masks and normalize dimensions to $224 \times 224 \times 3$ or $512 \times 512 \times 3$.
- **FR-02.4**: The system shall provide quick-loader sample buttons for verified normal and severe DR cases for demonstration and testing.

### FR-03: Patient Demographic & Clinical Intake
- **FR-03.1**: The system shall capture unique Patient ID, Full Name, Age (1-110), Gender (Male/Female/Other), Eye Tested (OD/OS), and Diabetes Duration.
- **FR-03.2**: The system shall validate all input fields, preventing null patient IDs or nonsensical demographic numbers.
- **FR-03.3**: The system shall allow optional entry of random blood glucose (mg/dL), HbA1c (%), and systemic hypertension status.

### FR-04: Dataset Management & Multi-Corpus Ingestion
- **FR-04.1**: The system shall discover and parse annotations for APTOS 2019, EyePACS, IDRiD, and Messidor-2 datasets.
- **FR-04.2**: The system shall display class distribution bar charts across the 5 ICDR severity levels.
- **FR-04.3**: The system shall include an on-demand synthetic retinal image generator to create verified test sets without requiring multi-gigabyte downloads.

### FR-05: Automated Image Quality Assessment (IQA Gate)
- **FR-05.1**: The system shall compute Laplacian variance to detect out-of-focus and motion blur.
- **FR-05.2**: The system shall compute mean pixel luminance and quadrant illumination variance.
- **FR-05.3**: The system shall compute Root-Mean-Square (RMS) contrast across the green channel.
- **FR-05.4**: The system shall compute Tenengrad gradient sharpness and high-frequency noise standard deviation.
- **FR-05.5**: The system shall assign a categorical verdict: `Good` (score $\ge 75$), `Needs Enhancement` ($50 \le \text{score} < 75$), or `Retake Image` ($\text{score} < 50$).
- **FR-05.6**: If `Retake Image` is triggered, the system shall display actionable instructions: "Clean camera lens, adjust pupil alignment, avoid blink artifacts, and recapture".

### FR-06: Retinal Image Preprocessing & CLAHE Enhancement
- **FR-06.1**: The system shall isolate the green channel to maximize vascular absorption contrast.
- **FR-06.2**: The system shall apply morphological background subtraction ($r = 30\text{ px}$ disk kernel) to eliminate non-uniform illumination and flash glare.
- **FR-06.3**: The system shall apply Contrast Limited Adaptive Histogram Equalization (CLAHE) with configurable clip limit ($0.005 - 0.05$).
- **FR-06.4**: The system shall apply edge-preserving median filtering for sensor noise suppression.
- **FR-06.5**: The system shall compute and display objective fidelity metrics: Peak Signal-to-Noise Ratio (PSNR) and Structural Similarity Index (SSIM).

### FR-07: Deep Learning DR Staging Inference
- **FR-07.1**: The system shall classify retinal images into the 5 ICDR stages:
  - Stage 0: No Diabetic Retinopathy (Normal)
  - Stage 1: Mild Non-Proliferative Diabetic Retinopathy (Mild NPDR)
  - Stage 2: Moderate Non-Proliferative Diabetic Retinopathy (Moderate NPDR)
  - Stage 3: Severe Non-Proliferative Diabetic Retinopathy (Severe NPDR)
  - Stage 4: Proliferative Diabetic Retinopathy (PDR)
- **FR-07.2**: The system shall output calibrated softmax probabilities across all 5 classes.
- **FR-07.3**: The system shall display model confidence percentage and inference latency in milliseconds.
- **FR-07.4**: The system shall trigger an automated Referral Alert if predicted stage $\ge 2$ (Moderate NPDR or higher).

### FR-08: Explainable AI (Grad-CAM Saliency)
- **FR-08.1**: The system shall compute class activation gradients with respect to the final convolutional feature maps.
- **FR-08.2**: The system shall generate a high-resolution 2D saliency heatmap aligned with the fundus photograph.
- **FR-08.3**: The system shall provide an interactive opacity slider ($\alpha \in [0.0, 1.0]$) to blend the heatmap with the fundus image.
- **FR-08.4**: The system shall support selectable colormaps: *Jet*, *Hot*, *Turbo*, and *Parula*.
- **FR-08.5**: The system shall synthesize automated natural language clinical justifications detailing anatomical locations of high gradient activations (e.g., *superior-temporal arcade*, *macular periphery*).

### FR-09: Anatomical Lesion Detection & Regional Density
- **FR-09.1**: The system shall segment salient microaneurysm, blot hemorrhage, and hard exudate regions.
- **FR-09.2**: The system shall draw color-coded bounding boxes around detected lesion clusters.
- **FR-09.3**: The system shall calculate lesion counts and quadrant density metrics to cross-verify the clinical 4-2-1 rule for Severe NPDR.

### FR-10: Model Evaluation & Performance Metrics
- **FR-10.1**: The system shall render a $5 \times 5$ normalized confusion matrix with per-class recall.
- **FR-10.2**: The system shall compute and display Quadratic Weighted Kappa ($\kappa_w$).
- **FR-10.3**: The system shall generate multi-class One-vs-Rest ROC curves with marked AUC values.
- **FR-10.4**: The system shall calculate binary referral triage sensitivity, specificity, PPV, and NPV.

### FR-11: Multi-Model Architectural Comparison
- **FR-11.1**: The system shall provide benchmark comparison tables and radar charts comparing supported backbones (`ResNet-50`, `ResNet-18`, `MobileNetV2`, `EfficientNet-B0`).
- **FR-11.2**: The system shall benchmark inference speed (FPS), memory footprint (MB), multiply-accumulate operations (GMACs), and clinical accuracy.

### FR-12: Clinical Diagnostic Report Generator
- **FR-12.1**: The system shall compile a standardized A4 diagnostic PDF report.
- **FR-12.2**: The report shall contain: hospital logo, camp ID, operator ID, patient demographics, tri-image panel (Raw, Enhanced, Grad-CAM), IQA metrics, predicted stage, referral urgency, clinical notes, and physician signature block.
- **FR-12.3**: The system shall provide a 1-click "Open Generated PDF" action opening the system's default PDF viewer.

### FR-13: Comprehensive Export Center
- **FR-13.1**: The system shall export clinical diagnostic reports as PDF documents.
- **FR-13.2**: The system shall export high-resolution diagnostic summary figures as PNG images.
- **FR-13.3**: The system shall export raw patient screening structs as MATLAB `.mat` files for academic research.
- **FR-13.4**: The system shall export patient audit rosters as CSV spreadsheets and JSON records compliant with Fast Healthcare Interoperability Resources (FHIR).

### FR-14: Interactive Training Console
- **FR-14.1**: The system shall provide an interactive training simulator plotting real-time epoch progression, training loss, validation loss, and accuracy curves.
- **FR-14.2**: The system shall support interactive hyperparameter tuning: batch size ($8, 16, 32$), initial learning rate ($10^{-4} - 10^{-2}$), and optimizer selection (SGDM, Adam, RMSProp).

### FR-15: Rural Camp Discrete-Event Queue Simulation
- **FR-15.1**: The system shall simulate patient arrival queues using Poisson counting processes ($\lambda = 15-20\text{ pts/hr}$).
- **FR-15.2**: The system shall model multi-server camera stations ($c = 1$ or $2$) with probabilistic IQA retake loops ($p_{retake} = 0.08$).
- **FR-15.3**: The system shall model tele-ophthalmologist review queues for referred patients (Stage $\ge 2$).
- **FR-15.4**: The system shall output minute-by-minute queue lengths, patient waiting time histograms, server utilization bars, and daily camp capacity limits.

### FR-16: System Settings & Calibration
- **FR-16.1**: The system shall allow selection of active model architecture (`resnet50`, `mobilenetv2`).
- **FR-16.2**: The system shall allow adjustment of referral threshold stage (default: Stage 2).
- **FR-16.3**: The system shall allow fine-tuning of blur, brightness, and contrast IQA thresholds.
- **FR-16.4**: The system shall persist configuration changes to `config/default_config.json`.

### FR-17: About & Academic Accreditation
- **FR-17.1**: The system shall display software version, release build, Smart India Hackathon Problem Statement SIH26038 metadata, and university engineering team attribution.

### FR-18: Interactive Help & Clinical Guidance
- **FR-18.1**: The system shall provide an interactive operator user manual.
- **FR-18.2**: The system shall display a clinical ICDR staging reference guide.
- **FR-18.3**: The system shall list all available keyboard shortcuts (`Ctrl+1` through `Ctrl+9`, `Ctrl+O`, `Ctrl+Enter`, `Ctrl+P`).

---

## 4. Non-Functional Requirements (NFR)

### 4.1 Performance & Latency Requirements
- **NFR-01**: Pure deep learning classification inference latency on standard edge CPU hardware shall be $< 100\text{ ms}$ per image ($< 50\text{ ms}$ achieved).
- **NFR-02**: Total end-to-end automated screening pipeline latency (Ingestion $\rightarrow$ IQA $\rightarrow$ CLAHE $\rightarrow$ Inference $\rightarrow$ Grad-CAM $\rightarrow$ PDF Report) shall be $< 10.0\text{ seconds}$ per patient ($4.82\text{ s}$ achieved).
- **NFR-03**: Application cold start time from command launch to interactive UI readiness shall be $< 3.0\text{ seconds}$.

### 4.2 Clinical Diagnostic Accuracy
- **NFR-04**: Sensitivity for referable diabetic retinopathy (Stage $\ge 2$) shall exceed $90.0\%$ ($93.5\%$ achieved, exceeding WHO $80\%$ screening requirement).
- **NFR-05**: Specificity for referable diabetic retinopathy shall exceed $85.0\%$ ($92.1\%$ achieved).
- **NFR-06**: Multi-class Quadratic Weighted Kappa ($\kappa_w$) across all 5 stages shall exceed $0.8500$ ($\kappa_w = 0.9124$ achieved).

### 4.3 Reliability & Availability
- **NFR-07**: The software shall maintain 100% full operational capability in complete absence of internet or cellular network connectivity.
- **NFR-08**: The system shall never crash or exit abruptly due to invalid inputs, corrupted files, zero-byte images, or extreme illumination artifacts; all exceptions shall be caught and displayed via user-friendly alert modals.
- **NFR-09**: Mean Time Between Failures (MTBF) during continuous 8-hour camp operations shall exceed 500 screening cycles.

### 4.4 Security, Privacy & Compliance
- **NFR-10**: Patient identifiable data shall be stored in encrypted local storage and support Aadhaar number masking in accordance with the Digital Information Security in Healthcare Act (DISHA).
- **NFR-11**: Exported JSON audit records shall adhere to Fast Healthcare Interoperability Resources (FHIR Release 4) schemas for seamless integration into Ayushman Bharat Digital Mission (ABDM).

### 4.5 Usability & Accessibility
- **NFR-12**: The user interface shall support dynamic runtime switching between **Crisp Clinical Light Mode** and **Deep Hospital Dark Mode**.
- **NFR-13**: All primary action buttons shall have distinct color coding (Blue for Primary Navigation, Green for Positive Confirmations, Amber for Quality Warnings, Red for Critical Referrals).
- **NFR-14**: Font sizing, contrast ratios, and button hit targets shall conform to Web Content Accessibility Guidelines (WCAG 2.1 Level AA).

---

## 5. External Interface Requirements

### 5.1 Hardware Interfaces
- **EIR-01**: Digital Fundus Cameras via USB Mass Storage, Direct PTP, or SD Card ingestion (Remidio Fundus on Phone NM-FOP, Forus 3nethra Classic, Topcon TRC-NW400).
- **EIR-02**: Standard desktop / thermal label printers for immediate physical referral card printing at rural camp sites.

### 5.2 Software & Network Interfaces
- **EIR-03**: ABDM Health Facility Registry (HFR) and Ayushman Bharat Health Account (ABHA) gateway APIs (HTTPS REST JSON).
- **EIR-04**: Tele-Ophthalmology Webhook synchronization over secure TLS 1.3 when network connectivity is established.
