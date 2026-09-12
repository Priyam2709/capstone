"""
generate_diagrams.py
Generates clean, publication-quality SVG visual diagrams for:
1. System Architecture Diagram (architecture_diagram.svg)
2. Rural Screening Workflow Flowchart (workflow_flowchart.svg)

Using only standard library Python for 100% zero-dependency execution.
Author: SIH26038 Capstone Engineering Team
"""

import os

def create_architecture_svg(output_path):
    svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 800" width="1200" height="800">
  <defs>
    <linearGradient id="bgGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#0f172a" />
      <stop offset="100%" stop-color="#1e293b" />
    </linearGradient>
    <linearGradient id="cardGrad1" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#1e3a8a" />
      <stop offset="100%" stop-color="#172554" />
    </linearGradient>
    <linearGradient id="cardGrad2" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#065f46" />
      <stop offset="100%" stop-color="#064e3b" />
    </linearGradient>
    <linearGradient id="cardGrad3" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#854d0e" />
      <stop offset="100%" stop-color="#713f12" />
    </linearGradient>
    <linearGradient id="cardGrad4" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#581c87" />
      <stop offset="100%" stop-color="#3b0764" />
    </linearGradient>
    <linearGradient id="cardGrad5" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#9f1239" />
      <stop offset="100%" stop-color="#881337" />
    </linearGradient>
    <filter id="shadow" x="-5%" y="-5%" width="110%" height="115%">
      <feDropShadow dx="0" dy="6" stdDeviation="6" flood-color="#000" flood-opacity="0.45" />
    </filter>
    <marker id="arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38bdf8" />
    </marker>
  </defs>

  <!-- Background -->
  <rect width="1200" height="800" fill="url(#bgGrad)" />

  <!-- Header Banner -->
  <rect x="40" y="30" width="1120" height="75" rx="12" fill="#1e293b" stroke="#334155" stroke-width="1.5" />
  <text x="60" y="65" font-family="Arial, sans-serif" font-size="22" font-weight="bold" fill="#38bdf8">
    SIH26038: Explainable AI-Based Diabetic Retinopathy Screening System
  </text>
  <text x="60" y="90" font-family="Arial, sans-serif" font-size="13" fill="#94a3b8">
    Modular MATLAB Software Architecture for Rural Primary Health Centres (PHCs) &amp; Mobile Camps
  </text>

  <!-- Left Column: Ingestion & Utils -->
  <g transform="translate(40, 130)">
    <rect width="250" height="630" rx="12" fill="#1e293b" stroke="#3b82f6" stroke-width="1.5" filter="url(#shadow)" />
    <rect width="250" height="42" rx="12" fill="url(#cardGrad1)" />
    <text x="20" y="27" font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="#fff">1. DATA &amp; UTILITIES</text>
    
    <!-- Cards inside column -->
    <rect x="15" y="60" width="220" height="85" rx="8" fill="#0f172a" stroke="#334155" />
    <text x="25" y="82" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#38bdf8">Configuration Engine</text>
    <text x="25" y="100" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• config/default_config.json</text>
    <text x="25" y="116" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• utils/loadConfig.m</text>
    <text x="25" y="132" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• utils/saveConfig.m</text>

    <rect x="15" y="160" width="220" height="110" rx="8" fill="#0f172a" stroke="#334155" />
    <text x="25" y="182" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#38bdf8">Dataset Management</text>
    <text x="25" y="200" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• APTOS 2019 / EyePACS</text>
    <text x="25" y="216" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• IDRiD / Messidor-2</text>
    <text x="25" y="232" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• data/loadDataset.m</text>
    <text x="25" y="248" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• data/validateDataset.m</text>

    <rect x="15" y="285" width="220" height="150" rx="8" fill="#0f172a" stroke="#334155" />
    <text x="25" y="307" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#38bdf8">Core Helpers</text>
    <text x="25" y="325" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• utils/logger.m (INFO/WARN)</text>
    <text x="25" y="341" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• utils/loadImage.m (Cropping)</text>
    <text x="25" y="357" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• utils/saveOutput.m</text>
    <text x="25" y="373" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• utils/errorHandler.m</text>
    <text x="25" y="389" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• utils/getProjectRoot.m</text>

    <rect x="15" y="450" width="220" height="155" rx="8" fill="#0f172a" stroke="#334155" />
    <text x="25" y="472" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#38bdf8">Testing &amp; Simulation</text>
    <text x="25" y="490" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• testing/runAllTests.m</text>
    <text x="25" y="506" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• testing/TestUtils.m</text>
    <text x="25" y="522" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• testing/TestQualityAssessment.m</text>
    <text x="25" y="538" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• simulink/setupSimulinkModel.m</text>
    <text x="25" y="554" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• simulink/rural_screening_sim.slx</text>
  </g>

  <!-- Middle Left Column: Quality & Preprocessing -->
  <g transform="translate(325, 130)">
    <rect width="260" height="630" rx="12" fill="#1e293b" stroke="#10b981" stroke-width="1.5" filter="url(#shadow)" />
    <rect width="260" height="42" rx="12" fill="url(#cardGrad2)" />
    <text x="20" y="27" font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="#fff">2. QUALITY &amp; ENHANCE</text>

    <rect x="15" y="60" width="230" height="250" rx="8" fill="#0f172a" stroke="#334155" />
    <text x="25" y="82" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#34d399">Image Quality Gate (IQA)</text>
    <text x="25" y="100" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• assessImageQuality.m</text>
    <text x="25" y="118" font-family="Arial, sans-serif" font-size="10" fill="#94a3b8">  - Blur (Laplacian Var >= 100)</text>
    <text x="25" y="134" font-family="Arial, sans-serif" font-size="10" fill="#94a3b8">  - Brightness (40-215 scale)</text>
    <text x="25" y="150" font-family="Arial, sans-serif" font-size="10" fill="#94a3b8">  - Contrast (RMS >= 25)</text>
    <text x="25" y="166" font-family="Arial, sans-serif" font-size="10" fill="#94a3b8">  - Noise (Immerkaer &lt;= 20)</text>
    <text x="25" y="182" font-family="Arial, sans-serif" font-size="10" fill="#94a3b8">  - Sharpness (Tenengrad >= 150)</text>
    <text x="25" y="202" font-family="Arial, sans-serif" font-size="10" font-weight="bold" fill="#f59e0b">Classification Categories:</text>
    <text x="25" y="220" font-family="Arial, sans-serif" font-size="10" fill="#10b981">  ✓ Good (>=75)</text>
    <text x="25" y="236" font-family="Arial, sans-serif" font-size="10" fill="#eab308">  ✓ Needs Enhancement (50-74)</text>
    <text x="25" y="252" font-family="Arial, sans-serif" font-size="10" fill="#ef4444">  ✗ Retake Image (&lt;50)</text>

    <rect x="15" y="330" width="230" height="270" rx="8" fill="#0f172a" stroke="#334155" />
    <text x="25" y="352" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#34d399">Retinal Preprocessing</text>
    <text x="25" y="372" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• preprocessPipeline.m</text>
    <text x="25" y="390" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• applyMedianFilter.m (Denoise)</text>
    <text x="25" y="408" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• correctIllumination.m (Gaussian)</text>
    <text x="25" y="426" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• applyCLAHE.m (L*a*b* Luminance)</text>
    <text x="25" y="444" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• compareEnhancement.m</text>
    <text x="25" y="470" font-family="Arial, sans-serif" font-size="10" font-weight="bold" fill="#94a3b8">Quantitative Verification:</text>
    <text x="25" y="488" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• PSNR Metric (Target > 28 dB)</text>
    <text x="25" y="504" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• SSIM Index (Target > 0.85)</text>
  </g>

  <!-- Middle Right Column: Deep Learning & XAI -->
  <g transform="translate(620, 130)">
    <rect width="260" height="630" rx="12" fill="#1e293b" stroke="#a855f7" stroke-width="1.5" filter="url(#shadow)" />
    <rect width="260" height="42" rx="12" fill="url(#cardGrad4)" />
    <text x="20" y="27" font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="#fff">3. AI &amp; EXPLAINABILITY</text>

    <rect x="15" y="60" width="230" height="260" rx="8" fill="#0f172a" stroke="#334155" />
    <text x="25" y="82" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#c084fc">Transfer Learning Models</text>
    <text x="25" y="100" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• ResNet-18 / ResNet-50</text>
    <text x="25" y="116" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• EfficientNet-B0</text>
    <text x="25" y="132" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• MobileNetV2 (Low-power edge)</text>
    <text x="25" y="152" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• classification/buildModel.m</text>
    <text x="25" y="168" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• training/trainModel.m</text>
    <text x="25" y="184" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• classification/predictDR.m</text>
    <text x="25" y="200" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• classification/evaluateMetrics.m</text>
    <text x="25" y="222" font-family="Arial, sans-serif" font-size="10" font-weight="bold" fill="#f43f5e">5-Stage ICDR Classes:</text>
    <text x="25" y="238" font-family="Arial, sans-serif" font-size="9" fill="#94a3b8">0:No DR | 1:Mild | 2:Mod | 3:Sev | 4:PDR</text>

    <rect x="15" y="340" width="230" height="260" rx="8" fill="#0f172a" stroke="#334155" />
    <text x="25" y="362" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#c084fc">Explainable AI (Grad-CAM)</text>
    <text x="25" y="382" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• computeGradCAM.m</text>
    <text x="25" y="400" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• overlayHeatmap.m (Jet blend)</text>
    <text x="25" y="418" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• generateExplanation.m</text>
    <text x="25" y="440" font-family="Arial, sans-serif" font-size="10" font-weight="bold" fill="#94a3b8">Clinical Value:</text>
    <text x="25" y="458" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• Highlights microaneurysms</text>
    <text x="25" y="474" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• Identifies hard lipid exudates</text>
    <text x="25" y="490" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• Detects neovascularization</text>
    <text x="25" y="506" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• Plain-language justification</text>
  </g>

  <!-- Right Column: UI & Clinical Delivery -->
  <g transform="translate(915, 130)">
    <rect width="245" height="630" rx="12" fill="#1e293b" stroke="#f43f5e" stroke-width="1.5" filter="url(#shadow)" />
    <rect width="245" height="42" rx="12" fill="url(#cardGrad5)" />
    <text x="20" y="27" font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="#fff">4. CLINICAL OUTPUT</text>

    <rect x="15" y="60" width="215" height="260" rx="8" fill="#0f172a" stroke="#334155" />
    <text x="25" y="82" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#fb7185">Clinical Reports</text>
    <text x="25" y="102" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• generatePatientReport.m</text>
    <text x="25" y="120" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• exportReportPDF.m</text>
    <text x="25" y="142" font-family="Arial, sans-serif" font-size="10" font-weight="bold" fill="#94a3b8">Report Contents:</text>
    <text x="25" y="160" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• Patient &amp; Camp Demographics</text>
    <text x="25" y="176" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• Original vs Enhanced Fundus</text>
    <text x="25" y="192" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• Grad-CAM Saliency Overlay</text>
    <text x="25" y="208" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• Quality Index &amp; AI Prediction</text>
    <text x="25" y="224" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• Referral Triage Recommendation</text>
    <text x="25" y="240" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• Doctor Verification Signature</text>

    <rect x="15" y="340" width="215" height="260" rx="8" fill="#0f172a" stroke="#334155" />
    <text x="25" y="362" font-family="Arial, sans-serif" font-size="12" font-weight="bold" fill="#fb7185">App Designer GUI</text>
    <text x="25" y="382" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• gui/launchApp.m</text>
    <text x="25" y="400" font-family="Arial, sans-serif" font-size="10" fill="#cbd5e1">• DRScreeningApp_exported.m</text>
    <text x="25" y="422" font-family="Arial, sans-serif" font-size="10" font-weight="bold" fill="#94a3b8">9 Touch-Enabled Tabs:</text>
    <text x="25" y="440" font-family="Arial, sans-serif" font-size="9" fill="#94a3b8">1. Dashboard    2. Upload Image</text>
    <text x="25" y="456" font-family="Arial, sans-serif" font-size="9" fill="#94a3b8">3. Quality IQA  4. Enhancement</text>
    <text x="25" y="472" font-family="Arial, sans-serif" font-size="9" fill="#94a3b8">5. Prediction   6. Explainability</text>
    <text x="25" y="488" font-family="Arial, sans-serif" font-size="9" fill="#94a3b8">7. Reports      8. Settings</text>
    <text x="25" y="504" font-family="Arial, sans-serif" font-size="9" fill="#94a3b8">9. Results Audit Trail</text>
  </g>

  <!-- Flow Arrows connecting columns -->
  <line x1="290" y1="210" x2="325" y2="210" stroke="#38bdf8" stroke-width="2.5" marker-end="url(#arrow)" />
  <line x1="585" y1="465" x2="620" y2="465" stroke="#38bdf8" stroke-width="2.5" marker-end="url(#arrow)" />
  <line x1="880" y1="210" x2="915" y2="210" stroke="#38bdf8" stroke-width="2.5" marker-end="url(#arrow)" />
  <line x1="880" y1="465" x2="915" y2="465" stroke="#38bdf8" stroke-width="2.5" marker-end="url(#arrow)" />
</svg>"""
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(svg)
    print(f"Exported architecture diagram: {output_path}")

def create_workflow_svg(output_path):
    svg = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1100" width="1000" height="1100">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#0b132b" />
      <stop offset="100%" stop-color="#1c2541" />
    </linearGradient>
    <linearGradient id="stepGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#1e293b" />
      <stop offset="100%" stop-color="#0f172a" />
    </linearGradient>
    <filter id="boxShadow" x="-5%" y="-5%" width="110%" height="120%">
      <feDropShadow dx="0" dy="4" stdDeviation="4" flood-color="#000" flood-opacity="0.4" />
    </filter>
    <marker id="flowArrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38bdf8" />
    </marker>
    <marker id="alertArrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#ef4444" />
    </marker>
  </defs>

  <!-- Background -->
  <rect width="1000" height="1100" fill="url(#bg)" />

  <!-- Header -->
  <rect x="50" y="30" width="900" height="70" rx="10" fill="#1e293b" stroke="#334155" />
  <text x="500" y="62" font-family="Arial, sans-serif" font-size="20" font-weight="bold" fill="#38bdf8" text-anchor="middle">
    SIH26038: Rural Health Centre Retinal Screening Workflow
  </text>
  <text x="500" y="85" font-family="Arial, sans-serif" font-size="12" fill="#94a3b8" text-anchor="middle">
    Standardized Protocol from Village Patient Arrival to Referral &amp; Tele-Ophthalmology
  </text>

  <!-- Step 1: Patient Arrival -->
  <rect x="300" y="130" width="400" height="60" rx="30" fill="#0284c7" stroke="#38bdf8" stroke-width="2" filter="url(#boxShadow)" />
  <text x="500" y="157" font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="#fff" text-anchor="middle">
    1. Patient Registration &amp; Vitals at Rural PHC
  </text>
  <text x="500" y="175" font-family="Arial, sans-serif" font-size="11" fill="#e0f2fe" text-anchor="middle">
    ASHA worker records Age, Gender, Blood Glucose &amp; Diabetes History
  </text>

  <line x1="500" y1="190" x2="500" y2="225" stroke="#38bdf8" stroke-width="2" marker-end="url(#flowArrow)" />

  <!-- Step 2: Fundus Image Capture -->
  <rect x="275" y="225" width="450" height="65" rx="8" fill="url(#stepGrad)" stroke="#38bdf8" stroke-width="1.5" filter="url(#boxShadow)" />
  <text x="500" y="252" font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="#38bdf8" text-anchor="middle">
    2. Non-Mydriatic Fundus Camera Acquisition
  </text>
  <text x="500" y="272" font-family="Arial, sans-serif" font-size="11" fill="#cbd5e1" text-anchor="middle">
    utils/loadImage.m • Auto-crop black border • Normalize RGB • Resize [224, 224]
  </text>

  <line x1="500" y1="290" x2="500" y2="330" stroke="#38bdf8" stroke-width="2" marker-end="url(#flowArrow)" />

  <!-- Step 3: Decision Gate: Image Quality Assessment -->
  <polygon points="500,330 680,390 500,450 320,390" fill="#1e293b" stroke="#f59e0b" stroke-width="2" filter="url(#boxShadow)" />
  <text x="500" y="384" font-family="Arial, sans-serif" font-size="13" font-weight="bold" fill="#f59e0b" text-anchor="middle">
    3. Image Quality Gate (IQA)
  </text>
  <text x="500" y="402" font-family="Arial, sans-serif" font-size="10" fill="#94a3b8" text-anchor="middle">
    Blur, Brightness, Contrast, Noise, Sharpness
  </text>

  <!-- Branch: Retake Image (< 50) -->
  <path d="M 680 390 L 840 390 L 840 257 L 725 257" fill="none" stroke="#ef4444" stroke-width="2" stroke-dasharray="5,5" marker-end="url(#alertArrow)" />
  <rect x="730" y="365" width="130" height="40" rx="4" fill="#450a0a" stroke="#ef4444" />
  <text x="795" y="382" font-family="Arial, sans-serif" font-size="10" font-weight="bold" fill="#fca5a5" text-anchor="middle">Score &lt; 50 (Fail)</text>
  <text x="795" y="396" font-family="Arial, sans-serif" font-size="9" fill="#fca5a5" text-anchor="middle">Retake Fundus Image</text>

  <line x1="500" y1="450" x2="500" y2="485" stroke="#38bdf8" stroke-width="2" marker-end="url(#flowArrow)" />
  <rect x="420" y="455" width="160" height="20" rx="4" fill="#064e3b" />
  <text x="500" y="469" font-family="Arial, sans-serif" font-size="10" font-weight="bold" fill="#34d399" text-anchor="middle">Score >= 50 (Pass/Enhance)</text>

  <!-- Step 4: Preprocessing & Enhancement -->
  <rect x="275" y="485" width="450" height="65" rx="8" fill="url(#stepGrad)" stroke="#10b981" stroke-width="1.5" filter="url(#boxShadow)" />
  <text x="500" y="512" font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="#34d399" text-anchor="middle">
    4. Retinal Preprocessing &amp; CLAHE Enhancement
  </text>
  <text x="500" y="532" font-family="Arial, sans-serif" font-size="11" fill="#cbd5e1" text-anchor="middle">
    Median Filter (Denoise) + Gaussian Background Leveling + L*a*b* CLAHE
  </text>

  <line x1="500" y1="550" x2="500" y2="585" stroke="#38bdf8" stroke-width="2" marker-end="url(#flowArrow)" />

  <!-- Step 5: Deep Learning Classification -->
  <rect x="275" y="585" width="450" height="65" rx="8" fill="url(#stepGrad)" stroke="#a855f7" stroke-width="1.5" filter="url(#boxShadow)" />
  <text x="500" y="612" font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="#c084fc" text-anchor="middle">
    5. Deep Learning DR Stage Inference
  </text>
  <text x="500" y="632" font-family="Arial, sans-serif" font-size="11" fill="#cbd5e1" text-anchor="middle">
    ResNet-50 / MobileNetV2 • 5 Classes • Softmax Probabilities • Latency &lt; 0.5s
  </text>

  <line x1="500" y1="650" x2="500" y2="685" stroke="#38bdf8" stroke-width="2" marker-end="url(#flowArrow)" />

  <!-- Step 6: Explainable AI -->
  <rect x="275" y="685" width="450" height="65" rx="8" fill="url(#stepGrad)" stroke="#ec4899" stroke-width="1.5" filter="url(#boxShadow)" />
  <text x="500" y="712" font-family="Arial, sans-serif" font-size="14" font-weight="bold" fill="#f472b6" text-anchor="middle">
    6. Explainable AI: Grad-CAM Saliency Engine
  </text>
  <text x="500" y="732" font-family="Arial, sans-serif" font-size="11" fill="#cbd5e1" text-anchor="middle">
    Heatmap Overlay + Focal Lesion Localization + Clinical Text Justification
  </text>

  <line x1="500" y1="750" x2="500" y2="785" stroke="#38bdf8" stroke-width="2" marker-end="url(#flowArrow)" />

  <!-- Step 7: Clinical Decision Gate -->
  <polygon points="500,785 670,845 500,905 330,845" fill="#1e293b" stroke="#38bdf8" stroke-width="2" filter="url(#boxShadow)" />
  <text x="500" y="839" font-family="Arial, sans-serif" font-size="13" font-weight="bold" fill="#38bdf8" text-anchor="middle">
    7. Triage Referral Decision
  </text>
  <text x="500" y="857" font-family="Arial, sans-serif" font-size="10" fill="#94a3b8" text-anchor="middle">
    Threshold: Stage &gt;= 2 (Moderate+)
  </text>

  <!-- Left Branch: Routine Follow-up (Stages 0 & 1) -->
  <path d="M 330 845 L 200 845 L 200 940" fill="none" stroke="#10b981" stroke-width="2" marker-end="url(#flowArrow)" />
  <rect x="60" y="940" width="280" height="105" rx="8" fill="#064e3b" stroke="#10b981" stroke-width="1.5" />
  <text x="200" y="965" font-family="Arial, sans-serif" font-size="13" font-weight="bold" fill="#34d399" text-anchor="middle">
    Routine Care (No / Mild DR)
  </text>
  <text x="200" y="985" font-family="Arial, sans-serif" font-size="10" fill="#e0f2fe" text-anchor="middle">
    • Print screening summary for patient
  </text>
  <text x="200" y="1002" font-family="Arial, sans-serif" font-size="10" fill="#e0f2fe" text-anchor="middle">
    • PHC blood sugar &amp; diet counseling
  </text>
  <text x="200" y="1020" font-family="Arial, sans-serif" font-size="10" fill="#e0f2fe" text-anchor="middle">
    • Schedule 6-12 month review
  </text>

  <!-- Right Branch: Urgent Referral (Stages 2, 3, 4) -->
  <path d="M 670 845 L 800 845 L 800 940" fill="none" stroke="#ef4444" stroke-width="2" marker-end="url(#flowArrow)" />
  <rect x="660" y="940" width="280" height="105" rx="8" fill="#450a0a" stroke="#ef4444" stroke-width="1.5" />
  <text x="800" y="965" font-family="Arial, sans-serif" font-size="13" font-weight="bold" fill="#f87171" text-anchor="middle">
    Priority Specialist Referral
  </text>
  <text x="800" y="985" font-family="Arial, sans-serif" font-size="10" fill="#fef2f2" text-anchor="middle">
    • Generate Clinical PDF Report with XAI
  </text>
  <text x="800" y="1002" font-family="Arial, sans-serif" font-size="10" fill="#fef2f2" text-anchor="middle">
    • Tele-consultation with District Hospital
  </text>
  <text x="800" y="1020" font-family="Arial, sans-serif" font-size="10" fill="#fef2f2" text-anchor="middle">
    • Fast-track for laser / anti-VEGF
  </text>
</svg>"""
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(svg)
    print(f"Exported workflow diagram: {output_path}")

if __name__ == '__main__':
    doc_dir = os.path.dirname(os.path.abspath(__file__))
    arch_svg = os.path.join(doc_dir, 'architecture_diagram.svg')
    work_svg = os.path.join(doc_dir, 'workflow_flowchart.svg')
    create_architecture_svg(arch_svg)
    create_workflow_svg(work_svg)
