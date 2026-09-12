# System Design Document (SDD)
## Explainable AI-Based Diabetic Retinopathy Screening System for Rural India
### Standard: IEEE Std 1016-2009 Software Design Description
### Project Code: SIH26038 | Version: 1.0.0-Production | Date: September 2026

---

## 1. System Architecture Overview

The **SIH26038 Retinal Screening System** is structured as a five-tier decoupled architecture separating hardware acquisition, image processing pipelines, deep learning inference, explainable AI, clinical reporting, and interactive presentation:

```
+---------------------------------------------------------------------------------------------------+
|                                      FIVE-TIER SYSTEM ARCHITECTURE                                |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [PRESENTATION TIER]                                                                              |
|  - MATLAB App Designer 18-View Clinical Workstation (gui/DRScreeningApp_exported.m)               |
|  - Light / Dark Mode Theme Engine | Interactive Visualizers | Toast Notification Hub              |
|                                         |                                                         |
|                                         v                                                         |
|  [APPLICATION & WORKFLOW TIER]                                                                    |
|  - Master Orchestration Controller (main.m) | Discrete-Event Queue Engine (simulink/)              |
|  - Patient Demographics & State Manager | Offline Session Cache                                   |
|                                         |                                                         |
|                                         v                                                         |
|  [CLINICAL AI & COMPUTATIONAL TIER]                                                               |
|  - Image Quality Assessment Gate (qualityAssessment/assessImageQuality.m)                         |
|  - Retinal Preprocessing & CLAHE Enhancement (preprocessing/preprocessPipeline.m)                 |
|  - Transfer-Learned 5-Stage ICDR Classifier (classification/predictDR.m)                          |
|  - Grad-CAM Heatmap & Lesion Segmentation Engine (explainability/computeGradCAM.m)                |
|                                         |                                                         |
|                                         v                                                         |
|  [REPORTING & DISPATCH TIER]                                                                      |
|  - Clinical PDF Document Assembler (reports/generatePatientReport.m, exportReportPDF.m)           |
|  - Multi-Format Export Hub (PNG Summary, MAT Raw Data, CSV Roster, FHIR JSON Record)             |
|                                         |                                                         |
|                                         v                                                         |
|  [DATA PERSISTENCE & HARDWARE TIER]                                                               |
|  - Centralized JSON Configs (config/) | Image Datastores (data/) | Model Weights (models/)         |
|  - Portable Fundus Camera Mounts (Remidio, Forus, Topcon) | Physical Label Printers               |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Data Flow Diagrams (DFD)

### 2.1 DFD Level 0 (Context Diagram)
The Level 0 Context Diagram depicts the interaction between external human and hardware actors and the core SIH26038 AI system boundary:

```mermaid
graph TD
    CAMERA[Fundus Camera Hardware\nRemidio / Forus / Topcon] -->|Raw Retinal Scans| SYS((SIH26038 AI Retinal\nScreening System))
    ASHA[Community Health Worker\nASHA / ANM] -->|Patient Vitals & Demographics| SYS
    ADMIN[Health Camp Coordinator] -->|Camp Settings & Calibration| SYS

    SYS -->|Image Quality Feedback & Retake Alert| ASHA
    SYS -->|Printed A4 Diagnostic Report & Referral Pass| PATIENT[Rural Diabetic Citizen]
    SYS -->|Escalated High-Risk Cases & Grad-CAM Heatmaps| DOCTOR[Tele-Ophthalmologist\nDistrict Hospital Hub]
    SYS -->|Structured FHIR JSON Audit Records| ABDM[Ayushman Bharat Digital\nMission EHR Gateway]
```

### 2.2 DFD Level 1 (Operational Decomposition)
The Level 1 DFD decomposes the system into its six core operational processes and data stores:

```mermaid
graph TD
    P1[1.0 Patient Intake & Ingestion]
    P2[2.0 Image Quality Assessment Gate]
    P3[3.0 Retinal Preprocessing & CLAHE]
    P4[4.0 Deep Learning 5-Stage Inference]
    P5[5.0 Grad-CAM Explainability Engine]
    P6[6.0 Clinical Report Generation]

    D1[(D1: Active Patient Store)]
    D2[(D2: System Configuration)]
    D3[(D3: Model Weights Checkpoints)]
    D4[(D4: Historical Screening Database)]

    CAMERA[Fundus Camera] -->|Digital Image| P1
    ASHA[ASHA Worker] -->|Demographics| P1
    P1 -->|Stored Record| D1
    P1 -->|Normalized Fundus| P2
    D2 -.->|IQA Thresholds| P2

    P2 -- "Overall Score < 50" --> RETAKE[Field Retake Alert]
    P2 -- "Score >= 50" -->|Quality Verified Fundus| P3
    D2 -.->|CLAHE Clip Limit| P3

    P3 -->|Enhanced Fundus| P4
    D3 -.->|ResNet50 Weights| P4
    P4 -->|Predicted Stage & Softmax| P5
    P3 -->|Feature Maps| P5

    P4 -->|Prediction Data| P6
    P5 -->|Grad-CAM Saliency| P6
    P2 -->|IQA Scores| P6
    D1 -->|Patient Demographics| P6

    P6 -->|Final PDF Report| D4
    P6 -->|Visual Output| GUI[18-Page App Designer GUI]
```

### 2.3 DFD Level 2 (Subsystem: AI Inference & Explainability)
Decomposes processes 4.0 and 5.0 into deep learning feature extraction, classification, gradient backpropagation, lesion segmentation, and text synthesis:

```mermaid
graph TD
    subgraph P4_Subsystem ["Process 4.0: Deep Learning Staging Subsystem"]
        P4_1[4.1 Feature Map Extraction\nResNet-50 Conv5_block3]
        P4_2[4.2 Global Average Pooling & Dense Head]
        P4_3[4.3 Softmax Activation & Confidence Calibration]
        P4_4[4.4 ICDR Referral Rule Engine\nThreshold: Stage >= 2]
    end

    subgraph P5_Subsystem ["Process 5.0: Explainability & Lesion Subsystem"]
        P5_1[5.1 Backpropagate Gradients\ndy^c / dA^k]
        P5_2[5.2 Global Feature Weighting alpha_k^c]
        P5_3[5.3 Rectified Linear Saliency Heatmap]
        P5_4[5.4 Regional Lesion Clustering & Bounding Boxes]
        P5_5[5.5 Natural Language Justification Synthesis]
    end

    ENH_IMG[Enhanced Fundus Image] --> P4_1
    P4_1 --> P4_2
    P4_2 --> P4_3
    P4_3 --> P4_4

    P4_1 --> P5_1
    P4_3 -->|Target Class c| P5_1
    P5_1 --> P5_2
    P5_2 --> P5_3
    P5_3 --> P5_4
    P5_3 --> P5_5
    P4_4 --> P5_5

    P4_4 -->|Triage Action| OUT_TRIAGE[Referral Action Banner]
    P5_3 -->|Color Overlay| OUT_OVERLAY[Grad-CAM Heatmap Viewer]
    P5_4 -->|Box Coordinates| OUT_BBOX[Lesion Detection Inspector]
    P5_5 -->|Clinical Narrative| OUT_TEXT[Diagnostic Justification Card]
```

---

## 3. Unified Modeling Language (UML) Diagrams

### 3.1 Use Case Diagram
Illustrates all system interactions across the four primary human actors:

```mermaid
graph TD
    subgraph Actors
        ASHA((ASHA / ANM Worker))
        DOCTOR((Tele-Ophthalmologist))
        ADMIN((System Administrator))
        PATIENT((Rural Patient))
    end

    subgraph "SIH26038 System Boundary"
        UC1([Register Patient & Demographics])
        UC2([Ingest Fundus Photograph])
        UC3([Evaluate Image Quality IQA])
        UC4([Enhance Image via CLAHE])
        UC5([Run Deep Learning Prediction])
        UC6([Inspect Grad-CAM Heatmap])
        UC7([Segment Salient Lesions])
        UC8([Generate Clinical PDF Report])
        UC9([Review Escalated Referral Case])
        UC10([Simulate Camp Patient Queues])
        UC11([Tune AI & Camp Settings])
        UC12([Toggle Light / Dark Theme])
        UC13([Export Audit Rosters CSV/JSON])
    end

    ASHA --> UC1
    ASHA --> UC2
    ASHA --> UC3
    ASHA --> UC4
    ASHA --> UC5
    ASHA --> UC6
    ASHA --> UC8
    ASHA --> UC12

    DOCTOR --> UC6
    DOCTOR --> UC7
    DOCTOR --> UC8
    DOCTOR --> UC9

    ADMIN --> UC10
    ADMIN --> UC11
    ADMIN --> UC13

    UC8 -.->|Hands Printed Report| PATIENT
```

### 3.2 Class Diagram
Defines the object-oriented structure, domain models, and UI controller classes:

```mermaid
classDiagram
    class DRScreeningApp_exported {
        +UIFigure: Figure
        +ContentTabGroup: TabGroup
        +CurrentConfig: struct
        +CurrentPatient: PatientEntity
        +CurrentRawImage: uint8
        +CurrentEnhancedImage: uint8
        +CurrentQualityResult: struct
        +CurrentPrediction: struct
        +CurrentXAI: struct
        +CurrentTheme: char
        +createComponents()
        +onNavigate(tabIdx)
        +toggleTheme()
        +onRunQuality()
        +onRunEnhance()
        +onRunPredict()
        +onRunXAI()
        +onGeneratePDF()
        +showToast(message, type)
    }

    class PatientEntity {
        +patientId: string
        +fullName: string
        +age: int
        +gender: string
        +eyeTested: string
        +diabetesDuration: int
        +bloodGlucose: float
        +campId: string
        +validate() bool
    }

    class ImageQualityEvaluator {
        +computeBlur(channel) float
        +computeBrightness(img) float
        +computeContrast(channel) float
        +computeSharpness(img) float
        +computeNoise(img) float
        +assess(img, config) QualityReport
    }

    class EnhancementPipeline {
        +isolateGreenChannel(img) uint8
        +correctIllumination(img, radius) uint8
        +applyCLAHE(img, clipLimit) uint8
        +applyMedianFilter(img, kernel) uint8
        +computeMetrics(raw, enh) FidelityMetrics
    }

    class DeepLearningClassifier {
        +modelBackbone: string
        +weightsPath: string
        +numClasses: int
        +predict(img, config) PredictionResult
        +evaluateBatch(batch) cell
    }

    class ExplainabilityEngine {
        +computeGradCAM(model, img, classIdx) XAIResult
        +overlayHeatmap(img, salMap, alpha, cmap) uint8
        +segmentLesions(salMap, img) LesionResult
        +generateJustification(pred, xai) ClinicalNarrative
    }

    class ReportGenerator {
        +hospitalLogoPath: string
        +compileReport(patient, quality, pred, xai) ReportStruct
        +exportPDF(report, config) string
        +exportJSON(report, config) string
    }

    class QueueSimulator {
        +campHours: float
        +arrivalRate: float
        +numCameras: int
        +runSimulation(params) SimulationResults
        +plotResults(results) Figure
    }

    DRScreeningApp_exported --> PatientEntity
    DRScreeningApp_exported --> ImageQualityEvaluator
    DRScreeningApp_exported --> EnhancementPipeline
    DRScreeningApp_exported --> DeepLearningClassifier
    DRScreeningApp_exported --> ExplainabilityEngine
    DRScreeningApp_exported --> ReportGenerator
    DRScreeningApp_exported --> QueueSimulator
```

### 3.3 Sequence Diagram: End-to-End Patient Screening Flow
Illustrates sequential message passing during active patient examination:

```mermaid
sequenceDiagram
    autonumber
    actor ASHA as ASHA Health Worker
    participant GUI as App Designer GUI
    participant IQA as IQA Gatekeeper
    participant ENH as Enhancement Pipeline
    participant DL as Deep Learning Model
    participant XAI as Grad-CAM Engine
    participant REP as Report Generator
    participant DISK as Local Storage

    ASHA->>GUI: Enter Demographics & Ingest Fundus Image
    GUI->>GUI: Validate inputs & render raw preview
    ASHA->>GUI: Click "Assess Image Quality"
    GUI->>IQA: assessImageQuality(rawImage, config)
    IQA-->>GUI: Return QualityReport (Verdict: Good, Score: 92.4%)
    GUI-->>ASHA: Display Green Verdict Badge & Factor Gauges

    ASHA->>GUI: Click "Enhance Retinal Image"
    GUI->>ENH: preprocessPipeline(rawImage, config)
    ENH-->>GUI: Return Enhanced Fundus & PSNR/SSIM Metrics
    GUI-->>ASHA: Render Split-Screen Before/After View

    ASHA->>GUI: Click "Run AI DR Inference"
    GUI->>DL: predictDR(enhancedImage, config)
    DL-->>GUI: Return Stage 3 (Severe NPDR, Conf: 94.2%, Latency: 42ms)
    GUI-->>ASHA: Display Stage Badge & URGENT REFERRAL BANNER

    ASHA->>GUI: Click "Compute Explainability (Grad-CAM)"
    GUI->>XAI: computeGradCAM([], enhancedImage, 3, config)
    XAI-->>GUI: Return Saliency Map & Clinical Justification
    GUI-->>ASHA: Render Jet Heatmap Overlay & Lesion BBoxes

    ASHA->>GUI: Click "Export Clinical PDF Report"
    GUI->>REP: generatePatientReport(demographics, IQA, DL, XAI)
    REP->>DISK: Export encrypted A4 PDF to results/reports/
    DISK-->>REP: Confirm PDF written
    REP-->>GUI: Return Report Path
    GUI-->>ASHA: Show Toast "Report Exported Successfully!"
```

### 3.4 Sequence Diagram: Tele-Ophthalmology Referral Escalation
Illustrates the remote specialist consultation workflow for high-risk patients:

```mermaid
sequenceDiagram
    autonumber
    actor ASHA as Rural ASHA Worker
    participant PHC as Rural Edge Station
    participant SYNC as ABDM Cloud Gateway
    actor DOC as District Tele-Ophthalmologist
    actor PATIENT as Rural Patient

    Note over ASHA,PHC: Patient diagnosed with Stage 3 / Stage 4 DR
    PHC->>PHC: Flag Case for Priority Tele-Consultation
    alt Network Available (4G / Wi-Fi)
        PHC->>SYNC: Upload Encrypted PDF & FHIR JSON Record
        SYNC->>DOC: Push Critical Alert: Urgent Tele-Referral
        DOC->>SYNC: Open Diagnostic Portal & Review Tri-Image Panel
        DOC->>DOC: Confirm Laser Photocoagulation Required
        DOC->>SYNC: Transmit Signed Hospital Admission Pass
        SYNC->>PHC: Deliver Electronic Hospital Voucher
        PHC-->>ASHA: Print Referral Slip with District Hospital Date
    else Network Offline (Zero Connectivity)
        PHC-->>ASHA: Print High-Contrast Paper Referral Pass
        ASHA->>PATIENT: Hand Physical Referral Pass & Coordinate Transport
    end
    ASHA->>PATIENT: Deliver Emergency Counselling & Schedule Follow-Up
```

### 3.5 Activity Diagram: Patient Screening Lifecycle
Shows control flow and decision branches through quality gates and referral thresholds:

```mermaid
flowchart TD
    START([Patient Arrives at Rural Camp]) --> REG[Register Patient Demographics & Vitals]
    REG --> CAPTURE[Capture Retinal Fundus with Handheld Camera]
    CAPTURE --> IQA{Evaluate IQA Gate\nLaplacian Blur & Illum}

    IQA -- "Score < 50 (Poor Quality)" --> WARN[Display Audible & Visual Retake Warning]
    WARN --> RETAKE_COUNT{Retake Count\n< 2?}
    RETAKE_COUNT -- Yes --> CLEAN[Clean Lens, Re-align Eye, Re-capture]
    CLEAN --> CAPTURE
    RETAKE_COUNT -- No --> MANUAL_DOC[Flag for In-Person Slit-Lamp Examination]

    IQA -- "Score >= 50 (Acceptable)" --> PREPROC[Apply CLAHE & Illumination Leveling]
    PREPROC --> INFER[Execute Deep Learning Forward Pass]
    INFER --> STAGE[Assign 5-Stage ICDR Staging & Probabilities]
    STAGE --> XAI[Compute Grad-CAM Saliency & Lesions]

    XAI --> TRIAGE{Predicted Stage\n>= 2?}
    TRIAGE -- "No (Stage 0: No DR or Stage 1: Mild)" --> ROUTINE[Generate Routine Annual Screening Report]
    ROUTINE --> COUNSEL_LOW[Counsel on Glycemic Control & Re-screen in 12 Months]
    COUNSEL_LOW --> FINISH([Screening Complete])

    TRIAGE -- "Yes (Stage 2: Mod, Stage 3: Sev, Stage 4: PDR)" --> URGENT[Generate Priority Tele-Referral Document]
    URGENT --> TELE_DOC[Transmit Case to District Tele-Ophthalmologist]
    TELE_DOC --> ISSUE_PASS[Issue District Eye Hospital Pass & Coordinate Transport]
    ISSUE_PASS --> FINISH
```

### 3.6 State Machine Diagram: Patient Screening State
Defines the discrete state transitions of a patient record inside the application:

```mermaid
stateDiagram-v2
    [*] --> Registered: Patient Intake Completed
    Registered --> ImageAcquired: Fundus Photograph Uploaded
    ImageAcquired --> QualityAssessing: Trigger IQA Check

    QualityAssessing --> QualityRejected: Score < 50 (Blur / Glare)
    QualityRejected --> ImageAcquired: Lens Cleaned & Recaptured
    QualityRejected --> ManualOphthalmologistReferral: Max Retakes Exceeded

    QualityAssessing --> QualityApproved: Score >= 50 (Good / Enhance)
    QualityApproved --> Preprocessed: CLAHE Enhancement Applied
    Preprocessed --> Classifying: Deep Learning Forward Pass
    Classifying --> Diagnosed: 5-Stage Staging Assigned

    Diagnosed --> ExplainabilityGenerated: Grad-CAM Saliency Computed
    ExplainabilityGenerated --> RoutineCare: Stage < 2 (Stage 0 or 1)
    ExplainabilityGenerated --> UrgentReferral: Stage >= 2 (Moderate, Severe, PDR)

    RoutineCare --> ReportExported: PDF Report Generated
    UrgentReferral --> ReportExported: Priority PDF & Voucher Generated

    ReportExported --> Archived: Added to Historical Audit Table
    Archived --> [*]
```

### 3.7 Component Diagram
Shows physical software modules and runtime dependency linkages:

```mermaid
graph TD
    subgraph UI_Layer ["Presentation & UI Components"]
        APP[DRScreeningApp_exported.m\nMaster 18-View Workstation]
        LAUNCH[launchApp.m\nLauncher & Environment Checker]
        THEME[Theme Engine\nLight / Dark Palette Switcher]
    end

    subgraph Core_Pipelines ["Computational Core Modules"]
        IQA_MOD[qualityAssessment/\nBlur, Brightness, Contrast]
        PRE_MOD[preprocessing/\nCLAHE, Illumination Correction]
        DL_MOD[classification/\nResNet-50, MobileNetV2]
        XAI_MOD[explainability/\nGrad-CAM, Saliency Overlay]
        REP_MOD[reports/\nPDF Exporter, Cohort Aggregator]
        SIM_MOD[simulink/\nDiscrete-Event Queue Simulator]
    end

    subgraph Shared_Utilities ["Shared Infrastructure Utilities"]
        LOGGER[utils/logger.m\nTimestamped File & Console Logger]
        CONFIG[utils/loadConfig.m\nJSON Schema Validator]
        READER[utils/loadImage.m\nSafe Border Cropper & Normalizer]
        ERROR_H[utils/errorHandler.m\nGraceful Exception Interceptor]
    end

    LAUNCH --> APP
    APP --> THEME
    APP --> IQA_MOD
    APP --> PRE_MOD
    APP --> DL_MOD
    APP --> XAI_MOD
    APP --> REP_MOD
    APP --> SIM_MOD

    IQA_MOD --> LOGGER
    PRE_MOD --> LOGGER
    DL_MOD --> CONFIG
    XAI_MOD --> LOGGER
    REP_MOD --> READER
    APP --> ERROR_H
```

### 3.8 Deployment Diagram
Illustrates edge hardware deployment in rural Primary Health Centres vs District Cloud:

```mermaid
graph TD
    subgraph Rural_PHC ["Rural Primary Health Centre / Camp Edge Station"]
        subgraph Hardware_Peripherals ["Field Peripherals"]
            CAM[Handheld Fundus Camera\nRemidio NM-FOP / Forus 3nethra]
            PRINTER[Thermal / Inkjet Printer\nA4 Report & Patient Voucher]
        end

        subgraph Edge_Laptop ["Edge Compute Workstation (Intel i5, 8GB RAM)"]
            OS[Windows 10/11 or Ubuntu Linux]
            M_RUNTIME[MATLAB R2021b+ Runtime]
            SIH_APP[SIH26038 Retinal Workstation App]
            LOCAL_DB[(Local SQLite / JSON Audit Store)]
        end
    end

    subgraph District_Hospital ["District Hospital Hub / Cloud Infrastructure"]
        TELE_PORTAL[District Tele-Ophthalmology Web Portal]
        ABDM_GATEWAY[Ayushman Bharat Health Account Gateway]
        SPECIALIST[Vitreo-Retinal Specialist Workstation]
    end

    CAM -->|USB / SD Card Interface| Edge_Laptop
    SIH_APP -->|USB Print Driver| PRINTER
    SIH_APP <--> LOCAL_DB

    Edge_Laptop -.->|Secure TLS 1.3 over 4G / Wi-Fi| TELE_PORTAL
    TELE_PORTAL <--> SPECIALIST
    TELE_PORTAL <--> ABDM_GATEWAY
```

### 3.9 Package Diagram
Defines namespace packaging and subsystem directory boundaries:

```mermaid
graph TD
    subgraph "SIH26038 Root Package"
        CONFIG_PKG["config\nMaster & Rural JSON Configs"]
        UTILS_PKG["utils\nLogging, Error Handling, I/O"]
        DATA_PKG["data\nDatasets, Loaders, Synthetic Generator"]
        IQA_PKG["qualityAssessment\nBlur, Illumination, Contrast Engines"]
        PRE_PKG["preprocessing\nCLAHE, Denoising, Normalization"]
        CLASS_PKG["classification\nDL Models, Inference, Triage"]
        XAI_PKG["explainability\nGrad-CAM, Saliency, Lesion Overlays"]
        REP_PKG["reports\nPatient & Cohort PDF Generators"]
        GUI_PKG["gui\n18-View App Designer Clinical Suite"]
        SIM_PKG["simulink\nDiscrete-Event Queueing Model"]
        TEST_PKG["testing\nAutomated Unit & Stress Test Suites"]
        DOCS_PKG["documentation\nSRS, SDD, RTM, Manuals, Capstone Report"]
    end

    GUI_PKG --> IQA_PKG
    GUI_PKG --> PRE_PKG
    GUI_PKG --> CLASS_PKG
    GUI_PKG --> XAI_PKG
    GUI_PKG --> REP_PKG
    GUI_PKG --> SIM_PKG

    IQA_PKG --> UTILS_PKG
    PRE_PKG --> UTILS_PKG
    CLASS_PKG --> CONFIG_PKG
    TEST_PKG --> GUI_PKG
    TEST_PKG --> CLASS_PKG
```

---

## 4. System & Program Flowcharts

### 4.1 System Flowchart
Depicts high-level physical document and digital data flow throughout rural screening operations:

```mermaid
flowchart TD
    A([Patient Registration Desk]) --> B[/Patient Demographics: Name, Age, ID/]
    B --> C[Assign Screening Token]
    C --> D[Fundus Image Acquisition Station]
    D --> E[USB Fundus Camera Capture]
    E --> F[Automated Image Quality Assessment Gate]
    F --> G{Is Image Quality\nAcceptable?}

    G -- No --> H[Issue Field Retake Alert to Operator]
    H --> D

    G -- Yes --> I[Apply Adaptive CLAHE & Illumination Leveling]
    I --> J[Execute Deep Learning Forward Pass]
    J --> K[Compute Grad-CAM Saliency Heatmap]
    K --> L{Referral Threshold\nStage >= 2?}

    L -- No --> M[Generate Routine Screening Certificate]
    L -- Yes --> N[Compile Urgent Hospital Referral Document]
    N --> O[Transmit Case to District Tele-Ophthalmologist]

    M --> P[/Print Physical Report for Patient/]
    O --> P
    P --> Q([Patient Handoff & Departure])
```

### 4.2 Program Flowchart
Detailed algorithmic control flow of the core MATLAB inference and explainability engine:

```mermaid
flowchart TD
    START([predictDR Function Invocation]) --> CHK_IN{Is Input Image uint8\nand 3-Channel?}
    CHK_IN -- No --> CONV[Convert to uint8 and replicate channels if grayscale]
    CHK_IN -- Yes --> RESIZE[Resize to 224x224x3 using bicubic interpolation]
    CONV --> RESIZE

    RESIZE --> NORM[Normalize pixel dynamic range to 0.0 - 1.0]
    NORM --> MODEL_LOAD{Trained Network\nAvailable on Disk?}

    MODEL_LOAD -- Yes --> FORWARD[Pass normalized tensor through ResNet-50 dlnetwork]
    FORWARD --> EXTRACT[Extract activations from layer 'conv5_block3_out']
    EXTRACT --> SOFTMAX[Compute Softmax probabilities across 5 stages]

    MODEL_LOAD -- No --> HEURISTIC[Execute Heuristic Feature Extraction Fallback]
    HEURISTIC --> LESION_STAT[Compute green-channel optical density & high-freq energy]
    LESION_STAT --> SOFTMAX

    SOFTMAX --> ARGMAX[Determine predictedStage = argmax_c P_c]
    ARGMAX --> CONF[Calculate confidence = max_c P_c]
    CONF --> TRIAGE{predictedStage\n>= 2?}

    TRIAGE -- Yes --> REF_TRUE[Set referralRecommended = true, urgency = Priority]
    TRIAGE -- No --> REF_FALSE[Set referralRecommended = false, urgency = Routine]

    REF_TRUE --> GRADCAM[Compute Grad-CAM: Backprop target class gradient]
    REF_FALSE --> GRADCAM

    GRADCAM --> RELU[Apply ReLU: SaliencyMap = max 0, sum alpha_k A^k]
    RELU --> NORM_SAL[Normalize saliency map to 0.0 - 1.0 range]
    NORM_SAL --> BLEND[Blend SaliencyMap with original fundus using Jet colormap]
    BLEND --> STRUCT[Package into predictionResult & xaiResult structs]
    STRUCT --> END([Return Result to Caller])
```
