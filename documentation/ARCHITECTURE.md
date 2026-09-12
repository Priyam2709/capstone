# System Architecture: Explainable AI-Based Diabetic Retinopathy Screening System

**Smart India Hackathon Problem Statement:** SIH26038  
**System Designation:** Rural PHC Autonomous & Semi-Autonomous Retinal Diagnostic Pipeline

---

## 1. Modular Architectural Overview

The system is architected into 12 decoupled, production-grade subsystems designed for deployment on edge laptops and low-resource mobile health vans in rural India.

```mermaid
graph TB
    subgraph Ingestion ["1. Data Ingestion & I/O"]
        RAW["Raw Retinal Image\n(APTOS, EyePACS, IDRiD, Camera)"]
        CFG["JSON Configuration\n(default_config.json)"]
        LOADER["utils/loadImage.m\n(Auto-crop, RGB norm, Resize)"]
    end

    subgraph QualityControl ["2. Image Quality Assessment (IQA)"]
        IQA["qualityAssessment/assessImageQuality.m"]
        BLUR["computeBlur.m\n(Laplacian Var)"]
        BRIGHT["computeBrightness.m\n(Luminance Mask)"]
        CONTRAST["computeContrast.m\n(RMS Contrast)"]
        NOISE["computeNoise.m\n(Immerkaer Std)"]
        SHARP["computeSharpness.m\n(Tenengrad Energy)"]
        IQA --> BLUR & BRIGHT & CONTRAST & NOISE & SHARP
    end

    subgraph Enhancement ["3. Preprocessing & Retinal Enhancement"]
        PRE["preprocessing/preprocessPipeline.m"]
        MED["applyMedianFilter.m\n(Denoising)"]
        ILLUM["correctIllumination.m\n(Background Sub)"]
        CLAHE["applyCLAHE.m\n(Lab L* Enhancement)"]
        PRE --> MED --> ILLUM --> CLAHE
    end

    subgraph Inference ["4. Deep Learning Classification"]
        NET["classification/buildModel.m\n(ResNet / EfficientNet / MobileNet)"]
        PRED["classification/predictDR.m"]
        PROBS["Softmax Vector (5 Classes) &\nConfidence Score"]
        NET --> PRED --> PROBS
    end

    subgraph Interpretability ["5. Explainable AI (XAI)"]
        XAI["explainability/computeGradCAM.m"]
        OVERLAY["overlayHeatmap.m\n(Jet Colormap Alpha Blend)"]
        EXP["generateExplanation.m\n(Clinical Narrative Text)"]
        XAI --> OVERLAY & EXP
    end

    subgraph Output ["6. Reporting & Interfaces"]
        REP["reports/generatePatientReport.m"]
        PDF["exportReportPDF.m\n(Clinical PDF Document)"]
        GUI["gui/launchApp.m\n(App Designer UI)"]
        SIM["simulink/setupSimulinkModel.m\n(Queue Simulation)"]
        REP --> PDF
    end

    RAW --> LOADER
    CFG --> LOADER & IQA & PRE & PRED & XAI & REP
    LOADER --> IQA
    IQA -- "Good or Needs Enhancement" --> PRE
    IQA -- "Retake Image (<50)" --> RAW
    PRE --> PRED
    PRED --> XAI
    XAI --> REP & GUI
    PRED --> SIM
```

---

## 2. Subsystem Interface Specifications

### Module 1: Configuration (`config/`)
- **`default_config.json`**: Single source of truth. Contains file paths, dataset split ratios, image preprocessing parameters, neural network hyperparameters, IQA score weights, Grad-CAM settings, and rural deployment flags.
- **`utils/loadConfig.m`**: Parses JSON, validates schema integrity, and automatically maps all relative paths to resolved absolute system paths.

### Module 2: Data Loader (`data/`)
- Ingests datasets: **APTOS 2019**, **EyePACS**, **IDRiD**, and **Messidor-2**.
- Verifies label CSV integrity, filters missing or corrupted image files, and creates stratified train/validation/test partitions.

### Module 3: Image Quality Assessment (`qualityAssessment/`)
- Acts as a clinical gatekeeper at rural camps.
- Evaluates 5 orthogonal visual metrics (Blur, Brightness, Contrast, Noise, Sharpness).
- Returns composite score in $[0, 100]$ and categorical status (`Good`, `Needs Enhancement`, `Retake Image`).

### Module 4: Retinal Preprocessing & Enhancement (`preprocessing/`)
- Suppresses sensor impulse noise via median filtering.
- Removes non-uniform illumination and vignetting artifacts.
- Enhances microvascular lesions (microaneurysms, hemorrhages, exudates) via **L\*a\*b\* CLAHE**.

### Module 5 & 6: Classification & Inference (`classification/`, `training/`)
- Supports state-of-the-art transfer learning backbones: `ResNet18`, `ResNet50`, `EfficientNet-B0`, `MobileNetV2`.
- `predictDR.m` outputs structured diagnosis: DR stage code (0–4), stage label, confidence percentage, 5-class probability vector, latency, and referral status.

### Module 7: Explainable AI (`explainability/`)
- Generates **Grad-CAM** activation maps highlighting microvascular lesions.
- Generates natural language clinical justification explaining model focus to rural health workers.

### Module 8: Clinical Reporting (`reports/`)
- Compiles patient demographics, original fundus, CLAHE image, Grad-CAM overlay, prediction metrics, and doctor sign-off.
- Exports publication-grade clinical reports in PDF and high-res image formats.

### Module 9: MATLAB App Designer GUI (`gui/`)
- Complete 9-page touch-optimized interface featuring Dashboard, Upload, IQA, Enhancement, Prediction, Explainability, Reports, Settings, and Results history.

### Module 10: Simulink Workflow Simulation (`simulink/`)
- Discrete-event queue model tracking patient arrival, capture, AI inference, remote doctor review, and referral triage.

### Module 11: Testing & Verification (`testing/`)
- Automated unit test suite using MATLAB's `matlab.unittest` framework covering utilities, IQA algorithms, and inference interfaces.
