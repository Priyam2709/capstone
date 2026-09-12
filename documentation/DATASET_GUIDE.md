# Dataset Guide & Ingestion Protocol: SIH26038 DR Screening System

**Smart India Hackathon Problem Statement:** SIH26038  
**Domain:** Retinal Fundus Image Repositories & Preprocessing Standards

---

## 1. Supported Clinical Fundus Datasets

The dataset loading module ([`data/loadDataset.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/data/loadDataset.m)) natively supports four globally recognized benchmark datasets widely utilized in Diabetic Retinopathy research:

| Dataset Identifier | Origin / Clinical Source | Image Modality | Native Resolution | Native CSV Columns | Public Source |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **APTOS 2019** | Aravind Eye Hospital, Tamil Nadu, India | Non-mydriatic fundus cameras across rural screening camps | Varied ($1050 \times 1050$ to $3216 \times 2136$) | `id_code`, `diagnosis` | [Kaggle APTOS 2019](https://www.kaggle.com/c/aptos2019-blindness-detection) |
| **EyePACS** | EyePACS Tele-ophthalmology Network, California, USA | Non-mydriatic digital fundus cameras (Centervue, Canon, Topcon) | High-res ($2592 \times 1944$ to $4752 \times 3168$) | `image`, `level` | [Kaggle Diabetic Retinopathy](https://www.kaggle.com/c/diabetic-retinopathy-detection) |
| **IDRiD** | Dr. Ramanjit Sihota Clinic, Nanded, Maharashtra, India | Kowa VX-10 $\alpha$ digital fundus camera ($50^\circ$ FOV) | High-res ($4288 \times 2848$) | `Image_name`, `Retinopathy_grade` | [IEEE Dataport IDRiD](https://idrid.grand-challenge.org/) |
| **Messidor / Messidor-2** | 3 French Ophthalmology Departments (Brest, Paris, Saint-Etienne) | Topcon TRC NW6 non-mydriatic camera ($45^\circ$ FOV) | $1440 \times 960$ to $2304 \times 1536$ | `Image`, `Retinopathy_grade` | [Messidor-2 Consortium](https://www.adcis.net/en/third-party/messidor2/) |

---

## 2. Directory Structure for Raw Datasets

To ingest any dataset, place the raw fundus images in `data/raw/<dataset_name>/` and the corresponding ground truth label CSV in `data/labels/<dataset_name>_labels.csv`:

```text
Capstone/
├── data/
│   ├── raw/
│   │   ├── aptos/         # e.g., 000c1434d8d7.png, 001639a390f0.png, ...
│   │   ├── eyepacs/       # e.g., 10_left.jpeg, 10_right.jpeg, ...
│   │   ├── idrid/         # e.g., IDRiD_001.jpg, IDRiD_002.jpg, ...
│   │   └── messidor/      # e.g., 20051019_38557_0100_PP.tif, ...
│   │
│   ├── labels/
│   │   ├── aptos_labels.csv     # Columns: id_code, diagnosis
│   │   ├── eyepacs_labels.csv   # Columns: image, level
│   │   ├── idrid_labels.csv     # Columns: Image_name, Retinopathy_grade
│   │   └── messidor_labels.csv  # Columns: Image, Retinopathy_grade
│   │
│   ├── loadDataset.m            # Master dataset ingestion & stratified split generator
│   ├── validateDataset.m        # Data sanitization, missing image & label checker
│   ├── displayClassDistribution.m # Class frequency table and grouped bar chart
│   └── visualizeSampleImages.m  # Representative 5-stage sample montage visualizer
```

---

## 3. Data Ingestion & Sanitization Protocol

### 1. Automatic Column Schema Detection
The loader dynamically detects column names across different conventions:
- **Image ID Columns:** `id_code`, `image`, `Image_name`, `Image`, `image_id`, `filename`.
- **Diagnosis Columns:** `diagnosis`, `level`, `Retinopathy_grade`, `dr_grade`, `label`.

### 2. Missing Image Detection
In real-world clinical datasets, CSV records occasionally refer to corrupt or omitted image files.
- [`data/validateDataset.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/data/validateDataset.m) checks whether each referenced image exists across supported extensions (`.png`, `.jpg`, `.jpeg`, `.tif`, `.bmp`).
- Missing images are flagged and logged, and excluded from training partitions to prevent runtime pipeline crashes.

### 3. Invalid Label Handling
Ground truth clinical labels must be integers within $[0, 4]$. The validation routine intercepts:
- Out-of-range numbers (e.g. $99$, $-1$)
- `NaN` or empty fields
- Non-integer floating point values
All invalid records are isolated in `report.invalidLabelList`.

---

## 4. Stratified Train / Validation / Test Splitting

Because retinal datasets in rural screening are naturally imbalanced (Stage 0 "No DR" typically represents 65–75% of captures, while Stage 4 "Proliferative DR" accounts for <5%), random partitioning can lead to zero-sample splits for severe stages.

The module implements **Stratified Partitioning**:
$$\text{Split Ratios: } \quad \text{Train} = 70\%, \quad \text{Validation} = 15\%, \quad \text{Test} = 15\%$$

For each class $c \in \{0, 1, 2, 3, 4\}$:
1. Extract all sample indices with $\text{Diagnosis} = c$.
2. Permute indices with deterministic pseudo-random seed (`config.dataset.random_seed = 42`).
3. Allocate $70\%$ to `datasetSplits.train`, $15\%$ to `datasetSplits.val`, and $15\%$ to `datasetSplits.test`.
4. Ensure every partition maintains the identical 5-class clinical distribution.

---

## 5. Visualizations & Verification

### Class Distribution Bar Chart
Exported to `results/visualizations/class_distribution_<dataset>.png`. Displays exact image counts and percentage share across all five ICDR stages for Train, Validation, and Test partitions.

### Representative Sample Montage
Exported to `results/visualizations/sample_images_<dataset>.png`. Renders high-contrast side-by-side fundus views of:
- **Stage 0:** Clear retina and healthy foveal zone
- **Stage 1:** Red dot microaneurysms
- **Stage 2:** Blot hemorrhages and yellow hard exudates
- **Stage 3:** Extensive quadrant hemorrhages (4-2-1 rule)
- **Stage 4:** Neovascularization fronds and fibrous proliferation
