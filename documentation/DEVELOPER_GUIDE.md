# Developer & API Reference Guide
## Explainable AI-Based Diabetic Retinopathy Screening System for Rural India
### Project Code: SIH26038 | Version: 1.0.0-Production | Date: September 2026

---

## 1. Architectural Principles & Coding Standards

The **SIH26038** codebase adheres to strict software engineering standards designed for high reliability and clinical compliance:
1. **Separation of Concerns**: UI components (`gui/`) never execute deep learning or raw image operations directly; all business logic resides in decoupled domain modules (`qualityAssessment/`, `preprocessing/`, `classification/`, `explainability/`, `reports/`, `simulink/`).
2. **Defensive Programming**: Every function validates inputs using `validateattributes`, provides fallbacks, and logs execution stages via `logger.m`.
3. **Reproducibility**: All random operations (Poisson generators, stochastic augmenters, dropout) use deterministic seeds (`rng(seed)`).
4. **Cross-Platform Compatibility**: All file paths use `fullfile()` and resolve dynamically via `getProjectRoot()`.

---

## 2. Core API Reference

### 2.1 Quality Assessment API (`qualityAssessment/`)

#### `assessImageQuality(img, config)`
Evaluates 5 optical quality factors on a 3-channel RGB retinal fundus photograph.
- **Inputs**:
  - `img`: `uint8` array of size $[H \times W \times 3]$.
  - `config`: (Optional) configuration struct loaded via `loadConfig()`.
- **Outputs**:
  - `qReport`: Struct containing:
    - `.overallScore`: Composite quality score in $[0.0, 1.0]$.
    - `.category`: String verdict: `'Good'`, `'Needs Enhancement'`, or `'Retake Image'`.
    - `.metrics`: Sub-struct with `.blur`, `.brightness`, `.contrast`, `.sharpness`, `.noise`.
    - `.recommendation`: String containing clinical operator guidance.

---

### 2.2 Preprocessing & CLAHE API (`preprocessing/`)

#### `preprocessPipeline(img, config)`
Applies illumination leveling, green channel isolation, adaptive CLAHE, and median filtering.
- **Inputs**:
  - `img`: `uint8` array of size $[H \times W \times 3]$.
  - `config`: System configuration struct.
- **Outputs**:
  - `enhancedResult`: Struct containing:
    - `.enhancedImage`: Processed `uint8` fundus photograph.
    - `.metrics`: Sub-struct with `.psnr`, `.ssim`, `.contrastRatio`.

---

### 2.3 Deep Learning Inference API (`classification/`)

#### `predictDR(img, model, config)`
Performs 5-stage International Clinical Diabetic Retinopathy classification.
- **Inputs**:
  - `img`: `uint8` enhanced fundus image.
  - `model`: (Optional) loaded `dlnetwork` object. If empty, loads checkpoint or runs verified feature heuristic fallback.
  - `config`: Configuration struct.
- **Outputs**:
  - `predResult`: Struct containing:
    - `.predictedClass`: Integer $0, 1, 2, 3, 4$.
    - `.className`: String (e.g. `'Stage 3 - Severe NPDR'`).
    - `.confidence`: Float in $[0.0, 1.0]$.
    - `.classProbabilities`: $1 \times 5$ normalized vector summing to $1.0$.
    - `.referralRecommended`: Boolean (`true` if stage $\ge 2$).
    - `.urgencyLevel`: String triage directive.
    - `.inferenceTimeMs`: Inference duration in milliseconds.

---

### 2.4 Explainable AI (Grad-CAM) API (`explainability/`)

#### `computeGradCAM(model, img, classIdx, config)`
Computes class activation gradients on the final convolutional layer.
- **Inputs**:
  - `model`: Neural network or `[]`.
  - `img`: `uint8` image array.
  - `classIdx`: Target class index ($0-4$).
  - `config`: Configuration struct.
- **Outputs**:
  - `xaiResult`: Struct containing:
    - `.saliencyMap`: Normalized 2D float array in $[0.0, 1.0]$.
    - `.overlay`: $H \times W \times 3$ uint8 image blended with Jet colormap.
    - `.activationAreaPercent`: Percentage of retinal area flagged as salient.

---

### 2.5 Clinical Reporting API (`reports/`)

#### `generatePatientReport(patient, quality, pred, xai, config)`
Assembles clinical screening report.
- **Outputs**:
  - `reportResult`: Aggregated clinical document struct.

#### `exportReportPDF(reportResult, config)`
Renders and exports publication-grade A4 PDF document.
- **Outputs**:
  - `pdfPath`: Absolute file path to exported PDF.

---

## 3. Extending the System

### 3.1 Adding a New Deep Learning Backbone
To add a new network architecture (e.g., `Swin-Transformer` or `EfficientNet-B4`):
1. Open [`classification/buildModel.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/buildModel.m).
2. Add a new branch in the `switch lower(arch)` block:
   ```matlab
   case 'swin_tiny'
       lgraph = swinTransformerTinyLayers([224, 224, 3], numClasses);
   ```
3. Update `config/default_config.json` under `"model"."supported_architectures"`.
4. Run `testing/TestModelClassification.m` to verify automated compliance.

### 3.2 Adding a Custom Image Quality Filter
To add a new quality metric (e.g., Glare Reflection Area Index):
1. Create `qualityAssessment/computeGlare.m`.
2. Integrate the metric into `qualityAssessment/assessImageQuality.m`:
   ```matlab
   metrics.glare = computeGlare(grayImg);
   ```
3. Add a unit test method in `testing/TestQualityAssessment.m`.

---

## 4. Running Static Analysis & Verification

Always execute the automated static analyzer before submitting changes:
```cmd
python test_syntax_and_integrity.py
```
And execute the master test suite inside MATLAB:
```matlab
main('test')
```
