# SIH26038: 10-Minute Judge Demo Script & Viva Defense Guide
## Explainable AI-Based Diabetic Retinopathy Screening System for Rural India
### Presentation & Viva Preparation | Version: 1.0.0-Production | Date: September 2026

---

## 1. 10-Minute Live Judge Demonstration Script

### Minute 0:00 - 1:30 | The Rural Problem & The Mission
- **Presenter**: *"Respected Judges, over 77 million citizens in India live with diabetes. In rural primary health centres, more than 80% of patients have never had an eye examination because retina specialists are concentrated in distant metropolitan hospitals. By the time a rural farmer notices vision loss, irreversible proliferative damage has already occurred."*
- **Visual**: Show the slide comparing rural diabetic population vs specialist density.
- **Presenter**: *"Our solution—**SIH26038**—is an edge-deployable, explainable AI screening workstation engineered natively in MATLAB that empowers rural ASHA workers to detect diabetic retinopathy in under 5 seconds with zero internet connectivity."*

### Minute 1:30 - 3:00 | Launching the Production Application & Dashboard
- **Action**: In MATLAB, run:
  ```matlab
  main('gui')
  ```
- **Visual**: The 18-View App Designer GUI appears in **Crisp Clinical Light Mode**.
- **Presenter**: *"Here is our production medical workstation. Notice the modern dashboard displaying real-time camp analytics: 48 patients screened today, 81.2% normal, and 18.8% flagged for district referral. We also built an instant Light/Dark mode switch for varying camp ambient lighting."*
- **Action**: Click the `☾ Dark` theme toggle button on the top right bar. The UI transitions to high-contrast deep navy dark mode, then toggle back to Light mode.

### Minute 3:00 - 4:30 | Patient Ingestion & The Image Quality (IQA) Gate
- **Action**: Click `2. Upload Image` in the sidebar. Click `Load Sample Severe DR Fundus`.
- **Presenter**: *"Now we ingest a patient photograph. Notice that before any AI diagnosis is made, we enforce an optical quality gate to eliminate false negatives."*
- **Action**: Click `5. Quality Assessment` and click `Assess Retinal Image Quality (IQA)`.
- **Visual**: Overall Quality Score updates to `91.4% (Good)`, factor bars display Laplacian blur, brightness, contrast, sharpness, and noise.
- **Presenter**: *"If an ASHA worker captures an image with severe motion blur or glare, the system blocks diagnosis and issues an audible alert instructing them to clean the lens and recapture."*

### Minute 4:30 - 6:00 | Retinal Enhancement & Deep Learning Inference
- **Action**: Click `6. Enhancement` and click `Apply Enhancement Pipeline`.
- **Visual**: Split-screen raw vs enhanced fundus appears with CLAHE clip-limit slider and PSNR ($>31.8\text{ dB}$) and SSIM ($>0.94$).
- **Presenter**: *"Our preprocessing isolates the green channel and applies morphological background subtraction and CLAHE, enhancing subtle microvascular lesions while preserving structural fidelity."*
- **Action**: Click `7. Disease Prediction` and click `Run AI DR Inference Engine`.
- **Visual**: Predicted Stage badge turns Orange: `STAGE 3: SEVERE NPDR`, confidence displays `94.2%`, inference latency shows `42.5 ms`, and the `URGENT REFERRAL REQUIRED` alert banner lights up.

### Minute 6:00 - 7:30 | Explainable AI (Grad-CAM Saliency) & Lesion Detection
- **Action**: Click `8. Explainable AI` and click `Compute Grad-CAM Saliency Map`.
- **Visual**: High-resolution Jet colormap overlay appears over the fundus, highlighting hemorrhage clusters along the superior-temporal arcade.
- **Presenter**: *"This is our core innovation: Explainable AI. Instead of a black box, Grad-CAM shows the clinician exactly where the neural network detected pathology. The natural language card explains that hemorrhages in multiple quadrants satisfied the ICDR 4-2-1 diagnostic criteria for Severe NPDR."*
- **Action**: Click `9. Lesion Detection` to show microaneurysm and exudate bounding boxes.

### Minute 7:30 - 8:45 | Clinical Report Generation & Multi-Format Export
- **Action**: Click `12. Generated Reports` and click `Generate & Export Full PDF Report`.
- **Visual**: Toast notification appears: `Clinical PDF Report generated successfully!`.
- **Action**: Click `Open Generated Report PDF`.
- **Visual**: The A4 medical PDF opens showing hospital branding, quad-image panel, doctor notes, and signature line.
- **Presenter**: *"With 1 click, the system compiles an official A4 clinical PDF report and FHIR-compliant JSON record that can be printed physically for the patient or synced to the Ayushman Bharat Digital Mission (ABDM)."*

### Minute 8:45 - 10:00 | Simulink Queue Simulation & Conclusion
- **Action**: Click `15. Simulation` in the sidebar.
- **Presenter**: *"Finally, to ensure rural camps don't get overwhelmed by patient backlogs, we modeled the entire camp workflow in a Simulink discrete-event queue model. Our simulation proved that adding a second handheld camera operated by an ASHA worker cuts patient waiting time by 68.5% and doubles daily throughput to 270 patients, while the AI computing node operates at under 2.5% utilization."*
- **Closing**: *"SIH26038 is 100% complete, fully tested across 50 automated test cases, and ready for immediate deployment to eliminate preventable diabetic blindness across rural India. Thank you, and we welcome your questions!"*

---

## 2. Viva Q&A Defense Bank for Judges

#### Q1: "Why use MATLAB instead of Python / PyTorch?"
> **Answer**: *"MATLAB provides verified, mathematically certified toolboxes for medical image processing, seamless App Designer GUI packaging into standalone royalty-free executables (`.exe`), and native integration with Simulink for discrete-event healthcare operations modeling—all within a single, validated engineering ecosystem without dependency hell."*

#### Q2: "How does the system prevent false negatives when an image is blurry?"
> **Answer**: *"Through our automated Image Quality Assessment (IQA) gatekeeper (`qualityAssessment/assessImageQuality.m`). It evaluates Laplacian variance, illumination uniformity, and RMS contrast. If an image is flagged as 'Retake Image' (score $< 50$), the diagnostic classifier is locked, preventing the AI from misinterpreting blur as a normal retina."*

#### Q3: "What happens if there is no internet in the village?"
> **Answer**: *"The system is built offline-first. All deep learning inference, CLAHE preprocessing, Grad-CAM generation, and PDF reporting execute locally on the edge laptop with 0 internet dependency. When internet is available, reports can optionally sync to ABDM via secure FHIR JSON schemas."*

#### Q4: "How does Grad-CAM work mathematically?"
> **Answer**: *"Grad-CAM computes the gradient of the predicted class score $y^c$ with respect to the feature activation maps $A^k$ of the final convolutional layer: $\alpha_k^c = \frac{1}{Z} \sum_i \sum_j \frac{\partial y^c}{\partial A_{i,j}^k}$. We take a rectified linear combination $L^c = \text{ReLU}(\sum \alpha_k^c A^k)$ to retain only features that positively influence the target DR stage."*

#### Q5: "What is your clinical referral threshold?"
> **Answer**: *"Per the International Clinical Diabetic Retinopathy (ICDR) standard, any patient with Stage 2 (Moderate NPDR), Stage 3 (Severe NPDR), or Stage 4 (Proliferative DR) requires referral to an ophthalmologist for laser photocoagulation or anti-VEGF therapy. Stage 0 (No DR) and Stage 1 (Mild NPDR) receive routine annual surveillance."*
