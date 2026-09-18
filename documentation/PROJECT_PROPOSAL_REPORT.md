# PROJECT PROPOSAL & SYNOPSIS

## Project Name: DRISHTI-AI
### (Diabetic Retinopathy Intelligent Screening with Hierarchical Triage & Interpretability)
**Subtitle:** An Explainable Edge-AI Retinal Screening and Clinical Decision Support System for Rural Primary Health Centres  
**Problem Statement ID:** Smart India Hackathon (SIH26038)  
**Target Domain:** Healthcare, Telemedicine & AI for Rural Public Health  
**Academic Submission:** Capstone Project Proposal & Engineering Synopsis  
**Team Composition:** 6 Members (3 Machine Learning, 2 Data Science, 1 Full Stack)  
**Document Status:** Initial Proposal & Technical Approach  

---

## 1. Introduction & Problem Statement

### 1.1 Clinical Background & Epidemiology
Diabetic Retinopathy (DR) is a microvascular complication of diabetes mellitus that damages the retinal capillaries, leading to progressive and irreversible visual impairment if untreated. India is currently recognized as the "diabetes capital of the world," with an estimated **77 to 101 million individuals** diagnosed with diabetes and over **136 million** in pre-diabetic stages. Epidemiological studies indicate that approximately **18% to 22% of diabetic patients in India develop diabetic retinopathy**, with 5% to 7% progressing to sight-threatening stages (Severe Non-Proliferative DR or Proliferative DR).

### 1.2 The Rural Healthcare Dilemma
While early detection through regular fundus screening can prevent **over 90% of severe vision loss**, rural populations face a critical barrier to care:
1. **Severe Specialist Deficit:** Over **80% of India's ophthalmologists and vitreoretinal specialists practice in tier-1/tier-2 metropolitan cities**, whereas approximately **70% of the diabetic population resides in rural villages and remote districts**.
2. **Equipment & Operator Inexperience:** Primary Health Centres (PHCs) and Community Health Centres (CHCs) lack trained optometrists. Community health workers (ASHAs and ANMs) using low-cost portable fundus cameras often capture blurred, underexposed, or poorly centered images, leading to catastrophic false-negative assessments.
3. **Connectivity Bottlenecks:** Cloud-based deep learning APIs are unviable in rural primary health camps due to absent or intermittent 3G/4G/5G cellular coverage.
4. **The "Black Box" Trust Barrier:** Existing deep learning classifiers output raw probability scores without visual explanations, preventing local doctors from validating *why* an AI flagged a retina as diseased.

### 1.3 Problem Statement Formulation (SIH26038)
The core objective of this project is:
> *"To design, implement, and validate an edge-deployable, offline-first, explainable artificial intelligence (XAI) screening platform capable of autonomously grading fundus photographs into 5 ICDR stages, verifying capture quality via mathematical image quality metrics, visually highlighting lesion locations using Grad-CAM, and generating automated clinical referral documentation compliant with National Programme for Control of Blindness & Visual Impairment (NPCB&VI) and Ayushman Bharat Digital Mission (ABDM) standards."*

---

## 2. Proposed Solution Overview

To address these challenges, we propose an integrated software engineering solution comprising **six modular subsystems** running completely locally on edge hardware (standard laptops) with zero cloud dependency:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                 PROPOSED SYSTEM ARCHITECTURE                                    │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘

 [1. INGESTION & DATASET]       [2. OPTICAL IQA GATE]          [3. RETINAL ENHANCEMENT]
 ┌────────────────────────┐     ┌────────────────────────┐     ┌────────────────────────┐
 │ Multi-Benchmark Curation│   │ 5-Metric Pre-Filter    │     │ L*a*b* Rayleigh CLAHE  │
 │ (APTOS, EyePACS, IDRiD)│────►│ (Blur, Illum, Contrast)│────►│ Morphological Leveling │
 │ Synthetic Generator    │     │ Gate: Pass / Retake    │     │ 2D Median Filter       │
 └────────────────────────┘     └────────────────────────┘     └────────────────────────┘
                                                                            │
                                                                            ▼
 [6. REPORTING & ABDM]          [5. EXPLAINABLE AI (XAI)]      [4. DEEP LEARNING MODEL]
 ┌────────────────────────┐     ┌────────────────────────┐     ┌────────────────────────┐
 │ A4 Vector PDF Report   │     │ Grad-CAM Backprop Map  │     │ Transfer Learning CNN  │
 │ Quad-Image Panel       │◄────│ Otsu Lesion Bounding   │◄────│ (ResNet-50/MobileNetV2)│
 │ ABDM FHIR R4 JSON Hub  │     │ Quadrant Justification │     │ 5-Stage ICDR Softmax   │
 └────────────────────────┘     └────────────────────────┘     └────────────────────────┘
            ▲                                                               │
            └───────────────────────┬───────────────────────────────────────┘
                                    ▼
                      [7. 18-VIEW CLINICAL WORKSTATION GUI]
```

### Key Proposed Features:
1. **Automated Image Quality Assessment (IQA):** An optical quality gate calculating modified Laplacian variance (blur), 4-quadrant illumination uniformity, RMS contrast, Immerkaer noise, and Tenengrad sharpness. It will automatically prompt operators to retake poor captures before deep learning inference.
2. **Retinal Feature Contrast Enhancement:** A specialized 6-stage image enhancement pipeline operating in the L*a*b* color space using Contrast Limited Adaptive Histogram Equalization (CLAHE) and morphological background subtraction to highlight subtle microaneurysms and hemorrhages without color distortion.
3. **Deep Transfer Learning Inference:** Multi-class classification based on transfer-learned convolutional backbones (**ResNet-50** for high-capacity benchmark, **MobileNetV2** for ultra-lightweight edge deployment) outputting calibrated probabilities across all 5 International Clinical Diabetic Retinopathy (ICDR) grades.
4. **Explainable AI (Grad-CAM) & Lesion Bounding:** Generation of class-discriminative gradient activation maps, alpha-blended heatmap overlays, Otsu-segmented lesion bounding boxes, and natural-language justifications indicating the dominant pathological quadrant (e.g., Inferotemporal, Macular).
5. **Hospital-Grade Reporting & ABDM FHIR Integration:** 1-click generation of A4 clinical diagnostic PDF reports featuring a Quad-Image panel (Raw, CLAHE, Grad-CAM, Lesions), physician signature lines, and machine-readable JSON records complying with **Ayushman Bharat Digital Mission (ABDM) FHIR Release 4** schemas.
6. **Simulink Operational Queue Simulation:** Discrete-event queueing models (single-server, multi-server, and general service queues) simulating patient flows and camera station bottlenecks in rural community screening camps.

---

## 3. Technology Stack & Planned Tooling

| Domain | Proposed Technology / Library | Selection Justification |
| :--- | :--- | :--- |
| **Core Platform** | **Python 3.10+** | Global standard for artificial intelligence, computer vision, open-source reproducibility, and portable edge deployment. |
| **Deep Learning** | **PyTorch & Torchvision** | Dynamic computational graphs, native ResNet-152 deep transfer learning, automatic differentiation for Grad-CAM, and CPU/GPU execution. |
| **Computer Vision** | **OpenCV (`cv2`) & NumPy** | High-performance implementations of CLAHE, morphological filtering, connected components, and L*a*b* color space transforms. |
| **Evaluation & Statistics** | **Scikit-Learn & SciPy** | Rigorous multi-class evaluation: Cohen's Quadratic Weighted Kappa, ROC/AUC, confusion matrices, and clinical sensitivity metrics. |
| **User Interface** | **Streamlit / Web Workstation** | Modern responsive medical UI with interactive sliders, fundus calipers, and drag-and-drop clinical screening workflows. |
| **Queueing & Operations** | **Python Discrete-Event Simulation** | Mathematical modeling of camp registration, camera bottlenecks, and patient queues (single-camera, multi-camera, and variable service queues). |
| **Clinical Standards** | **HL7 FHIR Release 4 / SNOMED-CT / LOINC** | Conformance with National Digital Health Mission (NDHM / ABDM) for interoperability with government hospital EHR systems. |
| **Benchmarking Datasets** | **APTOS 2019, EyePACS, IDRiD, Messidor** | Clinically labeled fundus datasets providing diverse ethnicities, camera angles (45-degree and 50-degree fields of view), and lighting variations. |

---

## 4. Team Structure & Work Breakdown (6 Members)

To ensure modularity and accountability, the project responsibilities are divided across **3 Machine Learning students, 2 Data Science students, and 1 Full Stack student**:

### 📋 Official Team Roster & Module Ownership

| S.No | Student Name | Registration No. | Domain | Primary Subsystems Owned |
| :---: | :--- | :---: | :--- | :--- |
| **1** | **Subham Panigrahi** | `12312794` | **Data Science** | Dataset Ingestion, Class Balance & 5-Metric IQA Gatekeeper |
| **2** | **Konduri Mrunal** | `12316339` | **Data Science** | L*a*b* CLAHE Retinal Enhancement & Simulink Queue Simulation |
| **3** | **Rajbardhan Kumar** | `12326119` | **Machine Learning** | Transfer Learning CNN Backbones, Head Surgery & Training Loop |
| **4** | **Priyam Saxena** | `12313674` | **Machine Learning** | Real-Time Edge Inference Engine, Clinical Triage & Validation |
| **5** | **Kadambala Likhith** | `12314034` | **Machine Learning** | Grad-CAM Saliency Engine, Lesion Bounding & Text Justifications |
| **6** | **Vaibhav Raj** | `12325142` | **Full Stack** | 18-Screen Workstation GUI, A4 PDF Reports & ABDM FHIR R4 Hub |

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                 TEAM WORK BREAKDOWN (6 ROLES)                               │
├──────────────────────┬─────────────────────────────┬────────────────────────────────────────┤
│  DATA SCIENCE (2)    │     MACHINE LEARNING (3)    │            FULL STACK (1)              │
├──────────────────────┼─────────────────────────────┼────────────────────────────────────────┤
│ 1. Subham Panigrahi  │ 3. Rajbardhan Kumar         │ 6. Vaibhav Raj                         │
│    (Dataset & IQA)   │    (CNN Architecture/Train) │    (18-View GUI, Reports, ABDM FHIR)   │
│ 2. Konduri Mrunal    │ 4. Priyam Saxena            │                                        │
│    (CLAHE & Queues)  │    (Inference & Validation) │                                        │
│                      │ 5. Kadambala Likhith        │                                        │
│                      │    (Grad-CAM Saliency & XAI)│                                        │
└──────────────────────┴─────────────────────────────┴────────────────────────────────────────┘
```

### 👤 Member 1: Subham Panigrahi (Reg. No: 12312794) — Data Science: Dataset Curation & IQA Gate
* **Assigned Modules:** `data/` and `qualityAssessment/`
* **Planned Tasks:**
  1. **Dataset Ingestion & Standardization:** Aggregate and sanitize image records from APTOS-2019, EyePACS, IDRiD, and Messidor. Map varying ground-truth labels into the standard 5-stage ICDR scale.
  2. **Class Imbalance Resolution:** Implement stratified 70% Train / 15% Validation / 15% Test partitioning to preserve rare clinical presentations (Severe NPDR and Proliferative DR).
  3. **Synthetic Retina Generator:** Develop a procedural fundus generator creating synthetic retinal disks, vessels, and optic discs for automated offline test suites.
  4. **5-Metric IQA Engine:** Implement mathematical optical quality estimators:
     - Focus blur metric via modified Laplacian variance.
     - Illumination balance and mean luminance analysis across 4 quadrants.
     - RMS dynamic range contrast.
     - Sensor noise standard deviation via Immerkaer Laplacian convolution.
     - Edge sharpness via Tenengrad Sobel gradient energy.
  5. **Triage Gatekeeper Logic:** Combine metrics into an overall 0–100 score producing a 3-way verdict: `Good`, `Needs Enhancement`, or `Retake Image`.

### 👤 Member 2: Konduri Mrunal (Reg. No: 12316339) — Data Science: Retinal Enhancement & Queue Simulation
* **Assigned Modules:** `preprocessing/` and `simulink/`
* **Planned Tasks:**
  1. **L*a*b* Enhancement Pipeline:** Convert RGB fundus captures to L*a*b* color space to decouple pure brightness (the L* channel) from color components (the a* and b* channels).
  2. **Rayleigh CLAHE Implementation:** Implement Contrast Limited Adaptive Histogram Equalization (using an 8x8 local tile grid with a 2% contrast clip limit) to accentuate microaneurysms and hemorrhages without over-amplifying background noise.
  3. **Morphological Illumination Flattening:** Estimate non-uniform illumination falloff using a 30-pixel disk neighborhood and subtract it to correct background lighting gradients.
  4. **Quantitative Metric Benchmarking:** Compute objective fidelity metrics: Peak Signal-to-Noise Ratio (PSNR above 31.8 dB), Structural Similarity Index (SSIM above 0.94, where 1.0 represents perfect structural match), and Contrast Improvement Index.
  5. **Simulink Operational Queue Model:** Formulate mathematical queueing models (single-camera, multi-camera Erlang-C wait formulas, and variable exam-time models) and build a discrete-event simulation of an 8-hour rural camp to evaluate patient wait times and camera bottlenecks.

### 👤 Member 3: Rajbardhan Kumar (Reg. No: 12326119) — Machine Learning: Deep Transfer Learning & Training
* **Assigned Modules:** `classification/build_model.py`, `training/train_model.py`, and `models/`
* **Planned Tasks:**
  1. **Model Backbone Construction:** Implement transfer learning centered on **ResNet-152** as the primary deep architecture:
     - **ResNet-152** (primary clinical benchmark: 152 layers, ~60.2M parameters for fine-grained micro-lesion detection)
     - **ResNet-50** (edge deployment option: 50 layers, ~25.6M parameters)
     - **MobileNetV2** (inverted residual bottlenecks for ultra-low-power edge hardware)
  2. **Custom Network Surgery:** Replace default ImageNet heads with a custom retinal classification head: Global Average Pooling (GAP), a Dropout layer (40% deactivation rate to prevent clinical overfitting), a 5-unit Fully Connected linear layer, and Softmax activation.
  3. **Stochastic Data Augmentation:** Program affine augmentations: random horizontal/vertical reflections, continuous rotations (from -180 to +180 degrees), scaling, and shear.
  4. **Training Optimization:** Program the training pipeline using the Adam optimizer (initial learning rate of 0.0001 with momentum 0.9), Categorical Cross-Entropy loss, piecewise learning rate decay schedule (reducing learning rate by 10x every 10 epochs), early stopping with validation patience, and checkpoint weight serialization.

### 👤 Member 4: Priyam Saxena (Reg. No: 12313674) — Machine Learning: Edge Inference & Clinical Validation
* **Assigned Modules:** `classification/predict_dr.py`, `classification/evaluate_metrics.py`, and `tests/`
* **Planned Tasks:**
  1. **Real-Time Edge Inference Engine:** Develop `predict_dr.py` to execute forward passes with ResNet-152 in under 50 milliseconds on standard non-GPU laptop CPUs, returning calibrated softmax probabilities.
  2. **Clinical Triage Decision Logic:** Program medical referral rules:
     - Stages 0–1 (No DR, Mild NPDR) → Routine annual community surveillance.
     - Stage 2 (Moderate NPDR) → Non-urgent ophthalmic referral within 30 days.
     - Stage 3 (Severe NPDR) → Urgent referral to District Hospital within 7 days.
     - Stage 4 (Proliferative DR) → Emergency vitreoretinal referral within 24–48 hours.
  3. **Multi-Class Statistical Evaluation:** Evaluate:
     - Normalized 5x5 confusion matrix.
     - Cohen’s **Quadratic Weighted Kappa (target score >= 0.90)** penalizing distant grade misdiagnoses.
     - One-vs-Rest ROC curves and multi-class Area Under Curve (AUC >= 0.95).
     - Clinical Sensitivity (>= 90%) and Specificity (>= 90%) on referable cases (Stage 2 Moderate DR and above).
  4. **Hardware Latency Benchmarking:** Profile execution times and memory footprint across edge hardware.

### 👤 Member 5: Kadambala Likhith (Reg. No: 12314034) — Machine Learning: Explainable AI (Grad-CAM) & Lesions
* **Assigned Modules:** `explainability/grad_cam.py`
* **Planned Tasks:**
  1. **Grad-CAM Algorithm:** Compute the sensitivity gradients of the predicted DR stage score with respect to feature maps of the final convolutional layer of ResNet-152 (`model.layer4`), calculate an importance weight for each feature channel, and combine them through a positive evidence filter (ReLU):
     ```
     Grad-CAM Heatmap = Positive Values of [ Sum of (Feature Importance Weights × Feature Maps) ]
     ```
     This discards negative or irrelevant background features and retains only visual patterns that positively indicate disease.
  2. **Saliency Blending:** Normalize activation values to a 0 to 1 scale and overlay heatmaps on fundus photographs with custom colormaps (Turbo, Jet, Hot) and variable opacity (from 0% to 100% transparency).
  3. **Morphological Lesion Segmentation:** Apply Otsu adaptive thresholding and connected component analysis to isolate focal lesion hotspots (microaneurysms, hemorrhages, hard exudates) and draw bounding boxes.
  4. **Quadrant Mapping & Plain-Language Clinical Justification:** Map detected lesion centroids to retinal quadrants (Superotemporal, Inferotemporal, etc.) and generate automated natural-language justifications for rural health workers (ASHAs).

### 👤 Member 6: Vaibhav Raj (Reg. No: 12325142) — Full Stack: Workstation GUI, Reporting Hub & Systems Integration
* **Assigned Modules:** `main.py`, `reports/export_fhir.py`, and `simulation/camp_queue_simulation.py`
* **Planned Tasks:**
  1. **Interactive Workstation GUI:** Build the clinical workstation interface in Streamlit / Web UI:
     - Top navigation bar: Active patient pill, offline status indicator, and dynamic Dark/Light theme switching.
     - Multi-screen navigation switching between all clinical screening workflows.
     - Interactive medical canvas: crosshair calipers measuring micro-lesions in micrometers (µm), pan/zoom controls, and Grad-CAM opacity sliders.
  2. **Hospital-Grade PDF Report Engine:** Develop the official A4 diagnostic PDF generator complying with NPCB&VI standards:
     - Institutional branding & logo header.
     - **Quad-Image diagnostic panel** (Raw Fundus, Enhanced CLAHE, Grad-CAM Saliency, Lesion Bounding Boxes).
     - Attending doctor observations box and physician signature lines.
  3. **ABDM FHIR R4 Integration:** Program the JSON export engine conforming to Ayushman Bharat Digital Mission schemas (`DiagnosticReport` and `Observation` resources mapped to SNOMED-CT and LOINC codes).
  4. **Master Orchestration & System Testing:** Maintain `main.py` as the unified entry driver and build automated unit test suites (`tests/test_python_suite.py`).

---

## 5. Technical Approach & Detailed Methodology

### Phase 1: Optical Image Quality Assessment (IQA Gatekeeper)
```
Raw Fundus Image ──► [Quality Gatekeeper] ──► Focus Blur (Modified Laplacian)
                                         ──► Illumination Uniformity (4 Quadrants)
                                         ──► Vascular Contrast (RMS)
                                         ──► Sensor Noise (Immerkaer Laplacian)
                                         ──► Edge Sharpness (Tenengrad Sobel)
                                                        │
                         Verdict: Good (Proceed) / Needs Enhancement / Retake Image
```
- **Why It Matters:** Community health workers in rural screening camps often capture out-of-focus or poorly lit images. Feeding degraded images to an AI model causes dangerous false negatives.
- **How It Works:** Before running deep learning, the capture is evaluated across 5 mathematical indicators (blur, lighting balance across 4 quadrants, contrast, sensor noise, and sharpness).
- **Automated Triage Verdict:** Flags poor captures immediately as `Retake Image`, prompting the operator to recapture before the patient leaves the screening camp.

### Phase 2: Retinal Feature Enhancement in L*a*b* Color Space
- **The Core Problem:** Early diabetic microaneurysms and faint capillary hemorrhages have very low contrast against the reddish retina. Enhancing contrast directly in standard RGB distorts color balance, turning blood vessels unnatural shades of purple or cyan.
- **What is L*a*b* (Decoupling Brightness from Color):**
  Unlike RGB (where brightness and colors are blended across all three channels), the CIE L*a*b* space decouples image information:
  - **L* (Lightness / Luminance):** Pure brightness channel (0 = black, 100 = white).
  - **a* (Green–Red Axis):** Encodes the green-to-red color spectrum.
  - **b* (Blue–Yellow Axis):** Encodes the blue-to-yellow color spectrum.
- **Proposed CLAHE Enhancement:** Contrast Limited Adaptive Histogram Equalization (CLAHE with Rayleigh distribution) is applied **strictly to the L* (Lightness) channel**, leaving the a* and b* color channels completely untouched.
- **Clinical Benefit:** Subtle microvascular lesions become sharply visible with high contrast, while the retina preserves its natural warm reddish-orange clinical hue without chromatic distortion.

### Phase 3: Deep Transfer Learning & 5-Stage ICDR Staging
```
Input Image (224x224x3) ──► [MobileNetV2 / ResNet-50 Backbone] ──► [GAP Layer]
                                                                        │
                                                                 [Dropout (0.40)]
                                                                        │
                                                                 [Dense Layer (5)]
                                                                        │
                                                                 [Softmax Output]
```
- **Dual Backbone Architecture:**
  - **MobileNetV2 (~3.5M parameters):** Inverted residual bottlenecks engineered for real-time edge CPU inference (under 50 milliseconds) on standard laptops without requiring an expensive GPU.
  - **ResNet-50 (~25.6M parameters):** Deep residual network providing a high-capacity validation benchmark.
- **Custom Retinal Head:** Replaces ImageNet categories with Global Average Pooling (GAP), a Dropout layer (40% deactivation rate to prevent clinical overfitting), and a 5-unit Softmax head calibrated across all 5 ICDR severity stages (Grade 0: Normal to Grade 4: Proliferative DR).
- **Training Strategy:** Adam optimizer with piecewise learning rate step decay (reducing learning rate by 10x every 10 epochs) and early stopping tracking validation loss.

### Phase 4: Explainable AI (Grad-CAM) & Anatomical Pathology Localization
- **Overcoming the "Black Box":** A medical practitioner cannot trust an AI that outputs a raw probability score without showing *where* in the patient's eye it detected disease.
- **How Grad-CAM Works in 2 Intuitive Steps:**
  1. **Step 1 — Calculate Feature Importance (Alpha Weights):** The algorithm traces gradients from the predicted disease score back to the final convolutional feature maps. This evaluates: *"How strongly did each feature channel contribute to diagnosing this retina with Severe DR?"*
  2. **Step 2 — Generate Visual Saliency Map (Grad-CAM Heatmap):** Feature maps are multiplied by their importance weights and summed together. A **ReLU** (Rectified Linear Unit) filter discards negative values, preserving *only the positive visual evidence* of disease (such as microaneurysms, hemorrhages, and hard exudates).
- **Clinical Visualization:** The heatmap is overlaid onto the retinal photo (Red/Yellow = disease hotspots, Blue = normal tissue), automated bounding boxes are drawn around clustered lesions, and plain-language notes identify the affected anatomical quadrant (e.g., *"Focal hemorrhages localized in Inferotemporal region"*).

### Phase 5: Clinical Workstation & National Standards Integration
- **App Designer Workstation:** Designed for non-specialist rural health workers (ASHAs) with responsive Dark/Light themes, prominent triage alerts, and measurement calipers (in micrometers, µm).
- **ABDM FHIR R4 Integration:** Generates standardized JSON records mapped to LOINC (`LP200057-0`) and SNOMED-CT codes for seamless synchronization with the Ayushman Bharat Digital Mission EHR gateway.
- **Queueing Simulation:** Discrete-event models simulate patient queues across registration, camera acquisition, and tele-ophthalmologist review to optimize camp throughput.

---

## 6. Expected Deliverables & Impact

Upon completion, the project will deliver:
1. **Fully Integrated Python Application:** Executable via an interactive clinical screening workstation and unified CLI orchestrator (`main.py`) powered by a deep ResNet-152 transfer learning backbone.
2. **Clinical Validation Benchmark:** Target Quadratic Weighted Kappa >= 0.90, Sensitivity >= 90%, Specificity >= 90%, and edge inference latency under 50 milliseconds.
3. **Hospital-Grade Reporting Hub:** Automated A4 PDF reports and ABDM-compliant FHIR R4 JSON records.
4. **Operations Research Model:** Discrete-event queue simulation demonstrating community camp throughput and capacity optimization.
5. **Complete Documentation Suite:** System Design Document (SDD), Software Requirements Specification (SRS), Risk Analysis (FMEA), and User Guides.

---

*Submitted by the SIH26038 Engineering Project Team • Academic Year 2026*
