# Deep Learning Training & Transfer Learning Guide: SIH26038

**Smart India Hackathon Problem Statement:** SIH26038  
**Module Name:** Deep Learning Training Module (`training/`, `classification/`)  
**Domain:** Convolutional Neural Networks, Transfer Learning & Medical Image Classification

---

## 1. Transfer Learning Model Backbones

Training deep convolutional neural networks from scratch on medical imaging datasets requires millions of labeled examples to avoid severe overfitting. The system employs **Transfer Learning from ImageNet**, replacing the classification head with a 5-class retinal diagnostic output layer while preserving rich low- and mid-level feature extractors (edges, textures, vascular contours).

The system supports four state-of-the-art backbones selectable via [`config/default_config.json`](file:///c:/Users/Priyam/Desktop/AI/Capstone/config/default_config.json):

| Architecture Backbone | Depth | Parameter Count | Target Conv Layer (for Grad-CAM) | Primary Rural Deployment Setting |
| :--- | :---: | :---: | :--- | :--- |
| **ResNet-18** | 18 layers | ~11.7M | `res5b_relu` | Mobile screening vans, fast real-time triage |
| **ResNet-50** | 50 layers | ~25.6M | `activation_49_relu` | Primary Health Centre (PHC) desktop stations, benchmark accuracy |
| **EfficientNet-B0** | Compound | ~5.3M | `top_activation` | High-accuracy edge screening with minimal parameter budget |
| **MobileNetV2** | Inverted Residual | ~3.5M | `out_relu` | Battery-powered handheld fundus cameras, ultra-low memory |

---

## 2. Network Surgery & Architecture Customization

[`classification/buildModel.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/buildModel.m) performs automated layer surgery:

```
[Pretrained Backbone Feature Extractor]
(ResNet50 / EfficientNet-B0 / MobileNetV2)
                   │
                   ▼
       [Global Average Pooling]
                   │
                   ▼
     [Dropout Layer (Rate: 0.40)]
     (Combats over-reliance on single lesion clusters)
                   │
                   ▼
   [Fully Connected Layer (5 Outputs)]
   (Weight & Bias Learn Rate Multiplier: 10x)
                   │
                   ▼
      [Softmax Probability Layer]
                   │
                   ▼
   [Classification Output (ICDR Stages 0 - 4)]
```

---

## 3. Data Augmentation Strategy

Fundus images possess unique spatial and anatomical symmetries. [`training/configureAugmenter.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/training/configureAugmenter.m) configures label-preserving transformations:
- **Horizontal & Vertical Reflection:** Left/right eye symmetry and upper/lower vascular arcade invariance.
- **Random Rotation ($[-25^\circ, +25^\circ]$):** Simulates natural head tilts on portable fundus chin-rests.
- **Random Scaling ($[0.90, 1.10]$):** Simulates variation in patient axial eye length and optical camera zoom.
- **Random Shear ($[-5^\circ, +5^\circ]$):** Simulates slight off-axis retinal imaging.

---

## 4. Hyperparameters & Optimization Protocol

| Hyperparameter | Configuration Value | Justification |
| :--- | :--- | :--- |
| **Optimizer** | Adam ($\beta_1=0.9, \beta_2=0.999$) | Adaptive learning rates provide smooth convergence across sparse lesion gradients. |
| **Initial Learning Rate** | $1 \times 10^{-4}$ ($0.0001$) | Low learning rate prevents disruptive weight updates to pretrained ImageNet features. |
| **Learning Rate Schedule** | Piecewise Decay | Multiplies LR by factor $0.1$ every $10$ epochs to refine decision boundaries. |
| **Batch Size** | $32$ (Desktop) / $16$ (Rural Edge) | Accommodates standard edge GPU/CPU memory envelopes. |
| **Maximum Epochs** | $25 - 30$ | Sufficient for convergence with early stopping intervention. |
| **Early Stopping** | Patience $= 5$ validation cycles | Terminates training if validation loss fails to decrease for 5 consecutive checks. |
| **L2 Regularization** | $1 \times 10^{-4}$ | Prevents weight explosion and promotes weight sparsity. |

---

## 5. Multi-Class Performance Metrics & Visualizations

The evaluation suite in [`classification/evaluateMetrics.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/classification/evaluateMetrics.m) reports:
- **Overall Accuracy:** Percentage of correct diagnostic predictions across all stages.
- **Confusion Matrix ($5 \times 5$):** Exported to `results/visualizations/confusion_matrix_<arch>.png`. Details true vs. predicted classifications with cell-level counts and row-normalized sensitivities.
- **Per-Class Precision, Recall, Specificity & F1-Score:** Crucial for monitoring false negatives in sight-threatening stages (Stages 2, 3, and 4).
- **One-vs-Rest ROC Curves & Multi-Class AUC:** Exported to `results/visualizations/roc_curves_<arch>.png`. Analyzes diagnostic discrimination thresholds independently for each severity stage.

---

## 6. Model Checkpointing & Serialization

- [`models/saveModelCheckpoint.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/models/saveModelCheckpoint.m) serializes model weights, best epoch metadata, validation loss, and class definitions into `models/checkpoints/` and `models/<arch>_best.mat`.
- [`models/loadModelCheckpoint.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/models/loadModelCheckpoint.m) handles automated reloading for single-image inference and clinical deployment.
