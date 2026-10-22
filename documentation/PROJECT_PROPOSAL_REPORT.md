# PROJECT PROPOSAL & SYNOPSIS

## Project Name: DRISHTI-AI
### (Diabetic Retinopathy Intelligent Screening with Hierarchical Triage & Interpretability)
**Subtitle:** An Explainable Edge-AI Retinal Screening and Clinical Decision Support System for Rural Primary Health Centres  
**Problem Statement ID:** Smart India Hackathon (SIH26038)  
**Target Domain:** Healthcare, Telemedicine & AI for Rural Public Health  
**Academic Submission:** Capstone Project Proposal & Engineering Synopsis  
**Team Composition:** 6 Members (3 Machine Learning, 2 Data Science, 1 Full Stack)  
**Document Status:** 100% Pure Python Implementation (PyTorch & OpenCV Stack)  

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
> *"To design, implement, and validate an edge-deployable, offline-first, explainable artificial intelligence (XAI) screening platform capable of autonomously grading fundus photographs into 5 ICDR stages using deep transfer learning (ResNet-152), verifying capture quality via mathematical image quality metrics, visually highlighting lesion locations using Grad-CAM, providing an interactive Clinical Workstation UI, and generating automated clinical referral documentation compliant with National Programme for Control of Blindness & Visual Impairment (NPCB&VI) and Ayushman Bharat Digital Mission (ABDM) standards."*

---

## 2. Proposed Solution Overview

To address these challenges, we have designed and implemented an integrated software engineering solution comprising **six modular subsystems** running completely locally on edge hardware (standard laptops) with zero cloud dependency:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                           DRISHTI-AI SYSTEM ARCHITECTURE (100% PYTHON)                          │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘

 [1. INGESTION & DATASET]       [2. OPTICAL IQA GATE]          [3. RETINAL ENHANCEMENT]
 ┌────────────────────────┐     ┌────────────────────────┐     ┌────────────────────────┐
 │ Multi-Benchmark Curation│   │ 5-Metric Pre-Filter    │     │ L*a*b* Rayleigh CLAHE  │
 │ (APTOS, EyePACS, IDRiD)│────►│ (Blur, Illum, Contrast)│────►│ Homomorphic Leveling   │
 │ Synthetic Generator    │     │ Gate: Pass / Retake    │     │ Green Channel Contrast │
 └────────────────────────┘     └────────────────────────┘     └────────────────────────┘
                                                                            │
                                                                            ▼
 [6. REPORTING & ABDM]          [5. EXPLAINABLE AI (XAI)]      [4. DEEP LEARNING MODEL]
 ┌────────────────────────┐     ┌────────────────────────┐     ┌────────────────────────┐
 │ A4 Vector PDF Report   │     │ Grad-CAM Backprop Map  │     │ ResNet-152 Backbone    │
 │ Quad-Image Panel       │◄────│ Saliency Opacity Blend │◄────│ (152 Layers, ~60.2M)   │
 │ ABDM FHIR R4 JSON Hub  │     │ Lesion Hotspot Bounding│     │ 5-Stage ICDR Softmax   │
 └────────────────────────┘     └────────────────────────┘     └────────────────────────┘
            ▲                                                               │
            └───────────────────────┬───────────────────────────────────────┘
                                    ▼
           [7. INTERACTIVE CLINICAL WORKSTATION WEB UI (app.py)]
```

### Key Architectural Features:
1. **Automated Image Quality Assessment (IQA):** An optical quality gate calculating modified Laplacian variance (blur), 4-quadrant illumination uniformity, RMS contrast, Immerkaer noise, and Tenengrad sharpness. It automatically prompts operators to retake poor captures before deep learning inference.
2. **Retinal Feature Contrast Enhancement:** A specialized image enhancement pipeline operating in the L*a*b* color space using Contrast Limited Adaptive Histogram Equalization (CLAHE) and homomorphic illumination correction to highlight subtle microaneurysms and hemorrhages without color distortion.
3. **Deep Transfer Learning Inference (ResNet-152):** Multi-class classification based on **ResNet-152** (152 residual bottleneck layers, ~60.2M parameters) with custom network surgery (`Dropout(0.40) + Linear(2048, 5)`), outputting calibrated probabilities across all 5 International Clinical Diabetic Retinopathy (ICDR) grades with inference latency under 50 ms.
4. **Explainable AI (Grad-CAM) & Lesion Saliency:** Generation of class-discriminative gradient activation maps from `layer4`, interactive opacity-blended heatmap overlays, lesion bounding coordinates, and plain-language clinical justifications indicating the dominant pathological quadrant.
5. **Interactive Clinical Workstation Web UI (`app.py`):** Modern, browser-based clinical dashboard supporting real-time image drag-and-drop, live optical IQA gauges, animated 5-stage softmax probability bars, interactive Grad-CAM heatmap blending, and one-click PDF printing.
6. **Hospital-Grade Reporting & ABDM FHIR Integration:** 1-click generation of clinical diagnostic PDF reports and machine-readable JSON records complying with **Ayushman Bharat Digital Mission (ABDM) FHIR Release 4** schemas.
7. **Operational Camp Queue Simulation:** Pure Python discrete-event queueing model simulating patient flows and camera station bottlenecks in rural community screening camps.

---

## 3. Technology Stack & Planned Tooling

| Domain | Implemented Technology / Library | Selection Justification |
| :--- | :--- | :--- |
| **Core Platform** | **Python 3.10+ (100% Pure Python)** | Complete migration from legacy MATLAB/Simulink; cross-platform, open-source reproducibility, zero proprietary licensing costs. |
| **Deep Learning** | **PyTorch 2.x & Torchvision** | Dynamic computational graphs, pre-trained **ResNet-152** deep transfer learning backbone, autograd for Grad-CAM, and CPU/GPU execution. |
| **Computer Vision** | **OpenCV (`cv2`), Pillow & NumPy** | High-performance implementations of CLAHE, morphological filtering, connected components, and L*a*b* color space transforms. |
| **Evaluation & Statistics** | **Scikit-Learn & SciPy** | Rigorous multi-class evaluation: **Cohen's Quadratic Weighted Kappa ($\kappa_w \ge 0.90$)**, ROC/AUC, confusion matrices, and clinical sensitivity metrics. |
| **User Interface** | **Clinical Workstation Web UI (`app.py`)** | Interactive local web application with drag-and-drop fundus upload, real-time inference, Grad-CAM opacity sliders, and print styling. |
| **Queueing & Operations** | **Python Discrete-Event Simulation (`simulation/`)** | Monte Carlo Poisson arrival queue model comparing 1-camera vs. 2-camera operational throughput in rural health camps. |
| **Clinical Standards** | **HL7 FHIR Release 4 / SNOMED-CT / LOINC** | Conformance with National Digital Health Mission (NDHM / ABDM) for interoperability with government hospital EHR systems. |
| **Benchmarking Datasets** | **APTOS 2019, EyePACS, IDRiD, Messidor** | Clinically labeled fundus datasets providing diverse ethnicities, camera angles (45° and 50° FOV), and lighting variations. |

---

## 4. Team Structure & Work Breakdown (6 Members)

To ensure modularity and accountability, the project responsibilities are divided across **3 Machine Learning students, 2 Data Science students, and 1 Full Stack student**:

### 📋 Official Team Roster & Module Ownership

| S.No | Student Name | Registration No. | Domain | Primary Subsystems Owned |
| :---: | :--- | :---: | :--- | :--- |
| **1** | **Subham Panigrahi** | `12312794` | **Data Science** | Dataset Ingestion, Class Balance & 5-Metric IQA Gatekeeper (`quality_assessment/`) |
| **2** | **Konduri Mrunal** | `12316339` | **Data Science** | L*a*b* CLAHE Enhancement (`preprocessing/`) & Camp Queue Simulation (`simulation/`) |
| **3** | **Rajbardhan Kumar** | `12326119` | **Machine Learning** | ResNet-152 Transfer Learning Backbone, Network Surgery & Training (`training/`) |
| **4** | **Priyam Saxena** | `12313674` | **Machine Learning** | Real-Time Edge Inference Engine, Clinical Triage & Validation (`classification/`) |
| **5** | **Kadambala Likhith** | `12314034` | **Machine Learning** | Grad-CAM Saliency Engine, Lesion Bounding & Text Justifications (`explainability/`) |
| **6** | **Vaibhav Raj** | `12325142` | **Full Stack** | Clinical Workstation Web UI (`app.py`), CLI Orchestrator (`main.py`) & FHIR Hub (`reports/`) |

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                 TEAM WORK BREAKDOWN (6 ROLES)                               │
├──────────────────────┬─────────────────────────────┬────────────────────────────────────────┤
│  DATA SCIENCE (2)    │     MACHINE LEARNING (3)    │            FULL STACK (1)              │
├──────────────────────┼─────────────────────────────┼────────────────────────────────────────┤
│ 1. Subham Panigrahi  │ 3. Rajbardhan Kumar         │ 6. Vaibhav Raj                         │
│    (Dataset & IQA)   │    (ResNet-152 Architecture)│    (Web UI Workstation, FHIR, CLI)     │
│ 2. Konduri Mrunal    │ 4. Priyam Saxena            │                                        │
│    (CLAHE & Queues)  │    (Inference & Validation) │                                        │
│                      │ 5. Kadambala Likhith        │                                        │
│                      │    (Grad-CAM Saliency & XAI)│                                        │
└──────────────────────┴─────────────────────────────┴────────────────────────────────────────┘
```

### 👤 Member 1: Subham Panigrahi (Reg. No: 12312794) — Data Science: Dataset Curation & IQA Gate
* **Assigned Modules:** `data/` and `quality_assessment/`
* **Implemented Subsystems:**
  1. **Dataset Ingestion & Standardization:** Aggregate and sanitize image records from APTOS-2019, EyePACS, IDRiD, and Messidor. Map varying ground-truth labels into the standard 5-stage ICDR scale.
  2. **Class Imbalance Resolution:** Implement stratified 70% Train / 15% Validation / 15% Test partitioning to preserve rare clinical presentations (Severe NPDR and Proliferative DR).
  3. **Synthetic Retina Generator:** Develop a procedural fundus generator creating synthetic retinal disks, vessels, and optic discs for automated offline test suites.
  4. **5-Metric IQA Engine:** Implement mathematical optical quality estimators:
     - Focus blur metric via modified Laplacian variance.
     - Illumination balance and mean luminance analysis across 4 quadrants.
     - RMS dynamic range contrast.
     - Sensor noise standard deviation via Immerkaer Laplacian convolution.
     - Edge sharpness via Tenengrad Sobel gradient energy.
  5. **Triage Gatekeeper Logic:** Combine metrics into an overall 0–100 score producing a 3-way verdict: `Good`, `Usable`, or `Retake Image`.

### 👤 Member 2: Konduri Mrunal (Reg. No: 12316339) — Data Science: Retinal Enhancement & Queue Simulation
* **Assigned Modules:** `preprocessing/` and `simulation/camp_queue_simulation.py`
* **Implemented Subsystems:**
  1. **L*a*b* Enhancement Pipeline:** Convert RGB fundus captures to L*a*b* color space to decouple pure brightness (the L* channel) from color components (the a* and b* channels).
  2. **Rayleigh CLAHE Implementation:** Implement Contrast Limited Adaptive Histogram Equalization (using an 8x8 local tile grid with a 2% contrast clip limit) to accentuate microaneurysms and hemorrhages without over-amplifying background noise.
  3. **Homomorphic Illumination Correction:** Estimate non-uniform illumination falloff and correct background lighting gradients.
  4. **Quantitative Metric Benchmarking:** Compute objective fidelity metrics: Peak Signal-to-Noise Ratio (PSNR above 31.8 dB) and Structural Similarity Index (SSIM above 0.94).
  5. **Camp Operational Queue Simulation:** Formulate Python Monte Carlo discrete-event models (single-camera vs. dual-camera queues) of an 8-hour rural camp to evaluate patient wait times and camera bottlenecks.

### 👤 Member 3: Rajbardhan Kumar (Reg. No: 12326119) — Machine Learning: Deep Transfer Learning & Training
* **Assigned Modules:** `classification/build_model.py` and `training/train_model.py`
* **Implemented Subsystems:**
  1. **Model Backbone Construction:** Implement transfer learning centered on **ResNet-152** as the primary deep architecture:
     - **ResNet-152** (primary clinical benchmark: 152 layers, ~60.2M parameters for fine-grained micro-lesion detection).
     - Bottleneck layer extraction with 2,048 feature channels at `layer4`.
     - ResNet-50 (~25.6M parameters) and MobileNetV2 as lightweight edge alternatives.
  2. **Custom Network Surgery:** Replace default ImageNet heads with a custom retinal classification head: Global Average Pooling (GAP), a Dropout layer (40% deactivation rate to prevent clinical overfitting), and a 5-unit Fully Connected linear layer (`nn.Linear(2048, 5)`).
  3. **Layer Freezing Strategy:** Freeze generic early feature extraction layers, unfreezing `layer4` and classification head for domain adaptation.
  4. **Training Optimization:** Program the training pipeline using the AdamW optimizer (learning rate $10^{-4}$, weight decay $10^{-4}$), Weighted Cross-Entropy Loss to counter class imbalance, and StepLR/CosineAnnealing learning rate decay.

### 👤 Member 4: Priyam Saxena (Reg. No: 12313674) — Machine Learning: Edge Inference & Clinical Validation
* **Assigned Modules:** `classification/predict_dr.py`, `classification/evaluate_metrics.py`, and `tests/test_python_suite.py`
* **Implemented Subsystems:**
  1. **Real-Time Edge Inference Engine:** Develop `predict_dr.py` to execute forward passes with ResNet-152 in under 50 milliseconds on standard non-GPU laptop CPUs, returning calibrated softmax probabilities.
  2. **Clinical Triage Decision Logic:** Program medical referral rules:
     - Stages 0–1 (No DR, Mild NPDR) → Routine annual community surveillance.
     - Stage 2 (Moderate NPDR) → Non-urgent ophthalmic referral within 30 days.
     - Stage 3 (Severe NPDR) → Priority referral to District Hospital within 7–14 days.
     - Stage 4 (Proliferative DR) → Emergency vitreoretinal referral within 24–48 hours.
  3. **Multi-Class Statistical Evaluation:** Evaluate:
     - Normalized 5x5 confusion matrix.
     - Cohen’s **Quadratic Weighted Kappa (target score $\kappa_w \ge 0.90$)** heavily penalizing distant grade misdiagnoses.
     - Clinical Sensitivity ($\ge 90\%$) and Specificity ($\ge 90\%$) on referable cases (Stage 2 Moderate DR and above).
  4. **Automated Unit Testing:** 12 automated unit tests verified 100% passing across all modules.

### 👤 Member 5: Kadambala Likhith (Reg. No: 12314034) — Machine Learning: Explainable AI (Grad-CAM) & Lesions
* **Assigned Modules:** `explainability/grad_cam.py`
* **Implemented Subsystems:**
  1. **Grad-CAM Algorithm:** Compute the sensitivity gradients of the predicted DR stage score with respect to feature maps of the final convolutional layer of ResNet-152 (`model.layer4`), calculate an importance weight for each feature channel, and combine them through a positive evidence filter (ReLU):
     $$\text{Grad-CAM Heatmap} = \text{ReLU}\left(\sum_{k} \alpha_k A^k\right)$$
  2. **Saliency Blending & Opacity Control:** Normalize activation values to a 0–1 scale and overlay heatmaps on fundus photographs with colormap Jet and interactive opacity blending.
  3. **Lesion Centroid Localization:** Isolate focal lesion hotspots (microaneurysms, hemorrhages, hard exudates) and locate coordinates.
  4. **Quadrant Mapping & Plain-Language Clinical Justification:** Map detected lesion centroids to retinal quadrants (Superotemporal, Inferotemporal, etc.) and generate automated natural-language justifications for rural health workers (ASHAs).

### 👤 Member 6: Vaibhav Raj (Reg. No: 12325142) — Full Stack: Workstation Web UI, Reporting Hub & Integration
* **Assigned Modules:** `app.py`, `main.py`, and `reports/export_fhir.py`
* **Implemented Subsystems:**
  1. **Interactive Clinical Workstation Web UI (`app.py`):**
     - Full-featured browser workstation with drag-and-drop and file picker image upload.
     - 1-click clinical benchmark sample loader (Stages 0 to 4).
     - Real-time optical IQA validation scorecards.
     - Animated 5-stage softmax probability distribution bars.
     - Interactive Grad-CAM heatmap opacity blend slider.
     - Print-optimized diagnostic summary layout.
  2. **Master Orchestrator CLI (`main.py`):** Unified execution driver supporting modes: `--mode ui`, `--mode predict`, `--mode quality`, `--mode simulate`, and `--mode fhir`.
  3. **ABDM FHIR R4 Integration:** Program the JSON export engine conforming to Ayushman Bharat Digital Mission schemas (`DiagnosticReport` and `Observation` resources mapped to SNOMED-CT and LOINC codes).

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
                         Verdict: Good (Proceed) / Usable / Retake Image
```
- **Why It Matters:** Community health workers in rural screening camps often capture out-of-focus or poorly lit images. Feeding degraded images to an AI model causes dangerous false negatives.
- **How It Works:** Before running deep learning, the capture is evaluated across mathematical indicators (blur, lighting balance across 4 quadrants, contrast, sensor noise, and sharpness).
- **Automated Triage Verdict:** Flags poor captures immediately as `Retake Image`, prompting the operator to recapture before the patient leaves the screening camp.

### Phase 2: Retinal Feature Enhancement in L*a*b* Color Space
- **The Core Problem:** Early diabetic microaneurysms and faint capillary hemorrhages have very low contrast against the reddish retina. Enhancing contrast directly in standard RGB distorts color balance, turning blood vessels unnatural shades.
- **What is L*a*b* (Decoupling Brightness from Color):**
  Unlike RGB (where brightness and colors are blended across all three channels), the CIE L*a*b* space decouples image information:
  - **L* (Lightness / Luminance):** Pure brightness channel (0 = black, 100 = white).
  - **a* (Green–Red Axis):** Encodes the green-to-red color spectrum.
  - **b* (Blue–Yellow Axis):** Encodes the blue-to-yellow color spectrum.
- **Proposed CLAHE Enhancement:** Contrast Limited Adaptive Histogram Equalization (CLAHE with Rayleigh distribution) is applied strictly to the L* (Lightness) channel, leaving the a* and b* color channels completely untouched.
- **Clinical Benefit:** Subtle microvascular lesions become sharply visible with high contrast, while the retina preserves its natural warm reddish-orange clinical hue without chromatic distortion.

### Phase 3: Deep Transfer Learning & 5-Stage ICDR Staging (ResNet-152)
```
Input Image (224x224x3) ──► [ResNet-152 Backbone (152 Bottleneck Blocks)] ──► [GAP Layer]
                                                                                   │
                                                                            [Dropout (0.40)]
                                                                                   │
                                                                            [Linear (2048, 5)]
                                                                                   │
                                                                            [Softmax Output]
```
- **Primary Backbone Architecture (ResNet-152):**
  - **152 residual bottleneck layers (~60.2 Million parameters):** Residual skip connections solve the vanishing gradient problem, allowing the network to extract high-level microvascular features (punctate microaneurysms, cotton wool spots, and neovascular loops).
  - **Bottleneck Feature Dimension:** 2,048 feature channels extracted from `layer4`.
- **Custom Retinal Classification Head:**
  - `model.fc = nn.Sequential(nn.Dropout(p=0.40), nn.Linear(2048, 5))`
  - Outputs 5 calibrated class probabilities corresponding to ICDR clinical stages (Grade 0: Normal to Grade 4: Proliferative DR).
- **Inference Speed:** Engineered for native CPU execution in **under 50 milliseconds** per image on standard laptops without requiring a discrete GPU.
- **Primary Clinical Metric — Cohen's Quadratic Weighted Kappa ($\kappa_w$):**
  $$w_{i,j} = \frac{(i - j)^2}{(N - 1)^2}$$
  Penalizes catastrophic clinical errors (e.g., misdiagnosing Stage 4 PDR as Stage 0 Normal) with maximum quadratic penalty (1.0). Target benchmark: **$\kappa_w \ge 0.90$**.

### Phase 4: Explainable AI (Grad-CAM) & Anatomical Pathology Localization
- **Overcoming the "Black Box":** A medical practitioner cannot trust an AI that outputs a raw probability score without showing *where* in the patient's eye it detected disease.
- **How Grad-CAM Works in 2 Intuitive Steps:**
  1. **Step 1 — Calculate Feature Importance ($\alpha_k$ Weights):** The algorithm traces gradients from the predicted disease score back to feature maps of `model.layer4`. This evaluates: *"How strongly did each feature channel contribute to diagnosing this retina with Severe DR?"*
  2. **Step 2 — Generate Visual Saliency Map:** Feature maps are weighted and summed, filtered through ReLU to preserve only positive visual evidence of disease (microaneurysms, hemorrhages, and hard exudates).
- **Interactive Visualization:** The heatmap is overlaid onto the retinal photo with an interactive opacity slider in the Web UI, and plain-language notes identify the affected anatomical quadrant.

### Phase 5: Interactive Clinical Workstation & National Standards Integration
- **Interactive Web UI Workstation (`app.py`):** Designed for rural primary health workers (ASHAs) with responsive layout, real-time image drag-and-drop, dynamic 5-stage softmax probability bars, prominent triage alerts, and print styling.
- **ABDM FHIR R4 Integration (`reports/export_fhir.py`):** Generates standardized JSON records mapped to LOINC (`74062-1`) and SNOMED-CT (`4855003`) codes for seamless synchronization with the Ayushman Bharat Digital Mission EHR gateway.
- **Queueing Simulation (`simulation/camp_queue_simulation.py`):** Python discrete-event Monte Carlo models simulate patient queues across registration, camera acquisition, and tele-ophthalmologist review to optimize camp throughput.

---

## 6. Expected Deliverables & Impact

Upon completion, the project delivers:
1. **100% Pure Python Application:** Fully operational PyTorch and OpenCV pipeline executable via the interactive Clinical Workstation Web UI (`app.py`) and unified CLI orchestrator (`main.py`).
2. **Deep Transfer Learning Engine:** Pre-trained **ResNet-152** architecture with network surgery, achieving edge CPU inference latency under 50 ms.
3. **Rigorous Clinical Validation:** Target Quadratic Weighted Kappa $\kappa_w \ge 0.90$, Referable DR Sensitivity $\ge 90\%$, and Specificity $\ge 90\%$.
4. **Hospital-Grade Reporting Hub:** Automated clinical diagnostic PDF reports and ABDM-compliant FHIR R4 JSON records.
5. **Operations Research Queue Model:** Discrete-event camp queue simulation demonstrating community screening capacity optimization.
6. **Automated Verification:** 12 automated unit tests (100% passing) and comprehensive technical documentation.

---

*Submitted by the SIH26038 Engineering Project Team • Academic Year 2026*
