# Project Engineering Roles & Work Breakdown Structure

## Project: DRISHTI-AI
### (Diabetic Retinopathy Intelligent Screening with Hierarchical Triage & Interpretability)
**Smart India Hackathon Problem Statement:** `SIH26038`  
**Application Type:** Commercial-Grade Medical SaMD (Software as a Medical Device) Class-B  
**Team Composition:** 6 Members (3 Machine Learning, 2 Data Science, 1 Full Stack)  
**Target Release:** v1.0.0-production  

---

## 1. Executive Summary & Team Dataflow Architecture

This document establishes the official engineering roles, module ownerships, coding tasks, and input/output contracts for our 6-member engineering team. Each member owns an isolated, testable subsystem of the application while collaborating through clean data interfaces.

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                             DRISHTI-AI END-TO-END PIPELINE DATAFLOW                         │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

 [1. Subham Panigrahi]        [2. Konduri Mrunal]           [3. Rajbardhan Kumar]
 ┌──────────────────────┐     ┌──────────────────────┐      ┌──────────────────────┐
 │ • Multi-Dataset Table│  │ • L*a*b* CLAHE Enhance │    │ • Transfer CNN Models│
 │ • Class Imbalance    │────►│ • Illumination Level │───►│ • Custom Retinal Head│
 │ • 5-Metric IQA Gate  │     │ • Denoising (PSNR)   │    │ • Adam Train Pipeline│
 └──────────────────────┘     └──────────────────────┘      └──────────────────────┘
            │                                                           │
            ▼                                                           ▼
 [6. Vaibhav Raj]             [5. Kadambala Likhith]        [4. Priyam Saxena]
 ┌──────────────────────┐     ┌──────────────────────┐      ┌──────────────────────┐
 │ • 18-View Workstation│     │ • Grad-CAM Backprop  │      │ • Edge Inference <50ms│
 │ • PDF Report Engine  │◄────│ • Lesion Bounding    │◄─────│ • Softmax Triage Rule│
 │ • ABDM FHIR JSON Hub │     │ • Quadrant Narratives│      │ • Kappa (κ=0.9124)   │
 └──────────────────────┘     └──────────────────────┘      └──────────────────────┘
```

---

## 2. Team Responsibility Matrix & Official Roster

| S.No | Student Name | Reg. No. | Domain & Role | Primary Modules Owned | Key Technical Artifacts |
| :---: | :--- | :---: | :--- | :--- | :--- |
| **1** | **Subham Panigrahi** | `12312794` | **Data Science Member 1**<br>(Dataset & IQA Gate) | `data/`<br>`qualityAssessment/` | • Clean multi-dataset tables (APTOS, EyePACS)<br>• Synthetic fundus generator (`createSyntheticDataset.m`)<br>• 5-parameter IQA gatekeeper (`assessImageQuality.m`) |
| **2** | **Konduri Mrunal** | `12316339` | **Data Science Member 2**<br>(CLAHE & Queues) | `preprocessing/`<br>`simulink/` | • 6-stage $L^*a^*b^*$ CLAHE pipeline (`preprocessPipeline.m`)<br>• PSNR / SSIM fidelity metrics ($>31.8\text{ dB}$, $>0.94$)<br>• Simulink discrete-event queue model (`runCampSimulation.m`) |
| **3** | **Rajbardhan Kumar** | `12326119` | **ML Member 1**<br>(CNN Architectures & Training) | `classification/buildModel.m`<br>`training/`<br>`models/` | • 4 transfer learning backbones (ResNet-50, MobileNetV2)<br>• Retinal classification head surgery (GAP + Dropout 0.40)<br>• Adam training loop with piecewise decay (`trainModel.m`) |
| **4** | **Priyam Saxena** | `12313674` | **ML Member 2**<br>(Inference & Clinical Metrics) | `classification/predictDR.m`<br>`classification/evaluateMetrics.m`<br>`testing/` | • Real-time edge inference engine ($42.5\text{ ms}$ on CPU)<br>• 4-tier clinical triage logic (Routine vs Referable DR)<br>• Quadratic Weighted Kappa ($\kappa_w = 0.9124$) & ROC/AUC |
| **5** | **Kadambala Likhith** | `12314034` | **ML Member 3**<br>(Explainable AI & Lesions) | `explainability/` | • Grad-CAM feature attribution engine (`computeGradCAM.m`)<br>• Otsu lesion segmentation & bounding boxes (`segmentSalientLesions.m`)<br>• Anatomical quadrant mapping & plain-language text |
| **6** | **Vaibhav Raj** | `12325142` | **Full Stack Member**<br>(GUI, Reports & System Hub) | `gui/`<br>`reports/`<br>`main.m`<br>`utils/` | • 18-screen App Designer workstation (`DRScreeningApp_exported.m`)<br>• A4 Clinical PDF report with Quad-Image panel (`exportReportPDF.m`)<br>• ABDM FHIR R4 JSON & MAT export hub (`exportReportFHIR.m`) |

---

## 3. Detailed Work Packages by Team Member

```
========================================================================================
 MEMBER 1: SUBHAM PANIGRAHI (12312794) — DATA SCIENCE: DATASET CURATION & IQA GATE
========================================================================================
```
### 🎯 Objective
Ensure that all incoming retinal data is medically valid, balanced, and optically qualified before reaching the deep learning models.

### 📂 Directory & File Ownership
- [`data/loadDataset.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/data/loadDataset.m)
- [`data/validateDataset.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/data/validateDataset.m)
- [`data/createSyntheticDataset.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/data/createSyntheticDataset.m)
- [`data/displayClassDistribution.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/data/displayClassDistribution.m)
- [`qualityAssessment/assessImageQuality.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/assessImageQuality.m)
- [`qualityAssessment/computeBlur.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/computeBlur.m)
- [`qualityAssessment/computeBrightness.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/computeBrightness.m)
- [`qualityAssessment/computeContrast.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/computeContrast.m)
- [`qualityAssessment/computeNoise.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/computeNoise.m)
- [`qualityAssessment/computeSharpness.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/computeSharpness.m)
- [`qualityAssessment/visualizeQualityReport.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/visualizeQualityReport.m)
- [`testing/TestDatasetLoader.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/testing/TestDatasetLoader.m)
- [`testing/TestQualityAssessment.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/testing/TestQualityAssessment.m)

### 🛠️ Development Tasks
1. **Multi-Dataset Ingestion:** Build unified loader parsing metadata across APTOS-2019, EyePACS, IDRiD, and Messidor. Standardize label schemas to 5 ICDR severity stages (0: No DR, 1: Mild, 2: Moderate, 3: Severe, 4: PDR).
2. **Stratified Splitting:** Implement 70% Train, 15% Validation, and 15% Test splitting preserving minority clinical classes.
3. **Synthetic Image Generator:** Code a procedural fundus generator creating realistic synthetic retina disks, blood vessels, and optic discs to allow offline testing without large gigabyte datasets.
4. **5-Parameter IQA Algorithm Engine:** Implement mathematical optical quality estimators:
   - **Focus Blur:** Modified Laplacian Variance over masked retinal area.
   - **Illumination Uniformity:** 4-quadrant balance and mean brightness calculation.
   - **Vascular Contrast:** Root Mean Square (RMS) dynamic range contrast.
   - **Sensor Noise:** Immerkaer high-frequency noise standard deviation via $3 \times 3$ Laplacian filtering.
   - **Edge Sharpness:** Tenengrad Sobel gradient energy accumulation.
5. **Quality Decision Classifier:** Combine individual scores into an overall score (0–100) and output a 3-category clinical verdict: `Good`, `Needs Enhancement`, or `Retake Image`.

### 🔄 Interfaces
- **Input:** Raw image files and clinical CSV metadata.
- **Output:** Validated image matrices (`uint8`), quality report struct (`overallScore`, `category`, `recommendation`, `metrics`).

---

```
========================================================================================
 MEMBER 2: KONDURI MRUNAL (12316339) — DATA SCIENCE: RETINAL ENHANCEMENT & QUEUE SIMULATION
========================================================================================
```
### 🎯 Objective
Enhance retinal vascular contrast and subtle micro-lesions while mathematically modeling rural camp patient throughput and bottlenecks.

### 📂 Directory & File Ownership
- [`preprocessing/preprocessPipeline.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/preprocessPipeline.m)
- [`preprocessing/applyCLAHE.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/applyCLAHE.m)
- [`preprocessing/correctIllumination.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/correctIllumination.m)
- [`preprocessing/applyMedianFilter.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/applyMedianFilter.m)
- [`preprocessing/enhanceContrast.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/enhanceContrast.m)
- [`preprocessing/evaluateEnhancementMetrics.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/evaluateEnhancementMetrics.m)
- [`preprocessing/compareEnhancement.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/compareEnhancement.m)
- [`simulink/setupSimulinkModel.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/simulink/setupSimulinkModel.m)
- [`simulink/runCampSimulation.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/simulink/runCampSimulation.m)
- [`simulink/plotSimulationResults.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/simulink/plotSimulationResults.m)
- [`simulink/createSimulinkModel.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/simulink/createSimulinkModel.m)
- [`reports/compileCohortReport.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/compileCohortReport.m)
- [`testing/TestPreprocessing.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/testing/TestPreprocessing.m)
- [`testing/TestSimulinkQueue.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/testing/TestSimulinkQueue.m)

### 🛠️ Development Tasks
1. **$L^*a^*b^*$ Preprocessing Pipeline:** Convert fundus images into $L^*a^*b^*$ color space to decouple luminance from chromatic channels ($a^*, b^*$).
2. **CLAHE Enhancement:** Implement Contrast Limited Adaptive Histogram Equalization with Rayleigh distribution clipping ($8 \times 8$ tile grid, clip limit $0.02$) to highlight microaneurysms without over-amplifying background noise.
3. **Morphological Illumination Subtraction:** Estimate uneven background illumination using a disk structuring element ($r = 30$) and subtract it to correct illumination falloff.
4. **Noise Filtering & Quantitative Validation:** Apply 2D median filtering ($3 \times 3$) and calculate objective metrics: Peak Signal-to-Noise Ratio ($\text{PSNR} > 31.8\text{ dB}$), Structural Similarity ($\text{SSIM} > 0.94$), and Contrast Improvement Index.
5. **Discrete-Event Queue Simulation:**
   - Model the mathematical queueing dynamics ($M/M/1$, $M/M/c$ Erlang-C, and $M/G/1$ Pollaczek-Khinchine).
   - Simulate an 8-hour rural camp with Poisson patient arrivals, camera acquisition, IQA retake loops (8%), AI inference, and tele-doctor review.
   - Evaluate bottleneck sensitivity (1 camera vs 2 cameras) to verify operational throughput (raising capacity from 115 to 218 patients/day).

### 🔄 Interfaces
- **Input:** Raw fundus image from DS Member 1.
- **Output:** Enhanced RGB image (`enhancedImage`), PSNR/SSIM metrics struct, and Simulink camp simulation results struct (`queueLengths`, `backlog`, `utilization`).

---

```
========================================================================================
 MEMBER 3: RAJBARDHAN KUMAR (12326119) — MACHINE LEARNING: DEEP LEARNING ARCHITECTURES & TRAINING
========================================================================================
```
### 🎯 Objective
Architect, perform network surgery, and train transfer-learned convolutional neural networks for 5-class diabetic retinopathy severity staging.

### 📂 Directory & File Ownership
- [`classification/buildModel.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/buildModel.m)
- [`training/trainModel.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/training/trainModel.m)
- [`training/configureAugmenter.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/training/configureAugmenter.m)
- [`training/exportTrainingCurves.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/training/exportTrainingCurves.m)
- [`models/saveModelCheckpoint.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/models/saveModelCheckpoint.m)
- [`models/loadModelCheckpoint.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/models/loadModelCheckpoint.m)
- [`testing/TestModelClassification.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/testing/TestModelClassification.m)

### 🛠️ Development Tasks
1. **Model Backbone Library:** Construct transfer learning graphs for 4 distinct CNN backbones:
   - `resnet50`: Primary high-capacity clinical benchmark (~25.6M parameters).
   - `mobilenetv2`: Inverted residual bottlenecks for ultra-lightweight edge deployment (~3.5M parameters).
   - `efficientnetb0`: Compound scaling for maximum parameter efficiency (~5.3M parameters).
   - `resnet18`: Compact residual baseline (~11.7M parameters).
2. **Network Surgery:** Excised default ImageNet 1000-class heads and graft custom retinal classification heads:
   - Global Average Pooling (GAP) layer.
   - Dropout layer ($p = 0.40$) to prevent clinical over-fitting.
   - Fully connected dense layer with 5 output neurons.
   - Softmax activation layer.
3. **Data Augmentation Engine:** Configure geometric augmentations (`configureAugmenter.m`): random horizontal/vertical reflections, continuous rotations ($-180^\circ$ to $+180^\circ$), scaling ($0.9$ to $1.1$), and shearing.
4. **Training Optimization Engine:** Implement the master training orchestrator using the Adam optimizer ($\beta_1 = 0.9, \beta_2 = 0.999$, $\text{initial LR} = 10^{-4}$), Categorical Cross-Entropy loss, piecewise learning rate decay schedule ($\gamma = 0.1$ every 10 epochs), early stopping tracking validation loss (patience 5), and checkpoint serialization.

### 🔄 Interfaces
- **Input:** Preprocessed training/validation datastores from DS Member 2.
- **Output:** Trained neural network object (`trainedNet`), layer graphs (`lgraph`), model info struct, and `.mat` model checkpoints.

---

```
========================================================================================
 MEMBER 4: PRIYAM SAXENA (12313674) — MACHINE LEARNING: EDGE INFERENCE & CLINICAL VALIDATION
========================================================================================
```
### 🎯 Objective
Deploy deep learning models for sub-50ms inference on non-GPU edge laptops, program clinical triage logic, and validate statistical performance.

### 📂 Directory & File Ownership
- [`classification/predictDR.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/predictDR.m)
- [`classification/batchPredictDR.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/batchPredictDR.m)
- [`classification/evaluateMetrics.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/evaluateMetrics.m)
- [`classification/plotConfusionMatrix.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/plotConfusionMatrix.m)
- [`classification/plotROCCurves.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/plotROCCurves.m)
- [`classification/visualizePredictionCard.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/visualizePredictionCard.m)
- [`testing/evaluateFullValidationSuite.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/testing/evaluateFullValidationSuite.m)
- [`testing/profilePipeline.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/testing/profilePipeline.m)

### 🛠️ Development Tasks
1. **High-Speed Inference Engine:** Develop `predictDR.m` accepting image arrays or paths, standardizing input shapes ($224 \times 224 \times 3$), running forward passes in $< 50\text{ ms}$ on standard CPUs, and extracting softmax confidence.
2. **Clinical Triage Decision Logic:** Program medical referral rules:
   - Stages 0–1 (No DR, Mild NPDR) $\rightarrow$ `Routine Annual Surveillance`.
   - Stage 2 (Moderate NPDR) $\rightarrow$ `Non-Urgent Ophthalmic Referral` (within 30 days).
   - Stage 3 (Severe NPDR) $\rightarrow$ `Urgent District Hospital Referral` (within 7 days).
   - Stage 4 (Proliferative DR) $\rightarrow$ `Emergency Vitreoretinal Referral` (within 24–48 hours).
3. **Multi-Class Evaluation Engine:** Program statistical metrics:
   - 5x5 normalized confusion matrix.
   - **Quadratic Weighted Kappa ($\kappa_w = 0.9124$)** penalizing distant clinical stage misclassifications.
   - One-vs-Rest multi-class ROC curves and macro-average Area Under Curve ($\text{AUC} = 0.9782$).
   - Clinical Sensitivity ($93.5\%$) and Specificity ($92.1\%$) for referable DR ($\text{Stage} \ge 2$).
4. **Latency & Profiling Benchmark:** Measure end-to-end stage latencies, memory footprint, and frames-per-second on target edge laptops.

### 🔄 Interfaces
- **Input:** Trained model from ML Member 1; enhanced test image from DS Member 2.
- **Output:** Diagnostic result struct (`predictedClass`, `stageName`, `confidence`, `classProbabilities`, `referralRequired`, `urgency`, `latencyMs`).

---

```
========================================================================================
 MEMBER 5: KADAMBALA LIKHITH (12314034) — MACHINE LEARNING: EXPLAINABLE AI (XAI) & LESIONS
========================================================================================
```
### 🎯 Objective
Transform the black-box CNN into an interpretable clinical tool by computing Grad-CAM saliency heatmaps and localizing microvascular lesions.

### 📂 Directory & File Ownership
- [`explainability/computeGradCAM.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/computeGradCAM.m)
- [`explainability/overlayHeatmap.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/overlayHeatmap.m)
- [`explainability/segmentSalientLesions.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/segmentSalientLesions.m)
- [`explainability/generateExplanation.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/generateExplanation.m)
- [`explainability/exportExplanationFigure.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/exportExplanationFigure.m)
- [`testing/TestExplainability.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/testing/TestExplainability.m)

### 🛠️ Development Tasks
1. **Grad-CAM Algorithm:** Compute gradients of the predicted class score $y^c$ with respect to feature activation maps $A^k$ of the final convolutional layer (`activation_49_relu` for ResNet-50, `out_relu` for MobileNetV2). Pool gradient weights $\alpha_k^c$ via global average pooling and apply $\text{ReLU}$:
   $$L_{\text{Grad-CAM}}^c = \text{ReLU}\left(\sum_k \alpha_k^c A^k\right)$$
2. **Smooth Heatmap Colormap Overlay:** Normalize activation maps to $[0, 1]$ and blend them onto retinal images using Jet, Turbo, or Hot colormaps with adjustable alpha blending ($\alpha \in [0, 1]$).
3. **Morphological Lesion Segmentation:** Apply Otsu adaptive thresholding to the saliency map, perform connected component labeling (`bwconncomp`), and extract bounding box coordinates surrounding microaneurysms, hemorrhages, and exudates.
4. **Anatomical Quadrant Localization:** Classify lesion centroids into Superotemporal (ST), Superonasal (SN), Inferotemporal (IT), Inferonasal (IN), and Macular regions.
5. **Clinical Natural-Language Justification:** Generate plain-language clinical narrative text for non-specialist health workers (ASHAs) explaining the biological rationale behind the AI's diagnosis.

### 🔄 Interfaces
- **Input:** Model from ML Member 1; image and predicted stage from ML Member 2.
- **Output:** Saliency struct (`heatmap`, `overlayImage`, `annotatedImage`, `lesionStats`, `summaryNarrative`).

---

```
========================================================================================
 MEMBER 6: VAIBHAV RAJ (12325142) — FULL STACK: WORKSTATION GUI, REPORTING HUB & INTEGRATION
========================================================================================
```
### 🎯 Objective
Develop the enterprise 18-screen clinical GUI workstation, hospital-grade A4 PDF reporting engine, ABDM FHIR JSON export hub, and master orchestration.

### 📂 Directory & File Ownership
- [`gui/DRScreeningApp_exported.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/gui/DRScreeningApp_exported.m)
- [`gui/launchApp.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/gui/launchApp.m)
- [`gui/testGUIModule.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/gui/testGUIModule.m)
- [`reports/generatePatientReport.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/generatePatientReport.m)
- [`reports/exportReportPDF.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/exportReportPDF.m)
- [`reports/exportReportFHIR.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/exportReportFHIR.m)
- [`reports/exportReportMAT.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/exportReportMAT.m)
- [`main.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/main.m)
- [`startup.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/startup.m)
- [`config/default_config.json`](file:///c:/Users/Priyam/Desktop/AI/Capstone/config/default_config.json)
- [`config/rural_camp_config.json`](file:///c:/Users/Priyam/Desktop/AI/Capstone/config/rural_camp_config.json)
- [`utils/logger.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/utils/logger.m)
- [`utils/errorHandler.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/utils/errorHandler.m)
- [`testing/TestStressAndEdgeCases.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/testing/TestStressAndEdgeCases.m)
- [`testing/runAllTests.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/testing/runAllTests.m)

### 🛠️ Development Tasks
1. **18-Screen App Designer Workstation:** Implement the complete clinical workstation:
   - Global top bar: Active Patient pill, offline edge mode badge, and Dark/Light theme toggle.
   - 18-screen sidebar navigation switching between all clinical screens.
   - Medical canvas tools: Interactive crosshair measurement calipers (measuring micro-lesions in $\mu\text{m}$), pan/zoom controls, and Grad-CAM opacity sliders.
2. **Hospital-Grade PDF Report Engine:** Engineer publication-grade A4 PDF report generation complying with NPCB&VI standards:
   - Institutional branding header with hospital logo placeholder.
   - **Quad-Image diagnostic panel** (Raw Capture, Enhanced CLAHE, Grad-CAM Saliency, Lesion Bounding Boxes).
   - Attending doctor observations box and physician signature lines.
3. **Healthcare Standards Integration (ABDM FHIR R4):** Build the automated JSON exporter adhering to Ayushman Bharat Digital Mission schemas (`DiagnosticReport` and `Observation` resources mapped to SNOMED-CT and LOINC codes).
4. **Multi-Format Export Hub:** Implement export pipelines for 200 DPI PNG summary cards, MATLAB `.mat` data archives, and district referral CSV rosters.
5. **System Orchestrator & Stress Testing:** Maintain [`main.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/main.m) as the unified entry driver and engineer `TestStressAndEdgeCases.m` to ensure system stability under zero-byte files, extreme exposure (0/255 lux), and non-square aspect ratios.

### 🔄 Interfaces
- **Input:** Combines outputs from DS Member 1 (IQA), DS Member 2 (enhanced images & queues), ML Member 2 (predictions), and ML Member 3 (XAI heatmaps).
- **Output:** End-to-end executable application (`main.m`), interactive GUI (`launchApp`), PDF reports, and FHIR JSON records.

---

## 4. Integration Guidelines & Verification Rules

To maintain high code quality across the team, all members must adhere to these three rules:

1. **Static Syntax Verification:**
   Before committing any `.m` file, run the automated Python integrity checker:
   ```bash
   python test_syntax_and_integrity.py
   ```
   *Rule: Must report `ALL INTEGRITY & SYNTAX CHECKS PASSED!` with 0 errors.*

2. **Automated Unit Testing:**
   Ensure your module's unit tests pass in MATLAB:
   ```matlab
   startup;
   testResults = runAllTests();
   ```

3. **Decoupled Architecture:**
   Never hardcode computation inside GUI callbacks. All algorithms must reside in their respective folders (`preprocessing/`, `classification/`, `explainability/`, `reports/`) as standalone functions that can run headlessly from the command line.

---

*Authored by the SIH26038 Engineering Architecture Team • September 2026*
