# PROJECT PROPOSAL & SYNOPSIS

## Explainable AI-Based Diabetic Retinopathy Screening System for Rural Primary Health Centres

**Problem Statement ID:** Smart India Hackathon (SIH26038)  
**Target Domain:** Healthcare, Telemedicine & AI for Rural Public Health  
**Academic Submission:** Project Synopsis / Phase-1 Engineering Proposal  
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
2. **Retinal Feature Contrast Enhancement:** A specialized 6-stage image enhancement pipeline operating in $L^*a^*b^*$ color space using Contrast Limited Adaptive Histogram Equalization (CLAHE) and morphological background subtraction to highlight subtle microaneurysms and hemorrhages without color distortion.
3. **Deep Transfer Learning Inference:** Multi-class classification based on transfer-learned convolutional backbones (**ResNet-50** for high-capacity benchmark, **MobileNetV2** for ultra-lightweight edge deployment) outputting calibrated probabilities across all 5 International Clinical Diabetic Retinopathy (ICDR) grades.
4. **Explainable AI (Grad-CAM) & Lesion Bounding:** Generation of class-discriminative gradient activation maps, alpha-blended heatmap overlays, Otsu-segmented lesion bounding boxes, and natural-language justifications indicating the dominant pathological quadrant (e.g., Inferotemporal, Macular).
5. **Hospital-Grade Reporting & ABDM FHIR Integration:** 1-click generation of A4 clinical diagnostic PDF reports featuring a Quad-Image panel (Raw, CLAHE, Grad-CAM, Lesions), physician signature lines, and machine-readable JSON records complying with **Ayushman Bharat Digital Mission (ABDM) FHIR Release 4** schemas.
6. **Simulink Operational Queue Simulation:** Discrete-event queueing models ($M/M/1$, $M/M/c$, and $M/G/1$) simulating patient flows and camera station bottlenecks in rural community screening camps.

---

## 3. Technology Stack & Planned Tooling

| Domain | Proposed Technology / Library | Selection Justification |
| :--- | :--- | :--- |
| **Core Platform** | **MATLAB R2021b+** | Industry standard for medical device prototyping, signal/image processing, and FDA-traceable engineering. |
| **Deep Learning** | **MATLAB Deep Learning Toolbox** | Native layerGraph surgery, automatic differentiation for Grad-CAM, transfer learning backbones, and INT8/FP16 quantization. |
| **Computer Vision** | **Image Processing Toolbox** | Optimized native implementations of CLAHE, morphological filtering, connected components (`bwconncomp`), and color space transforms. |
| **User Interface** | **MATLAB App Designer** | Desktop-grade medical workstation design with responsive grid layouts, canvas tools, and Dark/Light theme switching. |
| **Queueing & Operations** | **Simulink & SimEvents** | Discrete-event entity modeling of camp registration, camera acquisition, and tele-review queues. |
| **Verification & Linting** | **Python 3.10+ / Custom Linters** | Automated cross-platform syntax validation, bracket matching, and CI integrity checks. |
| **Clinical Standards** | **HL7 FHIR Release 4 / SNOMED-CT / LOINC** | Conformance with National Digital Health Mission (NDHM / ABDM) for interoperability with government hospital EHR systems. |
| **Benchmarking Datasets** | **APTOS 2019, EyePACS, IDRiD, Messidor** | Clinically labeled fundus datasets providing diverse ethnicities, camera angles ($45^\circ / 50^\circ$), and lighting variations. |

---

## 4. Team Structure & Work Breakdown (6 Members)

To ensure modularity and accountability, the project responsibilities are divided across **3 Machine Learning students, 2 Data Science students, and 1 Full Stack student**:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                 TEAM WORK BREAKDOWN (6 ROLES)                               │
├──────────────────────┬─────────────────────────────┬────────────────────────────────────────┤
│  DATA SCIENCE (2)    │     MACHINE LEARNING (3)    │            FULL STACK (1)              │
├──────────────────────┼─────────────────────────────┼────────────────────────────────────────┤
│ DS 1: Dataset & IQA  │ ML 1: Architecture & Train  │ FS 1: 18-Screen Workstation GUI,       │
│ DS 2: CLAHE & Queues │ ML 2: Inference & Metrics   │       Reporting Engine & ABDM FHIR Hub │
│                      │ ML 3: Grad-CAM Explainable  │                                        │
└──────────────────────┴─────────────────────────────┴────────────────────────────────────────┘
```

### 👤 Member 1: Data Science — Dataset Engineering & Image Quality Gate (IQA)
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

### 👤 Member 2: Data Science — Retinal Enhancement Pipeline & Queue Simulation
* **Assigned Modules:** `preprocessing/` and `simulink/`
* **Planned Tasks:**
  1. **$L^*a^*b^*$ Enhancement Pipeline:** Convert RGB fundus captures to $L^*a^*b^*$ color space to decouple luminance ($L^*$) from chromatic components ($a^*, b^*$).
  2. **Rayleigh CLAHE Implementation:** Implement Contrast Limited Adaptive Histogram Equalization ($8 \times 8$ tile grid, clip limit $0.02$) to accentuate microaneurysms and hemorrhages without over-amplifying noise.
  3. **Morphological Illumination Flattening:** Estimate non-uniform illumination falloff via large disk structuring element opening ($r = 30$) and subtract it from the background.
  4. **Quantitative Metric Benchmarking:** Compute objective fidelity metrics: Peak Signal-to-Noise Ratio ($\text{PSNR} > 31.8\text{ dB}$), Structural Similarity Index ($\text{SSIM} > 0.94$), and Contrast Improvement Index.
  5. **Simulink Operational Queue Model:** Formulate mathematical queueing models ($M/M/1$, $M/M/c$ Erlang-C, and $M/G/1$ Pollaczek-Khinchine) and build a discrete-event simulation of an 8-hour rural camp to evaluate patient wait times and camera bottlenecks.

### 👤 Member 3: Machine Learning — Deep Transfer Learning Architectures & Training
* **Assigned Modules:** `classification/buildModel.m`, `training/`, and `models/`
* **Planned Tasks:**
  1. **Model Backbone Construction:** Implement transfer learning on 4 distinct CNN backbones:
     - **ResNet-50** (primary clinical benchmark, ~25.6M parameters)
     - **MobileNetV2** (inverted residual bottlenecks for edge hardware, ~3.5M parameters)
     - **EfficientNet-B0** (compound scaling, ~5.3M parameters)
     - **ResNet-18** (fast baseline for low-power devices)
  2. **Custom Network Surgery:** Replace default ImageNet heads with a custom retinal classification head: Global Average Pooling (GAP), Dropout ($p = 0.40$), a 5-unit Fully Connected layer, and Softmax activation.
  3. **Stochastic Data Augmentation:** Program affine augmentations: random horizontal/vertical reflections, continuous rotations ($-180^\circ$ to $+180^\circ$), scaling, and shear.
  4. **Training Optimization:** Program the training pipeline using the Adam optimizer ($\beta_1=0.9, \beta_2=0.999$, $\text{LR}=10^{-4}$), Categorical Cross-Entropy loss, piecewise learning rate decay schedule ($\gamma=0.1$ every 10 epochs), early stopping with validation patience, and checkpoint weight serialization.

### 👤 Member 4: Machine Learning — Edge Inference Engine & Clinical Validation
* **Assigned Modules:** `classification/predictDR.m`, `classification/evaluateMetrics.m`, and `testing/`
* **Planned Tasks:**
  1. **Real-Time Edge Inference Engine:** Develop `predictDR.m` to execute forward passes in $< 50\text{ ms}$ on standard non-GPU laptop CPUs, returning calibrated softmax probabilities.
  2. **Clinical Triage Decision Logic:** Program medical referral rules:
     - Stages 0–1 (No DR, Mild NPDR) $\rightarrow$ Routine annual community surveillance.
     - Stage 2 (Moderate NPDR) $\rightarrow$ Non-urgent ophthalmic referral within 30 days.
     - Stage 3 (Severe NPDR) $\rightarrow$ Urgent referral to District Hospital within 7 days.
     - Stage 4 (Proliferative DR) $\rightarrow$ Emergency vitreoretinal referral within 24–48 hours.
  3. **Multi-Class Statistical Evaluation:** Evaluate:
     - Normalized 5x5 confusion matrix.
     - Cohen’s **Quadratic Weighted Kappa ($\kappa_w \ge 0.90$)** penalizing distant grade misdiagnoses.
     - One-vs-Rest ROC curves and multi-class Area Under Curve ($\text{AUC} \ge 0.95$).
     - Clinical Sensitivity ($\ge 90\%$) and Specificity ($\ge 90\%$) on referable DR ($\text{Stage} \ge 2$).
  4. **Hardware Latency Benchmarking:** Profile execution times and memory footprint across edge hardware.

### 👤 Member 5: Machine Learning — Explainable AI (Grad-CAM) & Lesion Localization
* **Assigned Modules:** `explainability/`
* **Planned Tasks:**
  1. **Grad-CAM Algorithm:** Compute gradients of the target class score $y^c$ with respect to feature activation maps $A^k$ of the final convolutional layer (`activation_49_relu` / `out_relu`), pool gradient weights $\alpha_k^c$, and apply $\text{ReLU}$:
     $$L_{\text{Grad-CAM}}^c = \text{ReLU}\left(\sum_k \alpha_k^c A^k\right)$$
  2. **Saliency Blending:** Normalize activation values to $[0, 1]$ and overlay heatmaps on fundus photographs with custom colormaps (Turbo, Jet, Hot) and variable opacity ($\alpha$).
  3. **Morphological Lesion Segmentation:** Apply Otsu’s thresholding and connected component analysis (`bwconncomp`) to isolate focal lesion hotspots (microaneurysms, hemorrhages, hard exudates) and draw bounding boxes.
  4. **Quadrant Mapping & Plain-Language Clinical Justification:** Map detected lesion centroids to retinal quadrants (Superotemporal, Inferotemporal, etc.) and generate automated natural-language justifications for rural health workers (ASHAs).

### 👤 Member 6: Full Stack — Workstation GUI, Reporting Hub & Systems Integration
* **Assigned Modules:** `gui/`, `reports/`, `main.m`, `utils/`, and `config/`
* **Planned Tasks:**
  1. **18-Screen Workstation GUI:** Build the clinical workstation interface in MATLAB App Designer:
     - Top navigation bar: Active patient pill, offline status indicator, and dynamic Dark/Light theme switching.
     - 18-screen sidebar navigation switching between all clinical screens.
     - Interactive medical canvas: crosshair calipers measuring micro-lesions in $\mu\text{m}$, pan/zoom controls, and Grad-CAM opacity sliders.
  2. **Hospital-Grade PDF Report Engine:** Develop the official A4 diagnostic PDF generator complying with NPCB&VI standards:
     - Institutional branding & logo header.
     - **Quad-Image diagnostic panel** (Raw Fundus, Enhanced CLAHE, Grad-CAM Saliency, Lesion Bounding Boxes).
     - Attending doctor observations box and physician signature lines.
  3. **ABDM FHIR R4 Integration:** Program the JSON export engine conforming to Ayushman Bharat Digital Mission schemas (`DiagnosticReport` and `Observation` resources mapped to SNOMED-CT and LOINC codes).
  4. **Multi-Format Export Hub:** Implement export pipelines for 200 DPI PNG summary cards, MATLAB `.mat` data archives, and district referral CSV rosters.
  5. **Master Orchestration & System Testing:** Maintain `main.m` as the unified entry driver and build stress test suites to ensure system stability under zero-byte files, extreme lighting (0/255 lux), and non-square images.

---

## 5. Technical Approach & Detailed Methodology

### Phase 1: Data Preprocessing & Mathematical Quality Assurance
```
Raw Fundus Image ──► [Color Extraction] ──► [Masking] ──► [Laplacian Blur Score]
                                                       ──► [4-Quadrant Illumination]
                                                       ──► [RMS Contrast]
                                                       ──► [Immerkaer Noise]
                                                       ──► [Tenengrad Sharpness]
                                                                  │
                                   Verdict: Good / Needs Enhancement / Retake
```
- **Modified Laplacian Variance:** Evaluates high-frequency spatial gradients to detect out-of-focus captures.
- **Illumination Uniformity:** Computes mean luminance across 4 concentric quadrants; flags uneven flash or peripheral shadowing.
- **$L^*a^*b^*$ CLAHE Enhancement:** The RGB image is converted to the CIE $L^*a^*b^*$ color space. CLAHE is applied exclusively to the $L^*$ channel with a Rayleigh distribution, enhancing contrast while keeping vascular hue intact.

### Phase 2: Deep Transfer Learning & Training Architecture
```
Input Image (224x224x3) ──► [ResNet-50 / MobileNetV2 Backbone] ──► [GAP Layer]
                                                                        │
                                                                 [Dropout (0.40)]
                                                                        │
                                                                 [Dense Layer (5)]
                                                                        │
                                                                 [Softmax Output]
```
- **Backbone Selection:** ResNet-50 is selected for its deep residual representations ($25.6\text{M}$ params), while MobileNetV2 is selected for low-power edge execution ($3.5\text{M}$ params).
- **Network Surgery:** Excises the ImageNet 1000-class dense layer and attaches Global Average Pooling, Dropout ($0.40$), and a 5-unit Softmax head corresponding to ICDR Grades 0 to 4.
- **Optimization:** Adam optimizer with piecewise learning rate step decay ($\gamma = 0.1$ every 10 epochs) and early stopping tracking validation loss to prevent overfitting on clinical training data.

### Phase 3: Explainable AI (Grad-CAM) & Anatomical Pathology Localization
- **Gradient Backpropagation:** Feature activations from the final convolutional layer are multiplied by pooled class gradients to generate a spatial importance map.
- **Lesion Segmentation:** Otsu adaptive thresholding and connected component labeling (`bwconncomp`) are applied to the saliency map to draw bounding boxes around pathology clusters.
- **Quadrant Mapping:** Saliency centroids are mapped into 5 anatomical zones:
  - Superotemporal (ST), Superonasal (SN), Inferotemporal (IT), Inferonasal (IN), and Macular.

### Phase 4: Clinical Interface & National Standards Integration
- **App Designer Workstation:** Designed for non-specialist community health workers (ASHAs) with simplified workflows, prominent triage alerts, and measurement calipers.
- **ABDM FHIR R4 Export:** Generates standardized JSON records mapped to LOINC (`LP200057-0`) and SNOMED-CT codes for seamless synchronization with the Ayushman Bharat Digital Mission EHR gateway.
- **Queueing Simulation:** Discrete-event models simulate patient queues across registration, camera acquisition, and tele-ophthalmologist review to optimize camp throughput.

---

## 6. Project Work Plan & Gantt Milestones

```
┌───────────────────────────┬────────────┬────────────┬────────────┬────────────┐
│ Planned Development Phase │ Month 1    │ Month 2    │ Month 3    │ Month 4    │
├───────────────────────────┼────────────┼────────────┼────────────┼────────────┤
│ Phase 1: Ingestion & IQA  │ [████████] │            │            │            │
│ Phase 2: CLAHE & Preproc  │   [██████] │            │            │            │
│ Phase 3: CNN & Training   │            │ [████████] │            │            │
│ Phase 4: Inference & XAI  │            │   [██████] │ [██████]   │            │
│ Phase 5: GUI Workstation  │            │            │ [████████] │            │
│ Phase 6: Reports & ABDM   │            │            │   [██████] │ [████]     │
│ Phase 7: Validation & DES │            │            │            │ [████████] │
└───────────────────────────┴────────────┴────────────┴────────────┴────────────┘
```

- **Milestone 1 (Month 1):** Ingestion of APTOS/EyePACS datasets, synthetic generator, and mathematical formulation of the 5-metric IQA gatekeeper.
- **Milestone 2 (Month 2):** $L^*a^*b^*$ CLAHE enhancement pipeline, CNN backbone construction, and training loop implementation with Adam and early stopping.
- **Milestone 3 (Month 3):** Grad-CAM explainability engine, lesion segmentation, and 18-screen App Designer GUI workstation development.
- **Milestone 4 (Month 4):** A4 PDF report generator, ABDM FHIR JSON export hub, discrete-event Simulink camp queue simulation, and clinical statistical validation ($\kappa_w \ge 0.90$).

---

## 7. Expected Deliverables & Impact

Upon completion, the project will deliver:
1. **Fully Integrated MATLAB Application:** Executable both via an interactive 18-screen App Designer workstation and headless CLI (`main.m`).
2. **Clinical Validation Benchmark:** Target Quadratic Weighted Kappa $\kappa_w \ge 0.90$, Sensitivity $\ge 90\%$, Specificity $\ge 90\%$, and edge inference latency $< 50\text{ ms}$.
3. **Hospital-Grade Reporting Hub:** Automated A4 PDF reports and ABDM-compliant FHIR R4 JSON records.
4. **Operations Research Model:** Discrete-event queue simulation demonstrating community camp throughput and capacity optimization.
5. **Complete Documentation Suite:** System Design Document (SDD), Software Requirements Specification (SRS), Risk Analysis (FMEA), and User Guides.

---

*Submitted by the SIH26038 Engineering Project Team • Academic Year 2026*
