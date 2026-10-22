# PROJECT ROLES & SUBSYSTEM RESPONSIBILITIES

## Project: DRISHTI-AI (SIH26038)
### Explainable Edge-AI Retinal Screening System for Rural Health Centers
**Platform Architecture:** 100% Pure Python Ecosystem (PyTorch, OpenCV, NumPy, SciPy)  
**Primary Deep Learning Model:** ResNet-152 Deep Transfer Learning Backbone  
**Team Structure:** 6 Members (3 Machine Learning, 2 Data Science, 1 Full Stack)  
**Document Status:** Production-Aligned Python Architecture  

---

## 1. Executive Summary & Team Structure

To maintain strict accountability, modularity, and high velocity, the DRISHTI-AI engineering responsibilities are mapped across three complementary engineering domains:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              DRISHTI-AI TEAM MATRIX (6 MEMBERS)                             │
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

---

## 2. Detailed Member Role Profiles

```
========================================================================================
 MEMBER 1: SUBHAM PANIGRAHI (12312794) — DATA SCIENCE: DATASET INGESTION & IQA GATE
========================================================================================
```
### 🎯 Objective
Curate multi-benchmark retinal datasets and engineer the 5-parameter optical Image Quality Assessment (IQA) gatekeeper preventing degraded captures from reaching deep learning inference.

### 📂 Directory & File Ownership
- [`quality_assessment/assess_quality.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/quality_assessment/assess_quality.py)
- [`quality_assessment/compute_blur.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/quality_assessment/compute_blur.py)
- [`quality_assessment/compute_brightness.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/quality_assessment/compute_brightness.py)
- [`quality_assessment/compute_contrast.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/quality_assessment/compute_contrast.py)
- [`data/`](file:///c:/Users/Priyam/Desktop/AI/Capstone/data)

### 🛠️ Development Tasks
1. **Multi-Source Benchmark Ingestion:** Aggregate, clean, and standardize fundus photography records across APTOS-2019, EyePACS, IDRiD, and Messidor.
2. **Stratified Split & Class Balancing:** Implement 70% Train / 15% Validation / 15% Test partitioning preserving representation of rare clinical stages (Severe NPDR and Proliferative DR).
3. **Synthetic Image Generator:** Program procedural fundus image synthesis creating realistic synthetic retina disks, blood vessels, and optic discs for offline testing.
4. **5-Parameter IQA Algorithm Engine:** Implement mathematical optical quality estimators:
   - **Focus Blur:** Modified Laplacian Variance over masked retinal area.
   - **Illumination Uniformity:** 4-quadrant balance and mean brightness calculation.
   - **Vascular Contrast:** Root Mean Square (RMS) dynamic range contrast.
   - **Sensor Noise:** High-frequency noise standard deviation via Laplacian filtering.
   - **Edge Sharpness:** Tenengrad Sobel gradient energy accumulation.
5. **Quality Decision Classifier:** Combine individual scores into an overall score (0–100) and output a 3-category clinical verdict: `Good`, `Usable`, or `Retake Image`.

---

```
========================================================================================
 MEMBER 2: KONDURI MRUNAL (12316339) — DATA SCIENCE: RETINAL ENHANCEMENT & QUEUE SIMULATION
========================================================================================
```
### 🎯 Objective
Enhance retinal vascular contrast and subtle micro-lesions while mathematically modeling rural camp patient throughput and camera bottlenecks.

### 📂 Directory & File Ownership
- [`preprocessing/apply_clahe.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/apply_clahe.py)
- [`preprocessing/correct_illumination.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/correct_illumination.py)
- [`preprocessing/preprocess_pipeline.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/preprocess_pipeline.py)
- [`simulation/camp_queue_simulation.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/simulation/camp_queue_simulation.py)

### 🛠️ Development Tasks
1. **L*a*b* Preprocessing Pipeline:** Convert fundus images into L*a*b* color space to decouple pure brightness (the L* channel) from color hues (the a* and b* channels).
2. **CLAHE Enhancement:** Implement Contrast Limited Adaptive Histogram Equalization to highlight microaneurysms without over-amplifying background noise.
3. **Homomorphic Illumination Correction:** Correct background lighting falloff and non-uniform illumination gradients.
4. **Quantitative Validation Metrics:** Calculate objective fidelity metrics: Peak Signal-to-Noise Ratio (PSNR above 31.8 dB) and Structural Similarity Index (SSIM above 0.94).
5. **Camp Queue Discrete-Event Simulation:** Formulate Python Monte Carlo Poisson arrival queue models comparing 1-camera vs. 2-camera operational bottlenecks in an 8-hour rural screening camp.

---

```
========================================================================================
 MEMBER 3: RAJBARDHAN KUMAR (12326119) — MACHINE LEARNING: RESNET-152 ARCHITECTURE & TRAINING
========================================================================================
```
### 🎯 Objective
Architect, perform network surgery, and train transfer-learned convolutional neural networks centered on ResNet-152 for 5-class diabetic retinopathy severity staging.

### 📂 Directory & File Ownership
- [`classification/build_model.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/build_model.py)
- [`training/train_model.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/training/train_model.py)

### 🛠️ Development Tasks
1. **Model Backbone Library:** Construct transfer learning graphs centered on **ResNet-152** as primary architecture:
   - `resnet152`: Primary deep benchmark (152 residual bottleneck layers, ~60.2M parameters).
   - `resnet50` and `mobilenet_v2`: Lightweight options for constrained edge hardware.
2. **Custom Network Surgery:** Replace default ImageNet 1000-class heads with custom retinal classification heads:
   - Dropout layer ($p = 0.40$ deactivation rate to prevent clinical overfitting).
   - Fully connected linear layer with 5 output classes (`nn.Linear(2048, 5)`).
   - Softmax activation output.
3. **Layer Freezing Strategy:** Freeze early convolutional layers to preserve generic edge/texture weights; unfreeze `layer4` and classification head for domain adaptation.
4. **Training Optimization Engine:** Implement training loop using the AdamW optimizer (learning rate $10^{-4}$, weight decay $10^{-4}$), Weighted Cross-Entropy Loss to counter class imbalance, and StepLR/CosineAnnealing learning rate decay.

---

```
========================================================================================
 MEMBER 4: PRIYAM SAXENA (12313674) — MACHINE LEARNING: EDGE INFERENCE & CLINICAL VALIDATION
========================================================================================
```
### 🎯 Objective
Deploy deep learning models for sub-50ms inference on non-GPU edge laptops, program clinical triage logic, and validate statistical performance.

### 📂 Directory & File Ownership
- [`classification/predict_dr.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/predict_dr.py)
- [`classification/evaluate_metrics.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/evaluate_metrics.py)
- [`tests/test_python_suite.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/tests/test_python_suite.py)

### 🛠️ Development Tasks
1. **High-Speed Inference Engine:** Develop `predict_dr.py` accepting image arrays or paths, standardizing input shapes (224x224x3 pixels), running forward passes in under 50 milliseconds on standard non-GPU laptop CPUs, and extracting softmax confidence.
2. **Clinical Triage Decision Logic:** Program medical referral rules:
   - Stages 0–1 (No DR, Mild NPDR) → `Routine Annual Surveillance at Local PHC`.
   - Stage 2 (Moderate NPDR) → `Non-Urgent Tele-Ophthalmology Referral` (within 30 days).
   - Stage 3 (Severe NPDR) → `Priority District Hospital Referral` (within 7–14 days).
   - Stage 4 (Proliferative DR) → `Emergency Vitreoretinal Referral` (within 24–48 hours).
3. **Multi-Class Evaluation Engine:** Program statistical metrics:
   - 5x5 normalized confusion matrix.
   - **Cohen's Quadratic Weighted Kappa (target $\kappa_w \ge 0.90$)** penalizing distant clinical stage misclassifications.
   - Referable DR Sensitivity ($\ge 90\%$) and Specificity ($\ge 90\%$) for Stage 2 Moderate DR and higher.
4. **Automated Test Suite:** 12 unit tests verifying 100% passing across all Python modules.

---

```
========================================================================================
 MEMBER 5: KADAMBALA LIKHITH (12314034) — MACHINE LEARNING: EXPLAINABLE AI (XAI) & LESIONS
========================================================================================
```
### 🎯 Objective
Transform the black-box CNN into an interpretable clinical tool by computing Grad-CAM saliency heatmaps and localizing microvascular lesions.

### 📂 Directory & File Ownership
- [`explainability/grad_cam.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/grad_cam.py)

### 🛠️ Development Tasks
1. **Grad-CAM Algorithm:** Compute sensitivity gradients of the predicted class score with respect to feature activation maps of ResNet-152 `model.layer4`, pool gradient weights across feature channels, and filter through ReLU:
   $$\text{Grad-CAM Heatmap} = \text{ReLU}\left(\sum_{k} \alpha_k A^k\right)$$
2. **Smooth Heatmap Colormap Overlay:** Normalize activation maps to a 0–1 scale and blend them onto retinal images using colormap Jet with interactive opacity blending.
3. **Lesion Hotspot Localization:** Extract bounding coordinates surrounding microaneurysms, hemorrhages, and hard exudates.
4. **Clinical Natural-Language Justification:** Generate plain-language clinical narrative text for non-specialist health workers (ASHAs) explaining the biological rationale behind the AI's diagnosis.

---

```
========================================================================================
 MEMBER 6: VAIBHAV RAJ (12325142) — FULL STACK: WORKSTATION WEB UI, REPORTING HUB & INTEGRATION
========================================================================================
```
### 🎯 Objective
Develop the interactive Clinical Workstation Web UI, master CLI orchestrator, ABDM FHIR JSON export hub, and end-to-end integration.

### 📂 Directory & File Ownership
- [`app.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/app.py)
- [`main.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/main.py)
- [`reports/export_fhir.py`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/export_fhir.py)
- [`requirements.txt`](file:///c:/Users/Priyam/Desktop/AI/Capstone/requirements.txt)

### 🛠️ Development Tasks
1. **Interactive Clinical Workstation Web UI (`app.py`):** Implement the complete browser workstation:
   - Drag-and-drop and file-picker retinal fundus image upload.
   - 1-click clinical benchmark sample loader (Stages 0 to 4).
   - Real-time optical Image Quality Assessment gauges.
   - Animated 5-stage softmax probability distribution bars.
   - Interactive Grad-CAM heatmap opacity slider.
   - Patient demographic form and print-optimized PDF styling.
2. **Master Orchestrator CLI (`main.py`):** Unified execution driver supporting modes: `--mode ui`, `--mode predict`, `--mode quality`, `--mode simulate`, and `--mode fhir`.
3. **Healthcare Standards Integration (ABDM FHIR R4):** Build the automated JSON exporter adhering to Ayushman Bharat Digital Mission schemas (`DiagnosticReport` and `Observation` resources mapped to SNOMED-CT and LOINC codes).
4. **Packaging & Dependency Management:** Maintain locked `requirements.txt` ensuring zero-dependency local browser workstation execution.

---

## 3. Verification & Execution Standards

To maintain high software engineering standards, all modules are verified through:
1. **Automated Unit Testing:**
   ```bash
   python tests/test_python_suite.py
   ```
   *Requirement: 12/12 tests passing (100% OK).*
2. **Interactive Clinical Workstation Execution:**
   ```bash
   python app.py
   # or
   python main.py --mode ui
   ```
   *Requirement: Launches local workstation at `http://localhost:5050` with drag-and-drop analysis.*
3. **Headless CLI Verification:**
   ```bash
   python main.py --mode predict --image data/raw/aptos/aptos_02_1.png
   python main.py --mode quality --image data/raw/aptos/aptos_02_1.png
   python main.py --mode simulate --cameras 2
   python main.py --mode fhir --patient PAT-2026-0042
   ```

---

*Authored by the SIH26038 Engineering Architecture Team • Academic Year 2026*
