# System Administrator & Deployment Guide
## Explainable AI-Based Diabetic Retinopathy Screening System for Rural India
### Project Code: SIH26038 | Version: 1.0.0-Production | Date: September 2026

---

## 1. System Overview & Deployment Architecture

The **SIH26038 Retinal Screening Workstation** is designed for deployment on edge laptops and all-in-one PCs stationed in Primary Health Centres (PHCs), Community Health Centres (CHCs), Sub-Centres, and mobile telemedicine vans across India. 

Administrators are responsible for hardware commissioning, camera USB driver binding, local storage configuration, role-based access management, and optional Ayushman Bharat Digital Mission (ABDM) synchronization.

```
+---------------------------------------------------------------------------------------------------+
|                                  RURAL PHC DEPLOYMENT TOPOLOGY                                    |
+---------------------------------------------------------------------------------------------------+
|                                                                                                   |
|  [Hardware Peripherals]                                                                           |
|  +-------------------------------------+         +---------------------------------------------+  |
|  | Handheld Fundus Camera (USB / Wi-Fi)| ------> | Edge Workstation (Intel Core i5 / 8GB RAM)  |  |
|  | (Remidio NM-FOP / Forus 3nethra)    |         | Running MATLAB Runtime / SIH26038 App       |  |
|  +-------------------------------------+         +---------------------------------------------+  |
|                                                                 |                 |               |
|                                                                 v                 v               |
|                                                   [Local Encrypted DB]     [Laser / Thermal]      |
|                                                   [results/reports/]       [Patient Slip Printer] |
|                                                                 |                                 |
|                                                                 v (Optional 4G/Wi-Fi)             |
|                                                   [District Tele-Ophthalmology Cloud & ABDM]     |
+---------------------------------------------------------------------------------------------------+
```

---

## 2. Hardware Commissioning & Specifications

### 2.1 Minimum & Recommended Specifications

| Component | Minimum Specification | Recommended Specification |
| :--- | :--- | :--- |
| **Processor** | Intel Core i3 (8th Gen+) or AMD Ryzen 3 | Intel Core i5/i7 (11th Gen+) or AMD Ryzen 5 |
| **System Memory** | 4 GB RAM | 8 GB or 16 GB DDR4/DDR5 |
| **Storage** | 128 GB SSD (with 20 GB free) | 256 GB NVMe SSD |
| **Display** | $1366 \times 768$ LCD | $1920 \times 1080$ IPS (Anti-Glare) |
| **Ports** | 2x USB 3.0 / Type-C | 3x USB 3.0, 1x Ethernet RJ-45 |
| **Battery Life** | 3 hours (with field power bank) | 6+ hours battery backup |
| **Operating System**| Windows 10/11 (64-bit) or Ubuntu 20.04 | Windows 11 Enterprise (64-bit) |

### 2.2 Fundus Camera Interfacing
1. **Remidio Fundus on Phone (NM-FOP)**:
   - Connect via USB-C or Wi-Fi Direct.
   - Set camera export folder to: `C:\Users\Public\RetinaScans\Incoming\`.
   - Update `config/default_config.json` path `camera_mount_dir`.
2. **Forus 3nethra Classic**:
   - Install vendor DirectShow USB driver.
   - Configure camera acquisition in View 2 (Upload Image) dropdown.
3. **Topcon TRC-NW400**:
   - Configure DICOM auto-export over local LAN to workstation IP.

---

## 3. Installation & First-Time Setup

### 3.1 Installing MATLAB Runtime (If Running Compiled Executable)
1. Download the free MATLAB Runtime R2021b (9.11) 64-bit for Windows from MathWorks.
2. Run `MATLAB_Runtime_R2021b_win64.exe` with administrative privileges.
3. Verify environment variable:
   ```cmd
   set PATH=%PATH%;C:\Program Files\MATLAB\MATLAB Runtime\v911\runtime\win64
   ```

### 3.2 Deploying the SIH26038 Application
1. Extract the application archive into `C:\SIH26038_Capstone\`.
2. Open MATLAB (or launch the compiled `.exe`):
   ```matlab
   cd('C:\SIH26038_Capstone');
   startup
   ```
3. Verify that all 7 toolboxes and path dependencies report `[OK]`.
4. Launch the verification test suite:
   ```matlab
   main('test')
   ```

---

## 4. Configuration & Clinic Calibration

Edit [`config/default_config.json`](file:///c:/Users/Priyam/Desktop/AI/Capstone/config/default_config.json) to customize local camp metadata:

```json
{
  "deployment": {
    "campId": "PUNE-KHED-PHC-04",
    "location": "Khed Primary Health Centre",
    "district": "Pune",
    "state": "Maharashtra",
    "operator": "Rekha Sharma (ASHA ID: 841)",
    "supervising_doctor": "Dr. S. Nair, MD (Ophthal)",
    "hospital_contact": "+91-20-2567-8900"
  },
  "quality": {
    "blurThreshold": 0.35,
    "brightness": { "min": 40, "max": 215 },
    "contrast": { "min": 25.0 }
  },
  "model": {
    "architecture": "resnet50",
    "referralThreshold": 2
  }
}
```

---

## 5. Ayushman Bharat Digital Mission (ABDM) Integration

The application generates electronic health records adhering to the **Fast Healthcare Interoperability Resources (FHIR R4)** standard.

### Automated FHIR Document Structure (`results/reports/report_PATIENTID.json`)
```json
{
  "resourceType": "DiagnosticReport",
  "id": "RPT-PAT-2026-0892",
  "status": "final",
  "category": [{ "coding": [{ "system": "http://loinc.org", "code": "LP200057-0", "display": "Diabetic Retinopathy Screening" }] }],
  "code": { "coding": [{ "system": "http://snomed.info/sct", "code": "4855003", "display": "Diabetic Retinopathy" }] },
  "subject": { "reference": "Patient/PAT-2026-0892", "display": "Ramesh Kumar" },
  "conclusion": "Stage 3: Severe Non-Proliferative Diabetic Retinopathy. URGENT REFERRAL TO DISTRICT HOSPITAL REQUIRED.",
  "conclusionCode": [{ "coding": [{ "system": "http://snomed.info/sct", "code": "1551000119108", "display": "Severe nonproliferative diabetic retinopathy" }] }]
}
```

---

## 6. Backup, Recovery & Audit Maintenance

1. **Daily Camp Backup**:
   - At the end of every screening camp shift, back up the `results/` folder to an encrypted external USB drive:
     ```cmd
     robocopy C:\SIH26038_Capstone\results E:\Camp_Backups\20260908_Khed /MIR
     ```
2. **Audit Trail Archival**:
   - Clinical screening audit logs are maintained in `results/logs/system_audit.log`. Logs rotate automatically upon reaching $10\text{ MB}$.
3. **Emergency Reset**:
   - To restore factory default configuration, execute in MATLAB:
     ```matlab
     app = DRScreeningApp_exported();
     app.navigateToTab(16); % Settings
     % Click "Reset to Factory Defaults"
     ```
