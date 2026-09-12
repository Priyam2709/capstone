# Clinical Diagnostic Reporting Guide: SIH26038

**Smart India Hackathon Problem Statement:** SIH26038  
**Module Name:** Automated Diagnostic Report Generation (`reports/`)  
**Target Beneficiaries:** Rural Diabetic Patients, ASHA/ANM Community Workers, District Hospital Tele-Ophthalmology Units

---

## 1. Clinical Context & Public Health Imperative

In rural screening camps across India, verbal communication of screening results often fails due to low health literacy, patient anxiety, or fragmented follow-up care. A **physical or digitally verifiable clinical screening document** is vital to ensure:
1. **Unambiguous Triage Communication:** The patient understands whether their condition requires immediate hospital travel or routine monitoring.
2. **Accelerated Tele-Consultation:** Consulting vitreoretinal specialists at District Hospitals can review a standardized A4 document containing the raw fundus, enhanced view, and Grad-CAM lesion heatmap in $< 30$ seconds.
3. **Medicolegal Accountability:** Every AI diagnosis is recorded with software version, date, operator ID, and a dedicated physician sign-off line complying with the National Programme for Control of Blindness and Visual Impairment (NPCB&VI).

---

## 2. Standardized Clinical Report Architecture

The report exported via [`reports/exportReportPDF.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/exportReportPDF.m) adheres to a structured, 8-section layout:

```
┌────────────────────────────────────────────────────────────────────────┐
│ 1. INSTITUTIONAL HEADER & SIH26038 CREDENTIALING BANNER               │
├────────────────────────────────────────────────────────────────────────┤
│ 2. PATIENT DEMOGRAPHICS & CLINICAL METADATA                            │
│    ID, Name, Age/Sex, Camp Location, ASHA Operator, Diabetes Duration  │
├────────────────────────────────────────────────────────────────────────┤
│ 3. TRI-IMAGE DIAGNOSTIC GALLERY                                        │
│    [1. Raw Field Capture]  [2. Enhanced CLAHE]  [3. Grad-CAM Overlay] │
│    IQA Score: 88.4/100 (Good) | Blur: 142.5 | Lum: 118.2 | Contr: 34.1  │
├────────────────────────────────────────────────────────────────────────┤
│ 4. DIAGNOSTIC PREDICTION & CONFIDENCE BANNER                           │
│    Severity: ICDR Grade 2 (Moderate NPDR) | Confidence: 94.2%          │
│    Referral: SIGHT-THREATENING DR DETECTED (REFERRAL MANDATORY)        │
├────────────────────────────────────────────────────────────────────────┤
│ 5. PROBABILITY DISTRIBUTION (0:No DR | 1:Mild | 2:Mod | 3:Sev | 4:PDR) │
├────────────────────────────────────────────────────────────────────────┤
│ 6. EXPLAINABLE AI (XAI) LESION LOCALIZATION & CLINICAL JUSTIFICATION   │
│    Focus: Superior-Temporal (Coverage: 4.2%) | Microaneurysms, Exudates│
│    Plain-language guidance for health worker & patient                 │
├────────────────────────────────────────────────────────────────────────┤
│ 7. REFERRAL URGENCY & ACTION PLAN                                      │
│    Timeline: Tele-ophthalmologist review within 30 days                │
├────────────────────────────────────────────────────────────────────────┤
│ 8. MEDICOLEGAL DISCLAIMER & PHYSICIAN SIGN-OFF BLOCK                   │
│    Examining Worker: ________________  Verifying Doctor: _____________ │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Tele-Ophthalmology Referral Urgency Tiers

| Stage Code | Diagnostic Stage | Referral Requirement | Referral Timeline | Recommended Clinical Action |
| :---: | :--- | :---: | :--- | :--- |
| **0** | No DR | **No** | 12 Months | Routine annual screening at local PHC; glycemic lifestyle counseling. |
| **1** | Mild NPDR | **No** | 6 Months | Repeat non-mydriatic screening in 6 months; monitor fasting blood glucose. |
| **2** | Moderate NPDR | **YES** | 30 Days | Non-urgent referral: forward clinical PDF report to District Hospital tele-network. |
| **3** | Severe NPDR | **YES** | 7–14 Days | Priority referral: patient transported for dilated slit-lamp biomicroscopy & laser triage. |
| **4** | Proliferative DR | **YES** | $<48$ Hours | **EMERGENCY REFERRAL:** Immediate hospital admission to prevent tractional retinal detachment. |

---

## 4. Cohort Summary & District Roster Compilation

[`reports/compileCohortReport.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/compileCohortReport.m) aggregates all screenings conducted across a village camp:
- Compiles statistical stage distribution (e.g., 68% No DR, 14% Mild, 12% Moderate, 4% Severe, 2% PDR).
- Automatically generates `district_referral_roster.csv` identifying patients requiring hospital transport, contact numbers, diagnosis, and follow-up deadlines.

---

## 5. API Reference: Functions in `reports/`

| Function | Primary Purpose | Syntax |
| :--- | :--- | :--- |
| [`generatePatientReport.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/generatePatientReport.m) | Master report orchestrator compiling patient data, images, IQA, prediction, and XAI. | `res = generatePatientReport(pat, q, enh, pred, xai);` |
| [`exportReportPDF.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/exportReportPDF.m) | Renders and exports high-resolution vector PDF and companion PNG image. | `pdfPath = exportReportPDF(compiled, enhResult);` |
| [`compileCohortReport.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/compileCohortReport.m) | Aggregates camp cohort screening totals and exports district hospital referral roster. | `[sum, roster] = compileCohortReport(records, campId);` |
| [`testReportGenerator.m`](file:///c:/Users/Priyam/Desktop/AI/Capstone/reports/testReportGenerator.m) | Comprehensive automated test runner verifying routine, referral, and emergency scenarios. | `testReportGenerator;` |
