# Explainable AI (Grad-CAM) Guide: SIH26038

**Smart India Hackathon Problem Statement:** SIH26038  
**Module Name:** Explainable AI & Lesion Localization Module (`explainability/`)  
**Domain:** Medical Interpretability, Gradient-Weighted Class Activation Mapping & Clinical Decision Support

---

## 1. Clinical Rationale & Rural Operational Need

In rural healthcare camps, artificial intelligence cannot operate as a silent "black box." Primary eye care workers (ASHA/ANM) and remote consulting ophthalmologists need visual evidence that the model is reacting to genuine retinal pathology rather than image artifacts (camera dust on lens, corneal reflections, or illumination halos).

The **Explainable AI (XAI) module** bridges the gap between deep neural networks and clinical trust by:
1. **Visualizing Attentional Focus:** Generating 2D **Grad-CAM** saliency heatmaps highlighting the exact spatial regions driving the model's prediction.
2. **Localizing Microvascular Lesions:** Segmenting and drawing bounding boxes around salient clusters of **microaneurysms**, **hard lipid exudates**, **blot hemorrhages**, and **neovascularization**.
3. **Translating Features to Clinical English:** Generating natural language clinical justifications tailored to the education level of field workers.
4. **Providing Medicolegal Audit Trails:** Exporting multi-panel diagnostic graphics into permanent screening archives and tele-ophthalmology referral packages.

---

## 2. Mathematical Principles of Grad-CAM

Gradient-weighted Class Activation Mapping computes the gradient of the class score $y^c$ (before softmax) with respect to feature activation maps $A^k$ of the network's final convolutional layer (`activation_49_relu` in ResNet-50, `top_activation` in EfficientNet-B0, `out_relu` in MobileNetV2):

### Step 1: Neuron Importance Weight Computation
Global average pooling over width $u$ and height $v$:
$$\alpha_k^c = \frac{1}{Z} \sum_{i=1}^u \sum_{j=1}^v \frac{\partial y^c}{\partial A_{i,j}^k}$$
Where $Z = u \times v$ represents the spatial dimensions of the feature map, and $\alpha_k^c$ captures the clinical importance of feature map $k$ for diagnostic class $c$.

### Step 2: Rectified Feature Combination
A weighted linear combination is computed and filtered through a Rectified Linear Unit (ReLU) to isolate positive contributions toward the predicted stage:
$$L_{\text{Grad-CAM}}^c = \text{ReLU}\left( \sum_k \alpha_k^c A^k \right)$$

### Step 3: Spatial Normalization & Bilinear Upsampling
$$H(x,y) = \frac{L_{\text{Grad-CAM}}^c(x,y) - \min(L)}{\max(L) - \min(L) + \epsilon}$$
Upsampled from the convolutional grid ($7 \times 7$ or $14 \times 14$) to the input fundus resolution ($224 \times 224$ or $512 \times 512$).

---

## 3. Lesion Localization & Anatomical Quadrant Mapping

[`explainability/segmentSalientLesions.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/segmentSalientLesions.m) performs connected-component analysis on high-activation regions ($H \ge 0.52$):

```
                        [Grad-CAM Saliency Map]
                                   │
                           Threshold (H >= 0.52)
                                   │
                       Binary Saliency Connected Components
                                   │
              ┌────────────────────┴────────────────────┐
              ▼                                         ▼
     Centroid & Bounding Box                   Anatomical Quadrant
    [r_min, c_min, width, height]                 Localization
              │                                         │
              └────────────────────┬────────────────────┘
                                   │
                                   ▼
        [Annotated Fundus Image + Dominant Quadrant Classification]
```

### Anatomical Retinal Quadrants:
1. **Central Macular Zone:** Radius within $18\%$ of image center (risk of Diabetic Macular Edema).
2. **Superior-Temporal Quadrant:** Upper lateral arcade (frequent site for branch vein occlusions and exudates).
3. **Superior-Nasal Quadrant:** Upper medial field.
4. **Inferior-Temporal Quadrant:** Lower lateral arcade (common site for early blot hemorrhages).
5. **Inferior-Nasal Quadrant:** Lower medial field.

---

## 4. Multi-Panel Explanation Figure Format

[`explainability/exportExplanationFigure.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/exportExplanationFigure.m) exports a standardized 4-panel graphic:

| Panel | Content | Clinical Purpose |
| :---: | :--- | :--- |
| **1** | **Annotated Fundus** | Enhanced fundus image with color-coded bounding boxes surrounding focal lesion clusters. |
| **2** | **Grad-CAM Heatmap** | Continuous $[0, 1]$ saliency heatmap with colorbar, showing model feature gradient intensity. |
| **3** | **Heatmap Overlay** | Smooth alpha-blended fusion ($50\%$ transparency) over retinal fundus. |
| **4** | **Clinical Narrative Card** | Diagnostic stage, confidence, dominant quadrant, lesion biomarkers, and referral triage guidance. |

---

## 5. API Reference: Functions in `explainability/`

| Function | Description | Syntax |
| :--- | :--- | :--- |
| [`computeGradCAM.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/computeGradCAM.m) | Master Grad-CAM generator returning heatmap, overlay, lesion stats, and explanation. | `xai = computeGradCAM(model, img, stage, cfg);` |
| [`segmentSalientLesions.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/segmentSalientLesions.m) | Localizes focal lesion clusters, extracts bounding boxes, and identifies dominant quadrant. | `[annImg, stats] = segmentSalientLesions(img, heat);` |
| [`overlayHeatmap.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/overlayHeatmap.m) | Blends heatmap over fundus image with smooth background falloff. | `blended = overlayHeatmap(img, heat, 0.5, 'jet');` |
| [`generateExplanation.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/generateExplanation.m) | Generates plain-language clinical justification for rural health workers. | `exp = generateExplanation(stage, conf, stats);` |
| [`exportExplanationFigure.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/exportExplanationFigure.m) | Renders and exports 4-panel diagnostic graphic to PNG/PDF. | `fig = exportExplanationFigure(img, xai, 'xai.png');` |
| [`testExplainability.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/explainability/testExplainability.m) | Comprehensive automated test runner across all 5 clinical DR stages. | `testExplainability;` |
