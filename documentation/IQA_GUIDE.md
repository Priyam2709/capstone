# Image Quality Assessment (IQA) Protocol: SIH26038

**Smart India Hackathon Problem Statement:** SIH26038  
**Module Name:** Independent Retinal Image Quality Assessment (IQA)  
**Target Setting:** Rural Primary Health Centres (PHCs) and Mobile Camp Screening

---

## 1. Clinical Rationale & Public Health Imperative

Non-mydriatic portable fundus cameras deployed in rural camps operate in non-ideal optical environments. Community health workers frequently encounter:
1. **Defocus & Motion Blur:** Caused by patient involuntary saccadic eye movements or unsteady handheld cameras.
2. **Underexposure & Dim Illumination:** Small, undilated pupils in daylight camps restrict photon flux to the camera sensor.
3. **Corneal Flash Glare:** Misalignment of the optical illumination ring with the pupil aperture creates severe white reflections.
4. **Media Opacities:** High prevalence of senile cataracts in rural elderly diabetics induces hazy, low-contrast fundus images.

Feeding substandard retinal captures directly into deep neural networks causes dangerous diagnostic failures—either missing early microaneurysms (false negatives) or mistaking camera blur for diffuse edema (false positives). The **IQA module acts as an autonomous clinical gatekeeper**, intercepting unusable images in real time while the patient is still seated.

---

## 2. Mathematical Formulations of Quality Metrics

Every captured image is analyzed in the **green channel spectrum** (where hemoglobin has peak absorption, providing maximum contrast between retinal microvasculature and background choroid):

```
                        [Input Fundus Image]
                                 │
                         Extract Green Channel
                                 │
                     Compute Retinal Tissue Mask
                       (Exclude Camera Border)
                                 │
         ┌──────────────┬────────┼──────────────┬──────────────┐
         ▼              ▼        ▼              ▼              ▼
     1. Blur      2. Brightness  3. Contrast  4. Noise    5. Sharpness
   (Laplacian)      (Luminance)    (RMS & DR) (Immerkaer)  (Tenengrad)
```

### 1. Blur Metric (Modified Laplacian Variance)
Measures the variance of the second-order spatial derivative on foreground retinal tissue:
$$\nabla^2 I(x,y) = I(x+1, y) + I(x-1, y) + I(x, y+1) + I(x, y-1) - 4 I(x,y)$$
$$\text{Blur Score} = \frac{1}{|M|} \sum_{(x,y) \in M} \left( \nabla^2 I(x,y) - \overline{\nabla^2 I} \right)^2$$
- **Threshold:** $\ge 100.0$ indicates sharp vessel boundaries; $< 50.0$ triggers immediate retake.

### 2. Brightness Metric (Mean Luminance & Quadrant Uniformity)
Extracts perceptual luminance and checks for illumination symmetry across four retinal quadrants ($Q_1, Q_2, Q_3, Q_4$):
$$\mu_B = \frac{1}{|M|} \sum_{(x,y) \in M} I(x,y)$$
$$\text{Uniformity} = 1.0 - \frac{\max_k(\mu_{Q_k}) - \min_k(\mu_{Q_k})}{\overline{\mu_Q}}$$
- **Thresholds:** Optimal range is $[80, 160]$. Underexposure flagged if $< 40.0$; flash glare flagged if $> 215.0$.

### 3. Contrast Metric (RMS Contrast & Dynamic Range)
Root Mean Square (RMS) contrast measures the intensity variation across the retina:
$$\text{RMS Contrast} = \sqrt{\frac{1}{|M|} \sum_{(x,y) \in M} \left( I(x,y) - \mu_B \right)^2}$$
- **Threshold:** Minimum RMS contrast $\ge 25.0$.

### 4. Noise Metric (Immerkaer High-Frequency Variance)
Estimates additive zero-mean Gaussian noise without interference from structural edges:
$$N = \begin{bmatrix} 1 & -2 & 1 \\ -2 & 4 & -2 \\ 1 & -2 & 1 \end{bmatrix}, \quad \sigma_{\text{noise}} = \frac{\sqrt{\pi/2}}{6} \cdot \frac{1}{|M_{\text{smooth}}|} \sum_{(x,y) \in M_{\text{smooth}}} |(I * N)(x,y)|$$
$$\text{SNR (dB)} = 20 \log_{10}\left( \frac{\mu_B}{\sigma_{\text{noise}}} \right)$$
- **Threshold:** Noise standard deviation should remain $\le 20.0$.

### 5. Sharpness Metric (Tenengrad Gradient Energy)
Computes the sum of squared Sobel gradient magnitudes for significant edge transitions:
$$S_x = I * \begin{bmatrix} -1 & 0 & 1 \\ -2 & 0 & 2 \\ -1 & 0 & 1 \end{bmatrix}, \quad S_y = S_x^T$$
$$\text{Tenengrad} = \frac{1}{|M|} \sum_{(x,y) \in M, S_x^2 + S_y^2 > \tau} (S_x^2 + S_y^2)$$
- **Threshold:** Tenengrad energy $\ge 150.0$.

---

## 3. Composite Quality Scoring & Categorization

Each raw metric is calibrated into a standardized sub-score $S_k \in [0, 100]$ through non-linear sigmoidal scaling. The **Overall Quality Score** is computed as a weighted sum:

$$\text{Overall Score} = 0.25 S_{\text{blur}} + 0.20 S_{\text{brightness}} + 0.20 S_{\text{contrast}} + 0.15 S_{\text{noise}} + 0.20 S_{\text{sharpness}}$$

### Three-Tier Categorical Classification

| Category | Score Range | Clinical Interpretation | Action Protocol |
| :--- | :---: | :--- | :--- |
| **Good** | $\ge 75.0$ | Pristine optical clarity, sharp microvessels, even illumination. | **Approved:** Proceed directly to Deep Learning classification. |
| **Needs Enhancement** | $50.0 - 74.9$ | Minor illumination deficit or slight contrast attenuation. | **Auto-Enhance:** Route image to CLAHE and median filtering before classification. |
| **Retake Image** | $< 50.0$ | Severe motion blur, flash glare, or impenetrable underexposure. | **Halt Pipeline:** Emit audio-visual alert to ASHA worker to recapture image immediately. |

---

## 4. API Reference: Functions in `qualityAssessment/`

| Function | Primary Purpose | Syntax |
| :--- | :--- | :--- |
| [`assessImageQuality.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/assessImageQuality.m) | Master IQA orchestrator evaluating all 5 metrics and returning structured report. | `qRep = assessImageQuality(img, cfg);` |
| [`computeBlur.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/computeBlur.m) | Calculates masked Laplacian variance. | `[blurScore, blurMap] = computeBlur(grayImg, mask);` |
| [`computeBrightness.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/computeBrightness.m) | Evaluates mean luminance, quadrant uniformity, and exposure defects. | `[meanB, uniformity, expStats] = computeBrightness(img, mask);` |
| [`computeContrast.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/computeContrast.m) | Calculates RMS contrast, dynamic range, and Michelson contrast. | `[rms, michelson, dynRange] = computeContrast(grayImg, mask);` |
| [`computeNoise.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/computeNoise.m) | Estimates additive noise standard deviation and SNR in dB. | `[noiseStd, snrDb] = computeNoise(grayImg, mask);` |
| [`computeSharpness.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/computeSharpness.m) | Evaluates Tenengrad edge gradient energy. | `[tenengrad, edgeDensity] = computeSharpness(grayImg, mask);` |
| [`visualizeQualityReport.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/visualizeQualityReport.m) | Renders multi-panel clinical diagnostic dashboard and exports graphic. | `fig = visualizeQualityReport(img, qRep, 'report.png');` |
| [`batchAssessQuality.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/qualityAssessment/batchAssessQuality.m) | Runs batch evaluation over a directory or image table, generating audit CSV. | `[tbl, summary] = batchAssessQuality('data/raw/aptos/');` |
