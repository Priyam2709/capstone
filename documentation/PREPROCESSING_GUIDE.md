# Retinal Image Enhancement & Preprocessing Guide: SIH26038

**Smart India Hackathon Problem Statement:** SIH26038  
**Module Name:** Preprocessing & Retinal Enhancement Pipeline (`preprocessing/`)  
**Domain:** Biomedical Image Processing, Retinal Contrast Optimization & Noise Suppression

---

## 1. Clinical Context & Objective

In rural India, non-mydriatic fundus cameras frequently produce suboptimal retinal images due to small pupils, corneal reflexes, patient movement, and cataracts. Subtle diagnostic signs of Diabetic Retinopathy—such as **microaneurysms** ($15 - 50\,\mu\text{m}$ red capillary outpouchings) and **cotton wool spots** (micro-infarcts)—are easily obscured.

The preprocessing pipeline acts as an automated digital darkroom that:
1. **Suppresses Sensor Impulse Noise:** Removes camera sensor dead pixels and high-ISO noise without blurring fine microvascular edges.
2. **Corrects Non-Uniform Illumination:** Eliminates flash vignetting and peripheral darkness, leveling the retinal illumination across all four quadrants.
3. **Amplifies Microvascular Contrast via CLAHE:** Enhances local contrast in the CIELAB luminance ($L^*$) channel, preventing color distortion of hemorrhages and optic disc tissue.
4. **Broadens Dynamic Range:** Stretches compressed tonal distributions to utilize the full 8-bit dynamic depth.
5. **Quantifies Image Improvement:** Employs rigorous mathematical metrics (PSNR, SSIM, CII, Entropy, and EME) to confirm image fidelity before downstream AI classification.

---

## 2. Preprocessing Pipeline Architecture

```
[Raw Fundus Image]
        │
        ▼
[Stage 1: Median Filter]
(Kernel: 3x3 • Eliminates salt-and-pepper noise)
        │
        ▼
[Stage 2: Illumination Leveling]
(Gaussian background subtraction: I - I_bg + mean(I_bg))
        │
        ▼
[Stage 3: CIELAB CLAHE]
(L* channel adaptive equalization • ClipLimit: 0.02 • Grid: 8x8)
        │
        ▼
[Stage 4: Luminance Histogram Balancing]
(Blended bi-histogram equalization • Weight: 0.35)
        │
        ▼
[Stage 5: Contrast Percentile Stretching & Gamma Correction]
(1st - 99th percentile stretch • Gamma: 1.15)
        │
        ▼
[Stage 6: Edge-Preserving Bilateral Filtering]
(Suppresses residual high-ISO noise while preserving vessel walls)
        │
        ▼
[Enhanced Retinal Image] ──► [Quantitative Evaluation: PSNR, SSIM, CII, Entropy]
```

---

## 3. Mathematical Formulations of Enhancement Stages

### 1. Contrast-Limited Adaptive Histogram Equalization (CLAHE)
Standard histogram equalization tends to over-amplify background noise in relatively homogeneous regions of the retina (such as the macular avascular zone). CLAHE bounds contrast amplification by clipping the local contextual histogram at threshold $\beta$:
$$\beta = \frac{N}{M} \left( 1 + \frac{\alpha}{100} (s_{\max} - 1) \right)$$
The clipped pixels are redistributed uniformly across all histogram bins before computing the Cumulative Distribution Function (CDF).
- **Color Space:** Computed on the $L^*$ (Luminance) channel of the CIELAB representation, leaving the chromatic channels $a^*$ (green-red) and $b^*$ (blue-yellow) unaltered. This preserves vital clinical color biomarkers (e.g. cherry-red microaneurysms vs. golden hard exudates).

### 2. Illumination Correction & Background Leveling
Fundus cameras introduce radial illumination decay (vignetting). The slowly varying low-frequency background surface is estimated by convolving with a large Gaussian kernel ($\sigma \approx 0.12 \times \text{Width}$):
$$I_{\text{bg}}(x,y) = I(x,y) * G_\sigma(x,y)$$
$$I_{\text{corrected}}(x,y) = I(x,y) - I_{\text{bg}}(x,y) + \overline{I_{\text{bg}}}$$

### 3. Dynamic Range Stretching & Gamma Correction
Stretches the middle 98% of foreground retinal luminance values:
$$I_{\text{stretched}}(x,y) = \frac{I(x,y) - P_{1\%}}{P_{99\%} - P_{1\%}} \cdot 255$$
$$I_{\text{final}}(x,y) = 255 \cdot \left( \frac{I_{\text{stretched}}(x,y)}{255} \right)^{1/\gamma}, \quad \gamma = 1.15$$

---

## 4. Quantitative Improvement Metrics

| Metric | Mathematical Definition | Clinical Interpretation | Target Value |
| :--- | :--- | :--- | :---: |
| **PSNR (Peak Signal-to-Noise Ratio)** | $\text{PSNR} = 10 \log_{10}\left( \frac{255^2}{\text{MSE}} \right)$ | Measures image reconstruction fidelity. | $> 28.0\,\text{dB}$ |
| **SSIM (Structural Similarity Index)** | $\text{SSIM}(x,y) = \frac{(2\mu_x\mu_y + c_1)(2\sigma_{xy} + c_2)}{(\mu_x^2 + \mu_y^2 + c_1)(\sigma_x^2 + \sigma_y^2 + c_2)}$ | Quantifies preservation of retinal microvascular topology and structural patterns. | $> 0.850$ |
| **CII (Contrast Improvement Index)** | $\text{CII} = \frac{C_{\text{enhanced}}}{C_{\text{original}}}, \quad C = \frac{\sigma_{\text{retina}}}{\mu_{\text{retina}}}$ | Factor of contrast amplification. | $> 1.00\times$ |
| **Shannon Information Entropy** | $H = -\sum_{i=0}^{255} p(i) \log_2 p(i)$ | Reflects richness of fine microvascular and lesion detail. | $+0.15$ to $+0.60\,\text{bits/px}$ |
| **EME (Enhancement Measure by Entropy)** | $\text{EME} = \frac{1}{k_1 k_2} \sum_{k=1}^{k_1}\sum_{l=1}^{k_2} 20 \ln\left( \frac{I_{\max; k,l}}{I_{\min; k,l} + \epsilon} \right)$ | Average local block-wise dynamic contrast. | Higher is better |

---

## 5. API Reference: Functions in `preprocessing/`

| Function | Primary Purpose | Syntax |
| :--- | :--- | :--- |
| [`preprocessPipeline.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/preprocessPipeline.m) | Master 6-stage orchestrator producing enhanced fundus image and metrics. | `res = preprocessPipeline(img, cfg);` |
| [`applyCLAHE.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/applyCLAHE.m) | L\*a\*b\* CLAHE enhancement with configurable clip limit and tile grid. | `out = applyCLAHE(img, 0.02, [8, 8]);` |
| [`applyMedianFilter.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/applyMedianFilter.m) | Salt-and-pepper / sensor impulse noise suppression. | `denoised = applyMedianFilter(img, [3, 3]);` |
| [`correctIllumination.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/correctIllumination.m) | Gaussian background leveling and flash vignetting compensation. | `corr = correctIllumination(img);` |
| [`applyHistogramEqualization.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/applyHistogramEqualization.m) | Retinal luminance equalization with controlled blending. | `eq = applyHistogramEqualization(img, 0.35);` |
| [`enhanceContrast.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/enhanceContrast.m) | Dynamic range percentile stretching and gamma adjustment. | `enh = enhanceContrast(img, 1.15);` |
| [`reduceNoise.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/reduceNoise.m) | Edge-preserving bilateral and Wiener filtering. | `denoised = reduceNoise(img, 'bilateral');` |
| [`evaluateEnhancementMetrics.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/evaluateEnhancementMetrics.m) | Computes PSNR, SSIM, CII, Entropy, EME, and sharpness gain. | `m = evaluateEnhancementMetrics(orig, enh);` |
| [`compareEnhancement.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/compareEnhancement.m) | Renders multi-panel side-by-side comparison and histogram distribution. | `fig = compareEnhancement(orig, enh, m);` |
| [`testPreprocessing.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/preprocessing/testPreprocessing.m) | Comprehensive automated test runner for all enhancement stages. | `testPreprocessing;` |
