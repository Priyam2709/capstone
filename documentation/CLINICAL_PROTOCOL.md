# Clinical Protocol: Explainable AI Diabetic Retinopathy Screening for Rural India

**Project Identifier:** SIH26038  
**Domain:** Community Ophthalmology, Rural Primary Healthcare & Tele-medicine  
**Target Beneficiaries:** Rural diabetic populations across Primary Health Centres (PHCs) & Mobile Screening Camps

---

## 1. Clinical Background & Public Health Imperative

Diabetic Retinopathy (DR) is the principal microvascular complication of diabetes mellitus and the leading cause of preventable blindness among working-age adults globally. In India, an estimated **77 million people live with diabetes**, a figure projected to exceed 100 million by 2030. 

### The Rural India Healthcare Challenge
1. **Specialist Deficit:** Over 70% of India's population resides in rural and peri-urban regions, whereas over 80% of ophthalmologists practice in tier-1 and tier-2 cities.
2. **Asymptomatic Early Stages:** DR progresses silently without visual loss until advanced proliferative stages or diabetic macular edema (DME) occurs.
3. **Screening Backlog:** Routine annual screening of all rural diabetic patients is physically impossible without autonomous and semi-autonomous AI triage at the Primary Health Centre (PHC) level.
4. **Field Operational Barriers:** Handheld non-mydriatic fundus cameras in village camps encounter frequent image artifacts:
   - Corneal flash reflections and halo glare
   - Media opacity from co-existing cataracts
   - Blurring from involuntary eye movement (saccades)
   - Low illumination due to undilated pupils in daylight camps

---

## 2. International Clinical Diabetic Retinopathy (ICDR) Disease Scale

The system standardizes classification across the recognized 5-stage ICDR scale:

| Stage Code | Clinical Stage | Pathological Signs on Fundus Examination | Screening Camp Action Protocol |
| :---: | :--- | :--- | :--- |
| **0** | **No DR** | No visible microvascular abnormalities; clear macula. | Routine annual follow-up at local PHC; glycemic & BP counseling. |
| **1** | **Mild NPDR** | Microaneurysms only (isolated tiny red dots). | Semi-annual follow-up (6 months); diabetes lifestyle control. |
| **2** | **Moderate NPDR** | Microaneurysms, blot hemorrhages, hard lipid exudates, cotton-wool spots, but less than Severe NPDR. | **Referral Required:** Tele-ophthalmology review within 30 days. |
| **3** | **Severe NPDR** | **The 4-2-1 Rule:** Severe hemorrhages in all 4 quadrants, definite venous beading in $\ge 2$ quadrants, or IRMA in $\ge 1$ quadrant. | **Urgent Referral:** District Eye Hospital within 1–2 weeks for laser/anti-VEGF evaluation. |
| **4** | **Proliferative DR (PDR)** | Neovascularization (NVD/NVE), vitreous hemorrhage, preretinal hemorrhage, fibrovascular proliferation. | **Emergency Referral:** Tertiary eye care center within 48 hours to prevent imminent tractional retinal detachment. |

---

## 3. Retinal Image Quality Assessment (IQA) Protocol

To prevent erroneous AI classifications on corrupt or substandard images, every fundus capture undergoes automated multi-metric quality verification prior to classification:

```
[Captured Fundus Image]
          │
          ▼
┌─────────────────────────────────────────────────────────┐
│ 1. Laplacian Variance Blur Check     (Thresh: >= 100)   │
│ 2. Retinal Mean Brightness Analysis  (Thresh: 40 - 215) │
│ 3. RMS Dynamic Contrast Evaluation   (Thresh: >= 25)    │
│ 4. Immerkaer Noise Estimation        (Thresh: <= 20)    │
│ 5. Tenengrad Edge Gradient Sharpness (Thresh: >= 150)   │
└─────────────────────────────────────────────────────────┘
          │
    Composite Score (0 - 100)
          ├── [>= 75] ─────────► "Good"               ──► Proceed to Inference
          ├── [50 - 74] ───────► "Needs Enhancement"  ──► Auto-CLAHE + Filter
          └── [< 50] ──────────► "Retake Image"       ──► Audible Alert to Field Worker
```

---

## 4. Role of Explainable AI (Grad-CAM) in Rural Triage

In safety-critical medical deployment, black-box deep learning models cannot be adopted without interpretability:
- **Trust for Community Health Workers:** ASHA and ANM workers can visually verify that the model is reacting to true retinal pathology (e.g. exudates, hemorrhages) rather than camera dust or optic disc edges.
- **Actionable Tele-consultation:** Referring ophthalmologists receive a combined PDF report displaying original fundus, CLAHE-enhanced contrast, and Grad-CAM activation heatmap, cutting remote review time by >60%.
- **Medicolegal Compliance:** Saliency overlays provide an auditable clinical record for every diagnosis rendered.
