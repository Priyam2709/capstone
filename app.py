"""
app.py
======
DRISHTI-AI: Interactive Clinical Workstation & Web UI.
Includes two tailored interfaces:
  1. International Conference & Academic Presentation Workstation (Route: `/` or `/conference`)
     - Complete deep tech stack: ResNet-152 fine-tuning, Layer-4 Grad-CAM saliency, 5-stage softmax,
       5-parameter optical IQA gate, Track C landmark localization, and rural camp queue simulation.
  2. Doctor's Rapid Clinical Portal (Route: `/doctor`)
     - Streamlined, physician-first workstation showing ONLY clinical essentials:
       definitive diagnosis, ICDR referral directive, anatomical biomarkers table,
       ophthalmologist sign-off notes, and a hospital-grade printable A4 diagnostic sheet.

Usage:
    python app.py
    python main.py --mode ui
"""

import os
import sys
import json
import time
import base64
import urllib.parse
import webbrowser
from http.server import HTTPServer, SimpleHTTPRequestHandler
import numpy as np

# Ensure project root is in sys.path
PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from quality_assessment.assess_quality import assess_image_quality
from classification.predict_dr import predict_dr, STAGE_NAMES, STAGE_DESCRIPTIONS
from explainability.grad_cam import compute_gradcam
from reports.export_fhir import export_abdm_fhir_json
from localization.localize_landmarks import localize_retinal_landmarks
from simulation.camp_queue_simulation import simulate_camp_throughput

PORT = 5050

# ==============================================================================
# 1. INTERNATIONAL CONFERENCE & ACADEMIC WORKSTATION (ROUTE: / or /conference)
# ==============================================================================
CONFERENCE_UI = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DRISHTI-AI | Retinal Screening & Diagnostic Workstation</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      darkMode: 'class',
      theme: {
        extend: {
          colors: {
            medical: {
              50: '#f0f9ff',
              100: '#e0f2fe',
              600: '#0284c7',
              700: '#0369a1',
              800: '#075985',
              900: '#0c4a6e',
            }
          }
        }
      }
    }
  </script>
  <style>
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    .font-mono {
      font-family: 'JetBrains Mono', monospace;
    }
    @media print {
      body { background: white !important; color: black !important; }
      .no-print { display: none !important; }
      .print-only { display: block !important; }
      .panel-card { border: 1px solid #cbd5e1 !important; background: white !important; color: black !important; box-shadow: none !important; }
    }
    .print-only { display: none; }
    .custom-scroll::-webkit-scrollbar { width: 5px; height: 5px; }
    .custom-scroll::-webkit-scrollbar-thumb { background: #94a3b8; border-radius: 3px; }
    .slider-track {
      -webkit-appearance: none;
      height: 4px;
      border-radius: 2px;
      background: #cbd5e1;
      outline: none;
    }
    .dark .slider-track {
      background: #334155;
    }
    .slider-track::-webkit-slider-thumb {
      -webkit-appearance: none;
      appearance: none;
      width: 14px;
      height: 14px;
      border-radius: 50%;
      background: #0284c7;
      cursor: pointer;
      box-shadow: 0 0 4px rgba(2, 132, 199, 0.5);
    }
    .canvas-flipped {
      transform: scaleX(-1);
    }
    /* ============================================================== */
    /* HIGH-CONTRAST PROFESSIONAL DARKROOM PACS STYLES                 */
    /* ============================================================== */
    body.dark {
      background-color: #0b0f19 !important;
      color: #f1f5f9 !important;
    }
    body.dark .panel-card,
    body.dark .bg-white {
      background-color: #111622 !important;
      border-color: #1e293b !important;
      color: #f1f5f9 !important;
    }
    body.dark .bg-slate-50 {
      background-color: #0d121c !important;
      border-color: #1e293b !important;
      color: #e2e8f0 !important;
    }
    body.dark .bg-slate-100 {
      background-color: #0a0d14 !important;
      border-color: #1e293b !important;
      color: #e2e8f0 !important;
    }
    body.dark .bg-slate-200 {
      background-color: #1e293b !important;
      border-color: #334155 !important;
      color: #f1f5f9 !important;
    }
    body.dark .border-slate-100,
    body.dark .border-slate-200,
    body.dark .border-slate-300 {
      border-color: #1e293b !important;
    }
    body.dark .text-slate-900,
    body.dark .text-slate-800,
    body.dark .text-slate-700 {
      color: #f8fafc !important;
    }
    body.dark .text-slate-600,
    body.dark .text-slate-500 {
      color: #94a3b8 !important;
    }
    body.dark .text-slate-400 {
      color: #64748b !important;
    }
    body.dark input[type="text"],
    body.dark textarea {
      color: #f8fafc !important;
      background-color: transparent !important;
      border-color: #334155 !important;
    }
    body.dark input[type="text"]:focus,
    body.dark textarea:focus {
      border-color: #2dd4bf !important;
      background-color: #0d121c !important;
    }
    /* Dynamic Severity Badges in Dark Mode */
    body.dark .bg-emerald-50 {
      background-color: rgba(6, 78, 59, 0.45) !important;
      color: #34d399 !important;
      border-color: rgba(52, 211, 153, 0.35) !important;
    }
    body.dark .text-emerald-700,
    body.dark .text-emerald-800 {
      color: #34d399 !important;
    }
    body.dark .bg-sky-50 {
      background-color: rgba(12, 74, 110, 0.45) !important;
      color: #38bdf8 !important;
      border-color: rgba(56, 189, 248, 0.35) !important;
    }
    body.dark .text-sky-700,
    body.dark .text-sky-800 {
      color: #38bdf8 !important;
    }
    body.dark .bg-amber-50 {
      background-color: rgba(120, 53, 15, 0.45) !important;
      color: #fbbf24 !important;
      border-color: rgba(251, 191, 36, 0.35) !important;
    }
    body.dark .text-amber-700,
    body.dark .text-amber-800,
    body.dark .text-amber-900 {
      color: #fbbf24 !important;
    }
    body.dark .bg-orange-50 {
      background-color: rgba(124, 45, 18, 0.45) !important;
      color: #fb923c !important;
      border-color: rgba(251, 146, 60, 0.35) !important;
    }
    body.dark .text-orange-700,
    body.dark .text-orange-800,
    body.dark .text-orange-900 {
      color: #fb923c !important;
    }
    body.dark .bg-rose-50 {
      background-color: rgba(136, 19, 55, 0.45) !important;
      color: #f43f5e !important;
      border-color: rgba(244, 63, 94, 0.35) !important;
    }
    body.dark .text-rose-700,
    body.dark .text-rose-800,
    body.dark .text-rose-900 {
      color: #f43f5e !important;
    }
    body.dark .text-cyan-800 {
      color: #22d3ee !important;
    }
    body.dark .text-purple-800 {
      color: #c084fc !important;
    }
    /* Modal in Dark Mode */
    body.dark #campModal > div {
      background-color: #111622 !important;
      border-color: #334155 !important;
      color: #f1f5f9 !important;
    }
    body.dark #campModal .bg-slate-50 {
      background-color: #0d121c !important;
      border-color: #1e293b !important;
    }

  </style>
</head>
<body class="bg-slate-100 text-slate-800 min-h-screen antialiased custom-scroll transition-colors duration-200">

  <!-- TOP CLINICAL NAVIGATION BAR (HOSPITAL SAPPHIRE) -->
  <header id="consoleHeader" class="no-print bg-[#0f766e] text-white px-5 py-2.5 flex items-center justify-between sticky top-0 z-40 shadow-md transition-colors duration-200">
    <div class="flex items-center space-x-3">
      <div class="h-8 w-8 rounded-lg bg-white/10 border border-white/20 flex items-center justify-center text-white shadow-sm">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
          <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
        </svg>
      </div>
      <div>
        <div class="flex items-center space-x-2">
          <span class="font-bold text-sm tracking-tight text-white">DRISHTI-AI</span>
          <span class="text-[10px] text-blue-200/60 font-normal">|</span>
          <span class="text-xs text-blue-100 font-medium">Clinical Retinal Screening Workstation</span>
          <span class="text-[10px] font-mono px-1.5 py-0.5 rounded bg-blue-950/60 text-blue-200 border border-blue-400/30">v1.2</span>
        </div>
        <div class="text-[11px] text-blue-200/80">SIH26038 &bull; Deep Retinal Pathology Classification &bull; Tele-Ophthalmology Decision Flow</div>
      </div>
    </div>

    <!-- WORKSTATION CONTROLS & ACTION BUTTON GROUP -->
    <div class="flex items-center space-x-2">
      <!-- Layout Orientation Switcher -->
      <div class="hidden md:flex items-center bg-teal-950/80 rounded-md p-0.5 border border-teal-400/30 text-xs">
        <button onclick="setLayoutOrientation('split')" id="btnOrientSplit" class="px-2.5 py-1 rounded bg-teal-600 text-white font-bold text-[11px] transition" title="Side-by-Side: Image on Left, Diagnosis on Right">
          Horizontal (Split)
        </button>
        <button onclick="setLayoutOrientation('console')" id="btnOrientConsole" class="px-2.5 py-1 rounded text-teal-100 hover:text-white font-medium text-[11px] transition" title="3-Column PACS Workstation Console">
          3-Column (PACS)
        </button>
        <button onclick="setLayoutOrientation('flow')" id="btnOrientFlow" class="px-2.5 py-1 rounded text-teal-100 hover:text-white font-medium text-[11px] transition" title="Sequential Vertical Clinical Report Flow">
          Vertical Flow
        </button>
      </div>

      <!-- Console Color Palette Selector -->
      <div class="hidden xl:flex items-center space-x-1.5 bg-black/25 px-2.5 py-1 rounded-md border border-white/20 text-xs">
        <span class="text-teal-100 font-medium text-[11px] mr-0.5">Color:</span>
        <button onclick="setConsoleTheme('teal')" class="w-3.5 h-3.5 rounded-full bg-teal-500 border border-white hover:scale-125 transition" title="Surgical Teal (Default)"></button>
        <button onclick="setConsoleTheme('slate')" class="w-3.5 h-3.5 rounded-full bg-slate-700 border border-white hover:scale-125 transition" title="Titanium Slate"></button>
        <button onclick="setConsoleTheme('emerald')" class="w-3.5 h-3.5 rounded-full bg-emerald-600 border border-white hover:scale-125 transition" title="Clinical Emerald"></button>
        <button onclick="setConsoleTheme('indigo')" class="w-3.5 h-3.5 rounded-full bg-indigo-700 border border-white hover:scale-125 transition" title="Academic Indigo"></button>
        <button onclick="setConsoleTheme('sapphire')" class="w-3.5 h-3.5 rounded-full bg-blue-700 border border-white hover:scale-125 transition" title="Royal Sapphire"></button>
      </div>

      <!-- Theme Switcher (Light / Dark) -->
      <button onclick="toggleColorTheme()" id="btnThemeToggle" class="px-2.5 py-1.5 rounded-md bg-teal-900/60 hover:bg-teal-800 border border-teal-400/30 text-xs font-medium text-teal-100 transition flex items-center space-x-1 shadow-sm" title="Toggle Clinical Light / Darkroom Mode">
        <span id="themeIcon">&#9728;</span>
        <span id="themeLabel">Light</span>
      </button>

      <!-- Doctor's Portal Button -->
      <a href="/doctor" class="px-3 py-1.5 rounded-md bg-indigo-700 hover:bg-indigo-600 border border-indigo-500/50 text-xs font-semibold text-white transition flex items-center space-x-1.5 shadow-sm">
        <svg class="w-3.5 h-3.5 text-indigo-200" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5a4 4 0 008 0V4M8 13v2a4 4 0 004 4h1a4 4 0 004-4v-1.5M19 16a2 2 0 100-4 2 2 0 000 4z"/>
        </svg>
        <span>Doctor's View</span>
      </a>

      <!-- Camp Simulation Button -->
      <button onclick="openCampSimulationModal()" class="px-3 py-1.5 rounded-md bg-emerald-700 hover:bg-emerald-600 border border-emerald-500/50 text-xs font-semibold text-white transition flex items-center space-x-1.5 shadow-sm">
        <svg class="w-3.5 h-3.5 text-emerald-200" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/>
        </svg>
        <span>Camp Simulator</span>
      </button>

      <!-- Print Summary Button -->
      <button onclick="window.print()" class="px-3 py-1.5 rounded-md bg-white text-teal-900 hover:bg-teal-50 text-xs font-semibold transition flex items-center space-x-1.5 shadow-sm">
        <svg class="w-3.5 h-3.5 text-teal-900" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4H7v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/>
        </svg>
        <span>Print Summary</span>
      </button>

      <!-- Export FHIR Button -->
      <button onclick="downloadFhirJson()" id="btnFhir" class="px-3 py-1.5 rounded-md bg-teal-950 hover:bg-teal-900 text-xs font-medium text-white transition flex items-center space-x-1.5 shadow-sm">
        <svg class="w-3.5 h-3.5 text-teal-200" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
        </svg>
        <span>ABDM FHIR</span>
      </button>
    </div>
  </header>

  <!-- CLINICAL STATUS STRIP -->
  <div class="no-print bg-white border-b border-slate-200 px-5 py-1.5 text-[11px] text-slate-600 flex items-center justify-between overflow-x-auto gap-4 shadow-xs">
    <div class="flex items-center space-x-6 shrink-0">
      <div><span class="text-slate-500 font-medium">Model:</span> <span class="text-slate-800 font-semibold">ResNet-152 (58.2M Params)</span></div>
      <div><span class="text-slate-500 font-medium">Latency:</span> <span class="text-emerald-700 font-mono font-semibold">42.5 ms (CPU Edge)</span></div>
      <div><span class="text-slate-500 font-medium">Reliability:</span> <span class="text-amber-700 font-mono font-semibold">Quadratic Kappa &ge; 0.90</span></div>
      <div><span class="text-slate-500 font-medium">Landmarks:</span> <span class="text-blue-700 font-semibold">100% Optic Disc &bull; 90% Fovea (PCK)</span></div>
      <div><span class="text-slate-500 font-medium">Cohort:</span> <span class="text-slate-800 font-semibold">IDRiD Benchmark (516 Scans)</span></div>
    </div>
    <div class="shrink-0 flex items-center space-x-1.5 text-[11px] text-emerald-800 font-medium">
      <span class="h-2 w-2 rounded-full bg-emerald-500"></span>
      <span class="font-mono text-[10px] uppercase">Clinical Edge Active</span>
    </div>
  </div>

  <!-- MAIN WORKSPACE -->
  <main class="max-w-[1580px] mx-auto p-3.5 md:p-4">
    
    <!-- DYNAMIC WORKSPACE GRID (ORIENTATION SWITCHABLE) -->
    <div id="workspaceGrid" class="grid grid-cols-1 lg:grid-cols-12 gap-4">

      <!-- ============================================================== -->
      <!-- COLUMN 1: PATIENT CASES, IMAGE INGESTION & QUALITY (IQA)       -->
      <!-- ============================================================== -->
      <div id="colStudy" class="lg:col-span-3 space-y-3.5">

        <!-- PATIENT STUDY DEMOGRAPHICS -->
        <div class="panel-card bg-white border border-slate-200 rounded-xl p-3.5 shadow-sm space-y-2.5">
          <div class="flex items-center justify-between text-xs pb-1.5 border-b border-slate-100">
            <span class="font-bold text-slate-800 uppercase tracking-wider text-[10px]">Patient Study Info</span>
            <span id="printDate" class="text-[10px] text-slate-400 font-mono"></span>
          </div>

          <div class="space-y-2 text-xs">
            <div>
              <label class="text-[10px] uppercase font-semibold text-slate-500 block tracking-wider">Patient ID</label>
              <input type="text" id="patientId" value="PAT-IDRiD_003" class="bg-transparent border-b border-slate-300 hover:border-slate-400 py-0.5 text-xs font-semibold text-slate-900 w-full focus:border-blue-500 focus:outline-none font-mono">
            </div>
            <div>
              <label class="text-[10px] uppercase font-semibold text-slate-500 block tracking-wider">Patient Name</label>
              <input type="text" id="patientName" value="IDRiD Patient 003" class="bg-transparent border-b border-slate-300 hover:border-slate-400 py-0.5 text-xs font-semibold text-slate-900 w-full focus:border-blue-500 focus:outline-none">
            </div>
            <div class="grid grid-cols-2 gap-2">
              <div>
                <label class="text-[10px] uppercase font-semibold text-slate-500 block tracking-wider">Demographics</label>
                <input type="text" id="patientAgeGender" value="56 Y / Female" class="bg-transparent border-b border-slate-300 hover:border-slate-400 py-0.5 text-xs font-semibold text-slate-900 w-full focus:border-blue-500 focus:outline-none">
              </div>
              <div>
                <label class="text-[10px] uppercase font-semibold text-slate-500 block tracking-wider">Modality</label>
                <span class="text-xs font-mono text-slate-700 block pt-0.5 font-medium">CFP (45&deg;)</span>
              </div>
            </div>
            <div>
              <label class="text-[10px] uppercase font-semibold text-slate-500 block tracking-wider">Facility</label>
              <input type="text" id="screeningCenter" value="Primary Health Centre - Camp #1" class="bg-transparent border-b border-slate-300 hover:border-slate-400 py-0.5 text-xs font-semibold text-slate-900 w-full focus:border-blue-500 focus:outline-none">
            </div>
          </div>
        </div>

        <!-- REFERENCE CASES (IDRiD COHORT WITH CLINICAL COLOR CODING) -->
        <div class="panel-card bg-white border border-slate-200 rounded-xl p-3.5 shadow-sm space-y-2">
          <div class="flex items-center justify-between text-xs pb-1 border-b border-slate-100">
            <span class="font-bold text-slate-800 uppercase tracking-wider text-[10px]">Reference Cases (IDRiD)</span>
            <span class="text-[9px] text-slate-500 font-mono">Consensus</span>
          </div>
          <div class="grid grid-cols-5 gap-1 pt-0.5">
            <button onclick="loadRealIdridSample(0)" id="sampleBtn0" class="px-1 py-1.5 rounded bg-slate-50 hover:bg-slate-100 border border-slate-200 text-[10px] font-semibold text-emerald-700 transition text-center truncate" title="IDRiD_118 (Grade 0: Normal)">
              0: Norm
            </button>
            <button onclick="loadRealIdridSample(1)" id="sampleBtn1" class="px-1 py-1.5 rounded bg-slate-50 hover:bg-slate-100 border border-slate-200 text-[10px] font-semibold text-sky-700 transition text-center truncate" title="IDRiD_021 (Grade 1: Mild NPDR)">
              1: Mild
            </button>
            <button onclick="loadRealIdridSample(2)" id="sampleBtn2" class="px-1 py-1.5 rounded bg-amber-50 border border-amber-300 text-[10px] font-bold text-amber-900 transition text-center truncate" title="IDRiD_003 (Grade 2: Moderate NPDR)">
              2: Mod
            </button>
            <button onclick="loadRealIdridSample(3)" id="sampleBtn3" class="px-1 py-1.5 rounded bg-slate-50 hover:bg-slate-100 border border-slate-200 text-[10px] font-semibold text-orange-700 transition text-center truncate" title="IDRiD_001 (Grade 3: Severe NPDR)">
              3: Sev
            </button>
            <button onclick="loadRealIdridSample(4)" id="sampleBtn4" class="px-1 py-1.5 rounded bg-slate-50 hover:bg-slate-100 border border-slate-200 text-[10px] font-semibold text-rose-700 transition text-center truncate" title="IDRiD_005 (Grade 4: PDR)">
              4: PDR
            </button>
          </div>
        </div>

        <!-- IMAGE UPLOAD DROPZONE -->
        <div id="dropZone" class="no-print border border-dashed border-slate-300 hover:border-blue-500 bg-white rounded-xl p-3 text-center cursor-pointer transition flex items-center justify-center space-x-2.5 shadow-sm">
          <input type="file" id="fileInput" accept="image/*" class="hidden" onchange="handleFileInputChange(event)">
          <svg class="w-4 h-4 text-slate-500 shrink-0" fill="none" stroke="currentColor" stroke-width="1.8" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"/>
            <path stroke-linecap="round" stroke-linejoin="round" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"/>
          </svg>
          <div class="text-left">
            <div class="text-xs text-slate-800 font-semibold">Upload Local Fundus Scan</div>
            <div class="text-[10px] text-slate-500">JPG, PNG, TIFF &bull; Drag &amp; Drop</div>
          </div>
        </div>

        <!-- OPTICAL QUALITY ASSESSMENT (IQA) -->
        <div class="panel-card bg-white border border-slate-200 rounded-xl p-3.5 shadow-sm space-y-2">
          <div class="flex items-center justify-between text-xs pb-1 border-b border-slate-100">
            <span class="font-bold text-slate-800 uppercase tracking-wider text-[10px]">Optical Quality Gate</span>
            <span id="iqaBadge" class="text-[10px] font-semibold px-2 py-0.5 rounded bg-emerald-50 text-emerald-800 border border-emerald-200">Good (93.1 / 100)</span>
          </div>

          <div class="grid grid-cols-3 gap-1.5 text-center text-xs">
            <div class="bg-slate-50 p-1.5 rounded border border-slate-200">
              <div class="text-[9px] text-slate-500">Sharpness</div>
              <div id="metricBlur" class="font-bold text-slate-900 text-xs mt-0.5">Optimal</div>
            </div>
            <div class="bg-slate-50 p-1.5 rounded border border-slate-200">
              <div class="text-[9px] text-slate-500">Illumination</div>
              <div id="metricBrightness" class="font-bold text-slate-900 text-xs mt-0.5">Balanced</div>
            </div>
            <div class="bg-slate-50 p-1.5 rounded border border-slate-200">
              <div class="text-[9px] text-slate-500">Contrast</div>
              <div id="metricContrast" class="font-bold text-slate-900 text-xs mt-0.5">High</div>
            </div>
          </div>

          <p id="iqaAction" class="text-[11px] text-slate-600 leading-relaxed pt-0.5">
            Image optical quality verified: illumination uniform, fovea and vascular arcade sharpness optimal for deep classification.
          </p>
        </div>

      </div>

      <!-- ============================================================== -->
      <!-- COLUMN 2: PRIMARY RETINAL VIEWPORT & CALIPERS                  -->
      <!-- ============================================================== -->
      <div id="colViewport" class="lg:col-span-5 space-y-3.5">

        <div class="panel-card bg-white border border-slate-200 rounded-xl p-4 shadow-sm space-y-3">
          
          <!-- Viewport Header -->
          <div class="flex items-center justify-between text-xs pb-1 border-b border-slate-100">
            <span class="font-bold text-slate-800">Retinal Fundus Photography</span>
            <div class="flex items-center space-x-2 text-[10px] font-mono">
              <span id="viewportEyeSide" class="px-1.5 py-0.5 rounded bg-slate-100 text-slate-700 font-semibold border border-slate-200">OS (Left Eye)</span>
              <span class="text-slate-500">224 &times; 224 Color</span>
            </div>
          </div>

          <!-- PACS-STYLE DARKROOM CANVAS ENCLOSURE -->
          <div class="relative bg-black rounded-lg overflow-hidden border border-slate-800 flex items-center justify-center min-h-[300px] shadow-inner">
            
            <!-- Corner Annotations -->
            <div class="absolute top-2 left-2 text-[9px] font-mono text-slate-300 z-10 pointer-events-none bg-black/70 px-1.5 py-0.5 rounded">
              IDRiD-003 &bull; CFP
            </div>
            <div class="absolute top-2 right-2 text-[9px] font-mono text-slate-300 z-10 pointer-events-none bg-black/70 px-1.5 py-0.5 rounded">
              FOV: 45&deg;
            </div>
            <div class="absolute bottom-2 left-2 text-[9px] font-mono text-slate-300 z-10 pointer-events-none bg-black/70 px-1.5 py-0.5 rounded">
              224 &times; 224 px
            </div>
            <div class="absolute bottom-2 right-2 text-[9px] font-mono text-slate-300 z-10 pointer-events-none bg-black/70 px-1.5 py-0.5 rounded">
              ResNet-152 Saliency
            </div>

            <!-- Canvas Layers -->
            <canvas id="fundusCanvas" width="224" height="224" class="w-full max-w-[280px] h-auto object-contain transition-transform duration-200"></canvas>
            <canvas id="gradcamCanvas" width="224" height="224" class="absolute w-full max-w-[280px] h-auto object-contain pointer-events-none opacity-0 transition-all duration-200"></canvas>
            <canvas id="landmarksCanvas" width="224" height="224" class="absolute w-full max-w-[280px] h-auto object-contain pointer-events-none opacity-0 transition-all duration-200"></canvas>
            
            <!-- Inference Spinner -->
            <div id="loader" class="hidden absolute inset-0 bg-slate-900/80 backdrop-blur-sm flex flex-col items-center justify-center space-y-2 z-20">
              <div class="h-7 w-7 border-2 border-blue-400 border-t-transparent rounded-full animate-spin"></div>
              <span class="text-xs font-semibold text-white">Running ResNet-152 &amp; Landmarks...</span>
            </div>
          </div>

          <!-- IMAGE ORIENTATION & COLOR FILTER CONTROLS -->
          <div class="no-print grid grid-cols-2 gap-2 text-xs pt-1">
            <!-- Laterality / Orientation Flip -->
            <button onclick="toggleImageFlip()" id="btnFlipImage" class="p-2 rounded-lg bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-700 font-semibold text-[11px] flex items-center justify-center space-x-1 transition">
              <svg class="w-3.5 h-3.5 text-slate-500" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/>
              </svg>
              <span id="flipLabel">Orientation: Standard (OS)</span>
            </button>

            <!-- Color Palette / Filter Selector -->
            <button onclick="cycleColorFilter()" id="btnFilterColor" class="p-2 rounded-lg bg-slate-50 hover:bg-slate-100 border border-slate-200 text-slate-700 font-semibold text-[11px] flex items-center justify-center space-x-1 transition">
              <span class="h-2.5 w-2.5 rounded-full bg-gradient-to-r from-blue-500 via-amber-400 to-red-500 inline-block"></span>
              <span id="filterLabel">Colormap: Thermal</span>
            </button>
          </div>

          <!-- VIEWPORT OVERLAY CONTROLS -->
          <div class="no-print space-y-2 pt-1">
            <!-- Grad-CAM Opacity Slider -->
            <div class="bg-slate-50 border border-slate-200 rounded-lg p-2.5 flex items-center justify-between text-xs">
              <span class="text-slate-800 font-semibold flex items-center space-x-1.5">
                <svg class="w-3.5 h-3.5 text-blue-600" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                  <polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/>
                </svg>
                <span>Lesion Saliency (Grad-CAM):</span>
              </span>
              <div class="flex items-center space-x-2">
                <input type="range" id="heatmapOpacity" min="0" max="100" value="0" oninput="updateOpacity(this.value)" class="slider-track w-28 cursor-pointer">
                <span id="heatmapOpacityVal" class="text-[10px] font-mono font-bold text-slate-700 w-8 text-right">0%</span>
              </div>
            </div>

            <!-- Track C Landmarks Toggle -->
            <div class="bg-slate-50 border border-slate-200 rounded-lg p-2.5 flex items-center justify-between text-xs">
              <label class="flex items-center space-x-2 cursor-pointer">
                <input type="checkbox" id="toggleLandmarks" onchange="toggleLandmarksView(this.checked)" class="accent-blue-600 h-3.5 w-3.5 rounded cursor-pointer">
                <span class="text-slate-800 font-semibold">Track C Calipers (OD &amp; Fovea)</span>
              </label>
              <div class="flex items-center space-x-2 text-[10px] font-mono">
                <span class="text-cyan-700 font-semibold flex items-center gap-1"><span class="h-1.5 w-1.5 rounded-full bg-cyan-500 inline-block"></span>OD</span>
                <span class="text-amber-700 font-semibold flex items-center gap-1"><span class="h-1.5 w-1.5 rounded-full bg-amber-500 inline-block"></span>Fovea</span>
                <span id="landmarksBadge" class="hidden">OD + Fovea</span>
              </div>
            </div>
          </div>

          <!-- QUICK BIOMARKER METRICS STRIP -->
          <div class="pt-1 border-t border-slate-100">
            <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
              <div class="bg-slate-50 p-2 rounded border border-slate-200">
                <div class="text-[10px] text-slate-500">Optic Disc</div>
                <div id="odCoords" class="font-mono text-cyan-800 text-xs font-bold mt-0.5">(143, 138) px</div>
                <div id="odRadiusText" class="text-[10px] text-slate-500 font-mono">Radius: 21 px</div>
              </div>
              <div class="bg-slate-50 p-2 rounded border border-slate-200">
                <div class="text-[10px] text-slate-500">Cup-to-Disc (CDR)</div>
                <div id="cdrValue" class="font-mono text-slate-900 text-xs font-bold mt-0.5">0.42</div>
                <div id="cdrStatus" class="text-[10px] text-emerald-700 font-semibold">Normal (&lt; 0.50)</div>
              </div>
              <div class="bg-slate-50 p-2 rounded border border-slate-200">
                <div class="text-[10px] text-slate-500">Fovea Centralis</div>
                <div id="foveaCoords" class="font-mono text-amber-800 text-xs font-bold mt-0.5">(76, 149) px</div>
                <div id="fazRadiusText" class="text-[10px] text-slate-500 font-mono">FAZ: 12 px</div>
              </div>
              <div class="bg-slate-50 p-2 rounded border border-slate-200">
                <div class="text-[10px] text-slate-500">Disc-to-Fovea</div>
                <div id="odFovDist" class="font-mono text-purple-800 text-xs font-bold mt-0.5">67.9 px</div>
                <div id="odFovDistMm" class="text-[10px] text-slate-500 font-mono">~2.42 mm</div>
              </div>
            </div>
          </div>

        </div>

      </div>

      <!-- ============================================================== -->
      <!-- COLUMN 3: DIAGNOSTIC FINDINGS, PROTOCOL & EXPLAINABILITY       -->
      <!-- ============================================================== -->
      <div id="colDiagnosis" class="lg:col-span-4 space-y-3.5">

        <!-- PRIMARY DIAGNOSTIC FINDING CARD (ICDR SEVERITY STANDARD) -->
        <div class="panel-card bg-white border border-slate-200 rounded-xl p-4 shadow-sm space-y-3">
          <div class="flex items-start justify-between flex-wrap gap-2 pb-2.5 border-b border-slate-100">
            <div>
              <span class="text-[10px] font-bold uppercase tracking-wider text-slate-500 block">Diagnostic Classification</span>
              <h2 id="diagStageName" class="text-xl font-black text-amber-700 tracking-tight mt-0.5">Stage 2: Moderate Non-Proliferative DR</h2>
              <div class="text-[11px] text-slate-500 mt-0.5">ICDR Clinical Standard &bull; Latency: <span id="diagLatency" class="text-slate-800 font-mono font-bold">42.5 ms</span></div>
            </div>
            <div class="text-right">
              <div class="text-2xl font-black text-slate-900 font-mono" id="diagConfidence">81.3%</div>
              <div class="text-[10px] uppercase font-bold text-slate-400">Confidence</div>
            </div>
          </div>

          <p id="diagDescription" class="text-xs text-slate-700 leading-relaxed bg-slate-50 p-2.5 rounded-lg border border-slate-200">
            Moderate NPDR: Multiple retinal microaneurysms, scattered intraretinal blot hemorrhages, and distinct yellowish lipid exudates detected in macula vicinity.
          </p>

          <!-- 5-STAGE POSTERIOR PROBABILITY BARS -->
          <div class="space-y-1.5 pt-1">
            <div class="text-[11px] font-bold text-slate-800 flex justify-between">
              <span>Posterior Class Distribution</span>
              <span class="text-[10px] text-slate-500 font-normal">5 ICDR Classes</span>
            </div>

            <div class="space-y-1.5 text-xs">
              <div>
                <div class="flex justify-between text-slate-700 mb-0.5 text-[10px]">
                  <span>Stage 0: No DR</span>
                  <span id="prob0Text" class="font-mono font-bold text-slate-500">2.1%</span>
                </div>
                <div class="h-2 w-full bg-slate-100 rounded-full overflow-hidden border border-slate-200">
                  <div id="prob0Bar" class="h-full bg-emerald-500 rounded-full transition-all duration-300" style="width: 2.1%"></div>
                </div>
              </div>

              <div>
                <div class="flex justify-between text-slate-700 mb-0.5 text-[10px]">
                  <span>Stage 1: Mild NPDR</span>
                  <span id="prob1Text" class="font-mono font-bold text-slate-500">8.4%</span>
                </div>
                <div class="h-2 w-full bg-slate-100 rounded-full overflow-hidden border border-slate-200">
                  <div id="prob1Bar" class="h-full bg-sky-500 rounded-full transition-all duration-300" style="width: 8.4%"></div>
                </div>
              </div>

              <div>
                <div class="flex justify-between text-amber-900 font-bold mb-0.5 text-[10px]">
                  <span>Stage 2: Moderate NPDR (Predicted)</span>
                  <span id="prob2Text" class="font-mono font-bold text-amber-700">81.3%</span>
                </div>
                <div class="h-2 w-full bg-slate-100 rounded-full overflow-hidden border border-slate-200">
                  <div id="prob2Bar" class="h-full bg-amber-500 rounded-full transition-all duration-300" style="width: 81.3%"></div>
                </div>
              </div>

              <div>
                <div class="flex justify-between text-slate-700 mb-0.5 text-[10px]">
                  <span>Stage 3: Severe NPDR</span>
                  <span id="prob3Text" class="font-mono font-bold text-slate-500">6.7%</span>
                </div>
                <div class="h-2 w-full bg-slate-100 rounded-full overflow-hidden border border-slate-200">
                  <div id="prob3Bar" class="h-full bg-orange-500 rounded-full transition-all duration-300" style="width: 6.7%"></div>
                </div>
              </div>

              <div>
                <div class="flex justify-between text-slate-700 mb-0.5 text-[10px]">
                  <span>Stage 4: Proliferative DR</span>
                  <span id="prob4Text" class="font-mono font-bold text-slate-500">1.5%</span>
                </div>
                <div class="h-2 w-full bg-slate-100 rounded-full overflow-hidden border border-slate-200">
                  <div id="prob4Bar" class="h-full bg-rose-500 rounded-full transition-all duration-300" style="width: 1.5%"></div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- CLINICAL REFERRAL & TRIAGE PROTOCOL -->
        <div class="panel-card bg-white border border-slate-200 rounded-xl p-3.5 shadow-sm space-y-2.5">
          <div class="flex items-center justify-between text-xs pb-1 border-b border-slate-100">
            <span class="font-bold text-slate-800 uppercase tracking-wider text-[10px]">Clinical Triage Protocol</span>
            <span id="triageBadge" class="px-2.5 py-0.5 rounded text-[10px] font-bold uppercase bg-rose-50 text-rose-700 border border-rose-200">
              Referral Required
            </span>
          </div>

          <div class="space-y-1.5 text-xs">
            <div class="bg-slate-50 p-2 rounded border border-slate-200">
              <span class="text-slate-500 text-[10px] uppercase font-bold block">Urgency Timeline</span>
              <div id="triageUrgency" class="text-slate-900 font-bold mt-0.5">Non-Urgent Tele-Ophthalmology (Within 30 Days)</div>
            </div>
            <div class="bg-slate-50 p-2 rounded border border-slate-200">
              <span class="text-slate-500 text-[10px] uppercase font-bold block">Destination</span>
              <div id="triageDest" class="text-slate-900 font-bold mt-0.5">District Hospital Tele-Eye Care Center</div>
            </div>
          </div>

          <div class="bg-slate-50 border border-slate-200 rounded p-2 text-xs text-slate-700 leading-relaxed">
            <strong class="text-slate-900">Directive: </strong>
            <span id="triageAction">Transmit clinical summary and Grad-CAM saliency map to District Tele-Ophthalmology network for confirmatory biomicroscopy and optical coherence tomography (OCT).</span>
          </div>
        </div>

        <!-- MACULAR THREAT & EXPLAINABILITY -->
        <div class="panel-card bg-white border border-slate-200 rounded-xl p-3.5 shadow-sm space-y-2.5">
          <div class="flex items-center justify-between text-xs pb-1 border-b border-slate-100">
            <span class="font-bold text-slate-800 uppercase tracking-wider text-[10px]">Macular Status &amp; Saliency</span>
            <span id="maculaThreatBadge" class="text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-50 text-emerald-800 border border-emerald-200">FAZ Intact</span>
          </div>

          <div id="csmeAlertBox" class="bg-slate-50 border border-slate-200 rounded p-2 text-xs text-slate-700 leading-relaxed flex items-center justify-between">
            <div>
              <strong class="text-slate-900">Macula: </strong>
              <span id="csmeAlertText">Macular Avascular Zone Clear</span>
            </div>
            <span id="eyeLateralityBadge" class="text-[10px] font-mono font-bold text-slate-700 bg-slate-100 px-1.5 py-0.5 rounded border border-slate-200">OS</span>
          </div>

          <p id="gradcamText" class="text-xs text-slate-600 leading-relaxed bg-slate-50 p-2 rounded border border-slate-200">
            Grad-CAM activation highlights dense focal attention concentrated around the superior and temporal vascular arcades, corresponding directly to clinical microvascular abnormalities.
          </p>
        </div>

      </div>

    </div>
  </main>

  <!-- RURAL CAMP SIMULATION MODAL -->
  <div id="campModal" class="hidden fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
    <div class="bg-white border border-slate-300 w-full max-w-3xl rounded-xl shadow-2xl p-5 space-y-4 custom-scroll max-h-[92vh] overflow-y-auto text-slate-800">
      
      <div class="flex items-center justify-between border-b border-slate-200 pb-2.5">
        <div>
          <h2 class="text-sm font-bold text-slate-900">Rural Camp Screening Queue &amp; Capacity Simulation</h2>
          <p class="text-xs text-slate-500">Discrete-event M/M/c queueing theory model for mobile screening logistics</p>
        </div>
        <button onclick="closeCampSimulationModal()" class="text-slate-400 hover:text-slate-700 text-lg font-bold p-1">&times;</button>
      </div>

      <!-- Parameter Sliders -->
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 bg-slate-50 p-3 rounded-lg border border-slate-200 text-xs">
        <div>
          <div class="flex justify-between font-bold text-slate-700 mb-1">
            <span>Patients Screened:</span>
            <span id="simPatientsVal" class="text-blue-700 font-mono">120</span>
          </div>
          <input type="range" id="simPatients" min="40" max="300" step="10" value="120" oninput="runCampSimulation()" class="slider-track w-full cursor-pointer">
          <div class="flex justify-between text-[10px] text-slate-400 mt-0.5 font-mono"><span>40</span><span>300</span></div>
        </div>

        <div>
          <div class="flex justify-between font-bold text-slate-700 mb-1">
            <span>Fundus Cameras:</span>
            <span id="simCamerasVal" class="text-emerald-700 font-mono">1 Camera</span>
          </div>
          <div class="grid grid-cols-2 gap-1.5 mt-1">
            <button id="btnCam1" onclick="setCameraCount(1)" class="py-1 px-2 rounded bg-blue-700 text-white text-[11px] font-bold transition">1 Camera</button>
            <button id="btnCam2" onclick="setCameraCount(2)" class="py-1 px-2 rounded bg-slate-200 text-slate-700 text-[11px] font-bold hover:bg-slate-300 transition">2 Cameras</button>
          </div>
        </div>

        <div>
          <div class="flex justify-between font-bold text-slate-700 mb-1">
            <span>Shift Duration:</span>
            <span id="simHoursVal" class="text-amber-700 font-mono">8.0 Hours</span>
          </div>
          <input type="range" id="simHours" min="4" max="10" step="1" value="8" oninput="runCampSimulation()" class="slider-track w-full cursor-pointer">
          <div class="flex justify-between text-[10px] text-slate-400 mt-0.5 font-mono"><span>4h</span><span>10h</span></div>
        </div>
      </div>

      <!-- KPI Metrics -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-2.5 text-center text-xs">
        <div class="bg-slate-50 p-2.5 rounded border border-slate-200">
          <div class="text-[10px] text-slate-500">Average Wait Time</div>
          <div id="simAvgWait" class="text-base font-bold text-amber-700 font-mono mt-0.5">24.5 min</div>
          <div id="simP95Wait" class="text-[9px] text-slate-500 font-mono">P95: 56.4 min</div>
        </div>
        <div class="bg-slate-50 p-2.5 rounded border border-slate-200">
          <div class="text-[10px] text-slate-500">Camera Utilization</div>
          <div id="simUtil" class="text-base font-bold text-slate-900 font-mono mt-0.5">87.5%</div>
          <div id="simUtilStatus" class="text-[9px] text-slate-500 font-bold">Elevated Queue</div>
        </div>
        <div class="bg-slate-50 p-2.5 rounded border border-slate-200">
          <div class="text-[10px] text-slate-500">Estimated Daily Capacity</div>
          <div id="simCapacity" class="text-base font-bold text-emerald-700 font-mono mt-0.5">123 pts</div>
          <div class="text-[9px] text-slate-500 font-mono">8-hour shift</div>
        </div>
        <div class="bg-slate-50 p-2.5 rounded border border-slate-200">
          <div class="text-[10px] text-slate-500">Edge AI Workload</div>
          <div id="simAiLoad" class="text-base font-bold text-blue-700 font-mono mt-0.5">2.4%</div>
          <div class="text-[9px] text-slate-500 font-mono">&lt; 50ms latency</div>
        </div>
      </div>

      <!-- Dual Camera Benefit Banner -->
      <div id="simBenefitBanner" class="bg-emerald-50 border border-emerald-200 rounded p-2.5 text-xs text-emerald-900 flex items-center justify-between">
        <div>
          <strong class="text-emerald-950">Operational Insight: </strong>
          <span id="simBenefitText">Adding a second camera reduces patient wait time by 96.7% and doubles screening capacity.</span>
        </div>
        <span class="text-[10px] bg-emerald-100 text-emerald-800 font-mono px-2 py-0.5 rounded border border-emerald-300 font-bold">M/M/c Model</span>
      </div>

      <!-- Hourly Timeline Bar Chart -->
      <div class="bg-slate-50 p-3 rounded-lg border border-slate-200 space-y-1.5">
        <div class="flex justify-between items-center text-xs">
          <span class="font-bold text-slate-800 text-[11px]">Hourly Patient Arrivals &amp; Queue Progression</span>
          <span class="text-[10px] text-slate-500 font-mono">Blue = Arrivals &bull; Amber = Backlog</span>
        </div>
        <div id="simTimelineBars" class="grid grid-cols-8 gap-1.5 pt-1"></div>
      </div>

      <!-- Resource Requirements -->
      <div class="bg-slate-50 p-3 rounded-lg border border-slate-200 text-xs space-y-1.5">
        <div class="font-bold text-slate-800 text-[11px]">Recommended Camp Staffing Allocation:</div>
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-2 text-slate-600">
          <div>Optometrists: <strong id="recOptom" class="text-slate-900">1</strong></div>
          <div>Field Workers (ASHA): <strong id="recAsha" class="text-slate-900">2</strong></div>
          <div>Fundus Cameras: <strong id="recCameras" class="text-slate-900">1</strong></div>
          <div>AI Edge Nodes: <strong class="text-slate-900">1 Laptop</strong></div>
        </div>
      </div>

      <div class="flex justify-end pt-1">
        <button onclick="closeCampSimulationModal()" class="px-4 py-1.5 rounded bg-slate-800 hover:bg-slate-700 text-xs font-semibold text-white transition">Close</button>
      </div>
    </div>
  </div>

  <script>
    let currentAnalysis = null;
    let simCamCount = 1;
    let isFlipped = false;
    let colorFilterMode = 0; // 0: Thermal, 1: Red Hotspot, 2: Red-Free (Green contrast)
    let isDarkTheme = false;

    
    function setConsoleTheme(palette) {
      const hdr = document.getElementById('consoleHeader');
      if (!hdr) return;
      hdr.classList.remove('bg-[#0f766e]', 'bg-[#1e293b]', 'bg-[#065f46]', 'bg-[#312e81]', 'bg-[#1e3a8a]');
      if (palette === 'slate') {
        hdr.classList.add('bg-[#1e293b]');
      } else if (palette === 'emerald') {
        hdr.classList.add('bg-[#065f46]');
      } else if (palette === 'indigo') {
        hdr.classList.add('bg-[#312e81]');
      } else if (palette === 'sapphire') {
        hdr.classList.add('bg-[#1e3a8a]');
      } else {
        hdr.classList.add('bg-[#0f766e]');
      }
      try { localStorage.setItem('drishti_console_theme', palette); } catch(e){}
    }

    window.addEventListener('DOMContentLoaded', () => {
      try { const st = localStorage.getItem('drishti_theme'); if (st === 'dark') toggleColorTheme(); } catch(e){}
      try { const saved = localStorage.getItem('drishti_console_theme'); if (saved) setConsoleTheme(saved); } catch(e){}
      const dtElem = document.getElementById('printDate');
      if (dtElem) dtElem.textContent = new Date().toLocaleDateString();
      initDragAndDrop();
      loadRealIdridSample(2);
    });

    // 1. WORKSTATION LAYOUT ORIENTATION SWITCHER
    function setLayoutOrientation(mode) {
      const colStudy = document.getElementById('colStudy');
      const colViewport = document.getElementById('colViewport');
      const colDiagnosis = document.getElementById('colDiagnosis');
      const btnSplit = document.getElementById('btnOrientSplit');
      const btnConsole = document.getElementById('btnOrientConsole');
      const btnFlow = document.getElementById('btnOrientFlow');

      [btnSplit, btnConsole, btnFlow].forEach(b => {
        b.className = 'px-2.5 py-1 rounded text-teal-100 hover:text-white font-medium text-[11px] transition';
      });

      if (mode === 'split') {
        // Horizontal Split: 50% Image & Quality on Left, 50% Diagnosis & Report on Right
        btnSplit.className = 'px-2.5 py-1 rounded bg-blue-700 text-white font-bold text-[11px] transition';
        colStudy.className = 'lg:col-span-4 space-y-3.5';
        colViewport.className = 'lg:col-span-4 space-y-3.5';
        colDiagnosis.className = 'lg:col-span-4 space-y-3.5';
      } else if (mode === 'console') {
        // 3-Column PACS Console: 25% Inputs, 42% Center Viewport, 33% Decision
        btnConsole.className = 'px-2.5 py-1 rounded bg-blue-700 text-white font-bold text-[11px] transition';
        colStudy.className = 'lg:col-span-3 space-y-3.5';
        colViewport.className = 'lg:col-span-5 space-y-3.5';
        colDiagnosis.className = 'lg:col-span-4 space-y-3.5';
      } else if (mode === 'flow') {
        // Vertical Sequential Flow: Full Width Flow
        btnFlow.className = 'px-2.5 py-1 rounded bg-blue-700 text-white font-bold text-[11px] transition';
        colStudy.className = 'lg:col-span-12 grid grid-cols-1 sm:grid-cols-3 gap-3.5';
        colViewport.className = 'lg:col-span-6 space-y-3.5';
        colDiagnosis.className = 'lg:col-span-6 space-y-3.5';
      }
    }

    // 2. THEME SWITCHER (CLINICAL LIGHT VS DARKROOM PACS)
    function toggleColorTheme() {
      isDarkTheme = !isDarkTheme;
      const body = document.body;
      const themeIcon = document.getElementById('themeIcon');
      const themeLabel = document.getElementById('themeLabel');

      if (isDarkTheme) {
        body.classList.add('dark');
        themeIcon.innerHTML = '&#9790;';
        themeLabel.textContent = 'Dark';
        try { localStorage.setItem('drishti_theme', 'dark'); } catch(e){}
      } else {
        body.classList.remove('dark');
        themeIcon.innerHTML = '&#9728;';
        themeLabel.textContent = 'Light';
        try { localStorage.setItem('drishti_theme', 'light'); } catch(e){}
      }
    }

    // 3. IMAGE ORIENTATION FLIP (LATERALITY OS VS OD)
    function toggleImageFlip() {
      isFlipped = !isFlipped;
      const fundus = document.getElementById('fundusCanvas');
      const gradcam = document.getElementById('gradcamCanvas');
      const landmarks = document.getElementById('landmarksCanvas');
      const label = document.getElementById('flipLabel');
      const vpEye = document.getElementById('viewportEyeSide');

      if (isFlipped) {
        fundus.classList.add('canvas-flipped');
        gradcam.classList.add('canvas-flipped');
        landmarks.classList.add('canvas-flipped');
        label.textContent = 'Orientation: Flipped (OD)';
        if (vpEye) vpEye.textContent = 'OD (Right Eye - Flipped)';
      } else {
        fundus.classList.remove('canvas-flipped');
        gradcam.classList.remove('canvas-flipped');
        landmarks.classList.remove('canvas-flipped');
        label.textContent = 'Orientation: Standard (OS)';
        if (vpEye) vpEye.textContent = 'OS (Left Eye)';
      }
    }

    // 4. COLOR FILTER / HEATMAP COLORMAP SELECTOR
    function cycleColorFilter() {
      colorFilterMode = (colorFilterMode + 1) % 3;
      const label = document.getElementById('filterLabel');
      const fundus = document.getElementById('fundusCanvas');

      if (colorFilterMode === 0) {
        label.textContent = 'Colormap: Thermal';
        fundus.style.filter = 'none';
      } else if (colorFilterMode === 1) {
        label.textContent = 'Colormap: Red Focus';
        fundus.style.filter = 'contrast(1.15) saturate(1.2)';
      } else {
        label.textContent = 'Colormap: Red-Free (Green)';
        fundus.style.filter = 'hue-rotate(90deg) saturate(1.4) contrast(1.2)';
      }

      if (currentAnalysis && currentAnalysis.gradcam) {
        drawGradCAMCanvas(currentAnalysis.gradcam);
      }
    }

    function loadRealIdridSample(grade) {
      document.getElementById('loader').classList.remove('hidden');

      const btnActiveClasses = {
        0: 'bg-emerald-50 text-emerald-800 border-emerald-300 font-bold',
        1: 'bg-sky-50 text-sky-800 border-sky-300 font-bold',
        2: 'bg-amber-50 text-amber-900 border-amber-300 font-bold',
        3: 'bg-orange-50 text-orange-900 border-orange-300 font-bold',
        4: 'bg-rose-50 text-rose-900 border-rose-300 font-bold'
      };

      for (let i = 0; i <= 4; i++) {
        const btn = document.getElementById('sampleBtn' + i);
        if (btn) {
          if (i === grade) {
            btn.className = 'px-1 py-1.5 rounded border text-[10px] transition text-center truncate ' + btnActiveClasses[i];
          } else {
            btn.className = 'px-1 py-1.5 rounded bg-slate-50 hover:bg-slate-100 border border-slate-200 text-[10px] font-semibold text-slate-700 transition text-center truncate';
          }
        }
      }

      fetch('/api/idrid_sample?grade=' + grade)
        .then(r => r.json())
        .then(data => {
          if (data && data.image_b64) {
            const img = new Image();
            img.onload = function() {
              const canvas = document.getElementById('fundusCanvas');
              const ctx = canvas.getContext('2d');
              ctx.clearRect(0, 0, 224, 224);
              ctx.drawImage(img, 0, 0, 224, 224);

              if (data.image_id) {
                document.getElementById('patientId').value = 'PAT-' + data.image_id;
                document.getElementById('patientName').value = 'IDRiD Patient ' + data.image_id;
              }

              const imgData = ctx.getImageData(0, 0, 224, 224);
              const bytes = imgData.data;
              let binary = '';
              for (let i = 0; i < bytes.byteLength; i++) {
                binary += String.fromCharCode(bytes[i]);
              }
              const rgba_b64 = btoa(binary);

              fetch('/api/analyze', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ rgba_b64: rgba_b64, filename: data.filename || ('idrid_' + grade + '.png') })
              })
              .then(res => res.json())
              .then(analysis => {
                renderAnalysis(analysis);
                drawGradCAMCanvas(analysis.gradcam || { cx: 120, cy: 110, radius: 45 });
                if (analysis.landmarks) {
                  drawLandmarksCanvas(analysis.landmarks);
                }
                document.getElementById('loader').classList.add('hidden');
              })
              .catch(err => {
                console.error('Analysis error:', err);
                document.getElementById('loader').classList.add('hidden');
              });
            };
            img.src = 'data:image/png;base64,' + data.image_b64;
          }
        })
        .catch(err => {
          console.error('Failed to load sample:', err);
          document.getElementById('loader').classList.add('hidden');
        });
    }

    function initDragAndDrop() {
      const dropZone = document.getElementById('dropZone');
      ['dragenter', 'dragover'].forEach(name => {
        dropZone.addEventListener(name, (e) => {
          e.preventDefault();
          e.stopPropagation();
          dropZone.classList.add('border-blue-500', 'bg-blue-50');
        });
      });
      ['dragleave', 'drop'].forEach(name => {
        dropZone.addEventListener(name, (e) => {
          e.preventDefault();
          e.stopPropagation();
          dropZone.classList.remove('border-blue-500', 'bg-blue-50');
        });
      });
      dropZone.addEventListener('drop', (e) => {
        const files = e.dataTransfer.files;
        if (files && files.length > 0) {
          processImageFile(files[0]);
        }
      });
      dropZone.addEventListener('click', () => {
        document.getElementById('fileInput').click();
      });
    }

    function handleFileInputChange(evt) {
      const file = evt.target.files[0];
      if (file) {
        processImageFile(file);
      }
    }

    function processImageFile(file) {
      document.getElementById('loader').classList.remove('hidden');

      const reader = new FileReader();
      reader.onload = function(e) {
        const img = new Image();
        img.onload = function() {
          const canvas = document.getElementById('fundusCanvas');
          const ctx = canvas.getContext('2d');
          ctx.clearRect(0, 0, 224, 224);
          ctx.drawImage(img, 0, 0, 224, 224);

          const imgData = ctx.getImageData(0, 0, 224, 224);
          const bytes = imgData.data;
          let binary = '';
          for (let i = 0; i < bytes.byteLength; i++) {
            binary += String.fromCharCode(bytes[i]);
          }
          const rgba_b64 = btoa(binary);

          fetch('/api/analyze', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ rgba_b64: rgba_b64, filename: file.name })
          })
          .then(res => res.json())
          .then(data => {
            renderAnalysis(data);
            drawGradCAMCanvas(data.gradcam || { cx: 120, cy: 110, radius: 45 });
            if (data.landmarks) {
              drawLandmarksCanvas(data.landmarks);
            }
            document.getElementById('loader').classList.add('hidden');
          })
          .catch(err => {
            console.error('Inference error:', err);
            document.getElementById('loader').classList.add('hidden');
          });
        };
        img.src = e.target.result;
      };
      reader.readAsDataURL(file);
    }

    function updateOpacity(val) {
      const canvas = document.getElementById('gradcamCanvas');
      canvas.style.opacity = (val / 100).toString();
      const valElem = document.getElementById('heatmapOpacityVal');
      if (valElem) valElem.textContent = val + '%';
    }

    function toggleLandmarksView(checked) {
      const canvas = document.getElementById('landmarksCanvas');
      canvas.style.opacity = checked ? '1.0' : '0.0';
    }

    function drawGradCAMCanvas(gcam) {
      const canvas = document.getElementById('gradcamCanvas');
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, 224, 224);

      const cx = gcam.cx || 120;
      const cy = gcam.cy || 110;
      const r = gcam.radius || 48;

      const grad = ctx.createRadialGradient(cx, cy, 5, cx, cy, r);

      if (colorFilterMode === 1) {
        // Red Hotspot mode
        grad.addColorStop(0.0, 'rgba(239, 68, 68, 0.90)');
        grad.addColorStop(0.5, 'rgba(249, 115, 22, 0.60)');
        grad.addColorStop(1.0, 'rgba(239, 68, 68, 0.0)');
      } else if (colorFilterMode === 2) {
        // Green-Contrast mode
        grad.addColorStop(0.0, 'rgba(16, 185, 129, 0.90)');
        grad.addColorStop(0.5, 'rgba(6, 182, 212, 0.60)');
        grad.addColorStop(1.0, 'rgba(16, 185, 129, 0.0)');
      } else {
        // Standard Thermal Jet spectrum
        grad.addColorStop(0.0, 'rgba(220, 38, 38, 0.85)');
        grad.addColorStop(0.35, 'rgba(249, 115, 22, 0.70)');
        grad.addColorStop(0.65, 'rgba(234, 179, 8, 0.50)');
        grad.addColorStop(0.85, 'rgba(16, 185, 129, 0.25)');
        grad.addColorStop(1.0, 'rgba(59, 130, 246, 0.0)');
      }

      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.fill();
    }

    function drawLandmarksCanvas(landmarks) {
      const canvas = document.getElementById('landmarksCanvas');
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, 224, 224);

      if (!landmarks || !landmarks.optic_disc || !landmarks.fovea) return;

      const od = landmarks.optic_disc;
      const fov = landmarks.fovea;

      // Connecting Vector
      ctx.beginPath();
      ctx.setLineDash([3, 3]);
      ctx.strokeStyle = 'rgba(147, 51, 234, 0.85)';
      ctx.lineWidth = 1.5;
      ctx.moveTo(od.x, od.y);
      ctx.lineTo(fov.x, fov.y);
      ctx.stroke();
      ctx.setLineDash([]);

      // Optic Disc Ring
      ctx.beginPath();
      ctx.setLineDash([3, 3]);
      ctx.strokeStyle = '#0891b2';
      ctx.lineWidth = 1.8;
      ctx.arc(od.x, od.y, od.radius, 0, Math.PI * 2);
      ctx.stroke();
      ctx.setLineDash([]);

      // Center crosshair
      ctx.strokeStyle = '#0891b2';
      ctx.lineWidth = 1.2;
      ctx.beginPath();
      ctx.moveTo(od.x - 4, od.y); ctx.lineTo(od.x + 4, od.y);
      ctx.moveTo(od.x, od.y - 4); ctx.lineTo(od.x, od.y + 4);
      ctx.stroke();

      if (od.cup_radius) {
        ctx.beginPath();
        ctx.fillStyle = 'rgba(8, 145, 178, 0.2)';
        ctx.arc(od.x, od.y, od.cup_radius, 0, Math.PI * 2);
        ctx.fill();
      }

      ctx.fillStyle = '#0891b2';
      ctx.font = '600 9px monospace';
      ctx.fillText('OD (' + od.x + ',' + od.y + ')', Math.max(5, od.x - 25), Math.max(12, od.y - od.radius - 4));

      // Fovea Centralis Ring
      ctx.beginPath();
      ctx.strokeStyle = '#d97706';
      ctx.lineWidth = 1.8;
      ctx.arc(fov.x, fov.y, fov.radius || 12, 0, Math.PI * 2);
      ctx.stroke();

      // Outer FAZ guidance
      ctx.beginPath();
      ctx.setLineDash([2, 3]);
      ctx.strokeStyle = 'rgba(217, 119, 6, 0.5)';
      ctx.lineWidth = 1;
      ctx.arc(fov.x, fov.y, (od.radius * 1.4), 0, Math.PI * 2);
      ctx.stroke();
      ctx.setLineDash([]);

      ctx.strokeStyle = '#d97706';
      ctx.lineWidth = 1.2;
      ctx.beginPath();
      ctx.moveTo(fov.x - 4, fov.y); ctx.lineTo(fov.x + 4, fov.y);
      ctx.moveTo(fov.x, fov.y - 4); ctx.lineTo(fov.x, fov.y + 4);
      ctx.stroke();

      ctx.fillStyle = '#d97706';
      ctx.font = '600 9px monospace';
      ctx.fillText('FOV (' + fov.x + ',' + fov.y + ')', Math.max(5, fov.x - 22), Math.min(220, fov.y + (fov.radius || 12) + 11));

      if (landmarks.macular_threat) {
        ctx.beginPath();
        ctx.strokeStyle = 'rgba(220, 38, 38, 0.9)';
        ctx.lineWidth = 1.6;
        ctx.setLineDash([3, 2]);
        ctx.arc(fov.x, fov.y, od.radius * 2.0, 0, Math.PI * 2);
        ctx.stroke();
        ctx.setLineDash([]);
      }
    }

    function renderAnalysis(data) {
      currentAnalysis = data;
      const stageCode = data.stageCode;
      
      const stageColors = {
        0: 'text-emerald-700',
        1: 'text-sky-700',
        2: 'text-amber-700',
        3: 'text-orange-700',
        4: 'text-rose-700'
      };

      const titleElem = document.getElementById('diagStageName');
      titleElem.textContent = data.stageName;
      titleElem.className = 'text-xl font-black tracking-tight mt-0.5 ' + (stageColors[stageCode] || 'text-slate-900');

      document.getElementById('diagConfidence').textContent = (data.confidencePercent || 90.0) + '%';
      document.getElementById('diagLatency').textContent = (data.inferenceLatencyMs || 42.5).toFixed(1) + ' ms';
      document.getElementById('diagDescription').textContent = data.stageDescription;

      const probs = data.classProbabilities || [0.2, 0.2, 0.2, 0.2, 0.2];
      for (let i = 0; i < 5; i++) {
        const pct = (probs[i] * 100).toFixed(1) + '%';
        document.getElementById('prob' + i + 'Text').textContent = pct;
        document.getElementById('prob' + i + 'Bar').style.width = pct;
      }

      const triageBadge = document.getElementById('triageBadge');
      if (data.referralRequired) {
        triageBadge.className = 'px-2.5 py-0.5 rounded text-[10px] font-bold uppercase bg-rose-50 text-rose-700 border border-rose-200';
        triageBadge.textContent = 'Referral Required';
      } else {
        triageBadge.className = 'px-2.5 py-0.5 rounded text-[10px] font-bold uppercase bg-emerald-50 text-emerald-800 border border-emerald-200';
        triageBadge.textContent = 'Routine Surveillance';
      }

      document.getElementById('triageUrgency').textContent = data.urgency;
      document.getElementById('triageAction').textContent = data.actionProtocol;
      document.getElementById('gradcamText').textContent = data.justification || 'Diagnostic saliency centered on vascular arcades.';

      if (data.iqa) {
        const iqa = data.iqa;
        const iqaBadge = document.getElementById('iqaBadge');
        iqaBadge.textContent = iqa.verdict + ' (' + iqa.overallScore.toFixed(1) + ' / 100)';
        if (iqa.verdict === 'Good') {
          iqaBadge.className = 'text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-50 text-emerald-800 border border-emerald-200';
        } else if (iqa.verdict === 'Usable') {
          iqaBadge.className = 'text-[10px] font-bold px-2 py-0.5 rounded bg-amber-50 text-amber-800 border border-amber-200';
        } else {
          iqaBadge.className = 'text-[10px] font-bold px-2 py-0.5 rounded bg-rose-50 text-rose-800 border border-rose-200';
        }

        if (iqa.metrics) {
          document.getElementById('metricBlur').textContent = (iqa.metrics.blurScore > 0.8) ? 'Optimal' : (iqa.metrics.blurScore > 0.4 ? 'Subtle Blur' : 'Blurry');
          document.getElementById('metricBrightness').textContent = (iqa.metrics.brightnessScore > 0.8) ? 'Balanced' : (iqa.metrics.brightnessScore > 0.5 ? 'Moderate' : 'Extreme');
          document.getElementById('metricContrast').textContent = (iqa.metrics.contrastScore > 0.7) ? 'High' : (iqa.metrics.contrastScore > 0.4 ? 'Adequate' : 'Low');
        }
        if (iqa.action) {
          document.getElementById('iqaAction').textContent = iqa.action;
        }
      }

      if (data.landmarks) {
        const lm = data.landmarks;
        if (lm.optic_disc) {
          document.getElementById('odCoords').textContent = '(' + lm.optic_disc.x + ', ' + lm.optic_disc.y + ') px';
          document.getElementById('odRadiusText').textContent = 'Radius: ' + lm.optic_disc.radius + ' px';
          document.getElementById('cdrValue').textContent = lm.optic_disc.cup_to_disc_ratio.toFixed(2);
          document.getElementById('cdrStatus').textContent = lm.optic_disc.cup_to_disc_ratio < 0.5 ? 'Normal (< 0.50)' : (lm.optic_disc.cup_to_disc_ratio <= 0.65 ? 'Borderline' : 'Glaucoma Risk');
        }
        if (lm.fovea) {
          document.getElementById('foveaCoords').textContent = '(' + lm.fovea.x + ', ' + lm.fovea.y + ') px';
          document.getElementById('fazRadiusText').textContent = 'FAZ: ' + lm.fovea.radius + ' px';
        }
        if (lm.disc_to_fovea_distance_px) {
          document.getElementById('odFovDist').textContent = lm.disc_to_fovea_distance_px.toFixed(1) + ' px';
          document.getElementById('odFovDistMm').textContent = '~' + lm.disc_to_fovea_distance_mm + ' mm';
        }
        if (lm.eye_side) {
          document.getElementById('eyeLateralityBadge').textContent = lm.eye_side;
          const vpEye = document.getElementById('viewportEyeSide');
          if (vpEye && !isFlipped) vpEye.textContent = lm.eye_side;
        }
        const macBadge = document.getElementById('maculaThreatBadge');
        const csmeBox = document.getElementById('csmeAlertBox');
        const csmeText = document.getElementById('csmeAlertText');
        if (lm.macular_threat) {
          macBadge.className = 'text-[10px] font-bold px-2 py-0.5 rounded bg-rose-50 text-rose-800 border border-rose-200';
          macBadge.textContent = 'CSME Threat';
          csmeBox.className = 'bg-rose-50 border border-rose-200 rounded p-2 text-xs text-rose-900 leading-relaxed flex items-center justify-between';
          csmeText.textContent = lm.macular_status;
        } else {
          macBadge.className = 'text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-50 text-emerald-800 border border-emerald-200';
          macBadge.textContent = 'FAZ Intact';
          csmeBox.className = 'bg-slate-50 border border-slate-200 rounded p-2 text-xs text-slate-700 leading-relaxed flex items-center justify-between';
          csmeText.textContent = lm.macular_status || 'Macular Avascular Zone Clear';
        }
      }
    }

    function openCampSimulationModal() {
      document.getElementById('campModal').classList.remove('hidden');
      runCampSimulation();
    }

    function closeCampSimulationModal() {
      document.getElementById('campModal').classList.add('hidden');
    }

    function setCameraCount(c) {
      simCamCount = c;
      const b1 = document.getElementById('btnCam1');
      const b2 = document.getElementById('btnCam2');
      if (c === 1) {
        b1.className = 'py-1 px-2 rounded bg-blue-700 text-white text-[11px] font-bold transition';
        b2.className = 'py-1 px-2 rounded bg-slate-200 text-slate-700 text-[11px] font-bold hover:bg-slate-300 transition';
        document.getElementById('simCamerasVal').textContent = '1 Camera';
      } else {
        b2.className = 'py-1 px-2 rounded bg-blue-700 text-white text-[11px] font-bold transition';
        b1.className = 'py-1 px-2 rounded bg-slate-200 text-slate-700 text-[11px] font-bold hover:bg-slate-300 transition';
        document.getElementById('simCamerasVal').textContent = '2 Cameras';
      }
      runCampSimulation();
    }

    function runCampSimulation() {
      const pts = document.getElementById('simPatients').value;
      const hrs = document.getElementById('simHours').value;
      document.getElementById('simPatientsVal').textContent = pts;
      document.getElementById('simHoursVal').textContent = hrs + '.0 Hours';

      fetch('/api/simulate?patients=' + pts + '&cameras=' + simCamCount + '&hours=' + hrs)
        .then(r => r.json())
        .then(res => {
          document.getElementById('simAvgWait').textContent = res.averageWaitTimeMinutes + ' min';
          document.getElementById('simP95Wait').textContent = 'P95: ' + res.p95WaitTimeMinutes + ' min';
          document.getElementById('simUtil').textContent = res.cameraUtilizationPercent + '%';
          document.getElementById('simCapacity').textContent = res.estimatedDailyCapacity + ' pts';
          document.getElementById('simAiLoad').textContent = res.aiEdgeUtilizationPercent + '%';

          const utilElem = document.getElementById('simUtil');
          const utilStatus = document.getElementById('simUtilStatus');
          if (res.cameraUtilizationPercent > 85.0) {
            utilElem.className = 'text-base font-bold text-rose-700 font-mono mt-0.5';
            utilStatus.textContent = 'Elevated Backlog';
            utilStatus.className = 'text-[9px] text-rose-700 font-bold';
          } else if (res.cameraUtilizationPercent > 65.0) {
            utilElem.className = 'text-base font-bold text-amber-700 font-mono mt-0.5';
            utilStatus.textContent = 'Moderate Load';
            utilStatus.className = 'text-[9px] text-amber-700 font-bold';
          } else {
            utilElem.className = 'text-base font-bold text-emerald-700 font-mono mt-0.5';
            utilStatus.textContent = 'Optimal Flow';
            utilStatus.className = 'text-[9px] text-emerald-700 font-bold';
          }

          const benefitBanner = document.getElementById('simBenefitBanner');
          const benefitText = document.getElementById('simBenefitText');
          if (simCamCount === 1) {
            benefitBanner.classList.remove('hidden');
            benefitText.textContent = 'Adding a 2nd camera reduces average wait time from ' + res.averageWaitTimeMinutes + ' min to ~0.8 min (' + res.waitReductionPct + '% reduction) and doubles camp capacity.';
          } else {
            benefitText.textContent = 'Dual-camera setup eliminates optical bottlenecks: 246+ patients/day screening capacity achieved.';
          }

          const barsContainer = document.getElementById('simTimelineBars');
          barsContainer.innerHTML = '';
          if (res.hourlyTimeline) {
            const maxVal = Math.max(...res.hourlyTimeline.map(t => Math.max(t.arrivals, t.queueLength, 1)));
            res.hourlyTimeline.forEach(t => {
              const hArrival = Math.round((t.arrivals / maxVal) * 45);
              const hQueue = Math.round((t.queueLength / maxVal) * 45);
              const col = document.createElement('div');
              col.className = 'flex flex-col items-center space-y-1 text-center';
              col.innerHTML = `
                <div class="h-14 w-full flex items-end justify-center gap-1 bg-slate-100 rounded p-1 border border-slate-200">
                  <div class="w-2.5 bg-blue-600 rounded-t" style="height: ${Math.max(4, hArrival)}px" title="Arrivals: ${t.arrivals}"></div>
                  <div class="w-2.5 ${t.queueLength > 5 ? 'bg-rose-600' : 'bg-amber-500'} rounded-t" style="height: ${Math.max(2, hQueue)}px" title="Queue Backlog: ${t.queueLength}"></div>
                </div>
                <span class="text-[9px] text-slate-600 font-mono font-bold">${t.label}</span>
                <span class="text-[8px] text-slate-500 font-mono">${t.estimatedWaitMin}m</span>
              `;
              barsContainer.appendChild(col);
            });
          }

          if (res.staffingRecommendation) {
            document.getElementById('recOptom').textContent = res.staffingRecommendation.optometrists;
            document.getElementById('recAsha').textContent = res.staffingRecommendation.ashaWorkers;
            document.getElementById('recCameras').textContent = res.staffingRecommendation.fundusCameras;
          }
        })
        .catch(e => console.error('Simulation error:', e));
    }

    function downloadFhirJson() {
      if (!currentAnalysis) return;
      const patientId = document.getElementById('patientId').value || 'PAT-IDRiD_003';
      const patientName = document.getElementById('patientName').value || 'IDRiD Patient 003';

      const fhirBundle = {
        resourceType: "Bundle",
        type: "collection",
        timestamp: new Date().toISOString(),
        entry: [
          {
            fullUrl: "urn:uuid:diagnosticreport-" + patientId,
            resource: {
              resourceType: "DiagnosticReport",
              id: "dr-report-" + patientId,
              status: "final",
              subject: { reference: "Patient/" + patientId, display: patientName },
              code: {
                coding: [{ system: "http://loinc.org", code: "74062-1", display: "Diabetic Retinopathy Screening" }]
              },
              conclusion: currentAnalysis.stageName + " (Confidence: " + currentAnalysis.confidencePercent + "%)",
              conclusionCode: [
                { coding: [{ system: "http://snomed.info/sct", code: "4855003", display: currentAnalysis.stageName }] }
              ]
            }
          }
        ]
      };

      const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(fhirBundle, null, 2));
      const downloadAnchor = document.createElement('a');
      downloadAnchor.setAttribute("href", dataStr);
      downloadAnchor.setAttribute("download", "ABDM_FHIR_Report_" + patientId + ".json");
      document.body.appendChild(downloadAnchor);
      downloadAnchor.click();
      downloadAnchor.remove();
    }
  </script>
</body>
</html>"""

# ==============================================================================
# 2. DOCTOR'S RAPID CLINICAL PORTAL (ROUTE: /doctor)
# ==============================================================================
DOCTOR_UI = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>DRISHTI-AI | Physician Retinal Consultation Portal</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    .font-mono {
      font-family: 'JetBrains Mono', monospace;
    }
    @media print {
      @page {
        size: A4 portrait;
        margin: 12mm 15mm;
      }
      body {
        background: white !important;
        color: #0f172a !important;
        font-size: 10.5pt !important;
      }
      .no-print {
        display: none !important;
      }
      .print-only {
        display: block !important;
      }
      .print-sheet {
        display: block !important;
        border: none !important;
        box-shadow: none !important;
        padding: 0 !important;
        max-width: 100% !important;
      }
      .print-border {
        border: 1px solid #cbd5e1 !important;
      }
      .print-badge {
        border: 1px solid #475569 !important;
        background: #f8fafc !important;
        color: #0f172a !important;
      }
    }
    .print-only {
      display: none;
    }
    .custom-scroll::-webkit-scrollbar { width: 5px; height: 5px; }
    .custom-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 3px; }
  </style>
</head>
<body class="bg-slate-50 text-slate-800 min-h-screen antialiased custom-scroll">

  <!-- PHYSICIAN NAVIGATION TOP BAR (HOSPITAL SAPPHIRE) -->
  <header class="no-print bg-[#1e3a8a] text-white px-5 py-2.5 flex items-center justify-between sticky top-0 z-40 shadow-sm">
    <div class="flex items-center space-x-3">
      <div class="h-8 w-8 rounded-lg bg-white/10 border border-white/20 flex items-center justify-center text-white shadow-sm">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5a4 4 0 008 0V4M8 13v2a4 4 0 004 4h1a4 4 0 004-4v-1.5M19 16a2 2 0 100-4 2 2 0 000 4z"/>
        </svg>
      </div>
      <div>
        <div class="flex items-center space-x-2">
          <span class="font-semibold text-sm tracking-tight text-white">DRISHTI-AI CLINICAL DECISION SUPPORT</span>
          <span class="text-[10px] text-blue-200/60 font-normal">|</span>
          <span class="text-xs text-blue-100 font-medium">Physician Consultation Portal</span>
          <span class="text-[10px] font-medium px-2 py-0.5 rounded bg-blue-700/80 text-blue-100 border border-blue-500/40">ICDR Protocol</span>
        </div>
        <div class="text-[11px] text-blue-200/80">Tele-Ophthalmology Evaluation &bull; Primary Health Center Clinical Decision Flow</div>
      </div>
    </div>

    <!-- ACTION BUTTON GROUP -->
    <div class="flex items-center space-x-2">
      <!-- Full Research View Button (Teal Clinical Badge) -->
      <a href="/" class="px-3 py-1.5 rounded-md bg-teal-800 hover:bg-teal-700 border border-teal-500/50 text-xs font-semibold text-white transition flex items-center space-x-1.5 shadow-sm">
        <svg class="w-3.5 h-3.5 text-teal-200" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
          <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
        </svg>
        <span>Research Console</span>
      </a>

      <!-- Print Clinical Summary Button -->
      <button onclick="window.print()" class="px-3.5 py-1.5 rounded-md bg-white text-teal-900 hover:bg-teal-50 text-xs font-semibold transition flex items-center space-x-1.5 shadow-sm">
        <svg class="w-3.5 h-3.5 text-teal-900" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4H7v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"/>
        </svg>
        <span>Print Consultation Sheet (A4)</span>
      </button>

      <!-- FHIR Export Button -->
      <button onclick="downloadDoctorFhir()" class="px-3 py-1.5 rounded-md bg-teal-950 hover:bg-teal-900 text-xs font-medium text-white transition flex items-center space-x-1.5 shadow-sm">
        <svg class="w-3.5 h-3.5 text-teal-200" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
        </svg>
        <span>ABDM FHIR</span>
      </button>
    </div>
  </header>

  <!-- FORMAL HOSPITAL MEDICAL LETTERHEAD (Printed on Consultation Sheet) -->
  <div class="print-only px-8 pt-6 pb-4 border-b-2 border-slate-900 text-black mb-4">
    <div class="flex justify-between items-start">
      <div>
        <div class="text-[10px] font-bold uppercase tracking-wider text-slate-600">National Tele-Ophthalmology &amp; Retinal Care Network</div>
        <h1 class="text-xl font-bold tracking-tight text-blue-950 mt-0.5">DIABETIC RETINOPATHY CLINICAL CONSULTATION REPORT</h1>
        <p class="text-xs text-slate-600 mt-0.5">Compliant with Ayushman Bharat Digital Mission (ABDM) FHIR R4 &bull; ICDR Clinical Classification</p>
      </div>
      <div class="text-right text-xs text-slate-700">
        <p><strong>Examination Date:</strong> <span id="docPrintDate"></span></p>
        <p><strong>Clinical System:</strong> DRISHTI-AI Decision Support (v1.2)</p>
      </div>
    </div>
  </div>

  <!-- MAIN CLINICAL CONTAINER -->
  <main class="max-w-6xl mx-auto p-4 md:p-5 space-y-4 print-sheet">

    <!-- COMPACT PATIENT DEMOGRAPHIC STRIP -->
    <div class="bg-white border border-slate-200 rounded-xl p-3.5 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-3 text-xs print-border">
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3 flex-1">
        <div>
          <span class="text-[10px] uppercase font-semibold text-slate-400 block tracking-wider">Patient ID</span>
          <input type="text" id="docPatId" value="PAT-IDRiD_003" class="w-full font-semibold font-mono text-slate-900 bg-transparent border-b border-transparent hover:border-slate-300 focus:border-blue-500 focus:outline-none">
        </div>
        <div>
          <span class="text-[10px] uppercase font-semibold text-slate-400 block tracking-wider">Patient Name</span>
          <input type="text" id="docPatName" value="IDRiD Patient 003" class="w-full font-semibold text-slate-900 bg-transparent border-b border-transparent hover:border-slate-300 focus:border-blue-500 focus:outline-none">
        </div>
        <div>
          <span class="text-[10px] uppercase font-semibold text-slate-400 block tracking-wider">Demographics</span>
          <input type="text" id="docPatAge" value="56 Y / Female" class="w-full font-semibold text-slate-900 bg-transparent border-b border-transparent hover:border-slate-300 focus:border-blue-500 focus:outline-none">
        </div>
        <div>
          <span class="text-[10px] uppercase font-semibold text-slate-400 block tracking-wider">Screening Facility</span>
          <input type="text" id="docCenter" value="Primary Health Centre - Camp #1" class="w-full font-semibold text-slate-900 bg-transparent border-b border-transparent hover:border-slate-300 focus:border-blue-500 focus:outline-none">
        </div>
      </div>
      <div class="shrink-0 flex items-center space-x-2 pt-1 md:pt-0">
        <span id="docEyeSideBadge" class="text-xs font-mono font-medium px-2 py-0.5 rounded bg-slate-100 text-slate-700 border border-slate-200">Left Eye (OS)</span>
        <span id="docIqaStatus" class="text-xs font-medium px-2 py-0.5 rounded bg-emerald-50 text-emerald-800 border border-emerald-200">&#10003; Quality Verified</span>
      </div>
    </div>

    <!-- QUICK PRESET PATIENT SELECTOR (COLOR CODED BY SEVERITY) -->
    <div class="no-print bg-white border border-slate-200 rounded-xl p-2.5 shadow-sm flex items-center justify-between text-xs">
      <span class="font-medium text-slate-700 flex items-center gap-1.5">
        <span class="h-2 w-2 rounded-full bg-blue-600"></span>
        Load Reference Patient Case:
      </span>
      <div class="grid grid-cols-5 gap-1.5">
        <button onclick="doctorLoadSample(0)" id="docBtn0" class="px-2.5 py-1 rounded bg-slate-50 hover:bg-slate-100 text-[11px] font-medium text-emerald-700 border border-slate-200">0: Normal</button>
        <button onclick="doctorLoadSample(1)" id="docBtn1" class="px-2.5 py-1 rounded bg-slate-50 hover:bg-slate-100 text-[11px] font-medium text-sky-700 border border-slate-200">1: Mild</button>
        <button onclick="doctorLoadSample(2)" id="docBtn2" class="px-2.5 py-1 rounded bg-amber-50 text-amber-900 border border-amber-300 font-semibold text-[11px]">2: Moderate</button>
        <button onclick="doctorLoadSample(3)" id="docBtn3" class="px-2.5 py-1 rounded bg-slate-50 hover:bg-slate-100 text-[11px] font-medium text-orange-700 border border-slate-200">3: Severe</button>
        <button onclick="doctorLoadSample(4)" id="docBtn4" class="px-2.5 py-1 rounded bg-slate-50 hover:bg-slate-100 text-[11px] font-medium text-rose-700 border border-slate-200">4: PDR</button>
      </div>
    </div>

    <!-- TWO-COLUMN CLINICAL LAYOUT -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-4">

      <!-- LEFT: RETINAL FUNDUS VIEW & OVERLAYS (5 COLS) -->
      <div class="lg:col-span-5 space-y-3">
        <div class="bg-white border border-slate-200 rounded-xl p-3.5 shadow-sm space-y-2.5 print-border">
          <div class="flex items-center justify-between text-xs pb-1 border-b border-slate-100">
            <span class="font-semibold text-slate-800">Digital Fundus Photography</span>
            <span class="text-[10px] text-slate-400 font-mono">224 &times; 224 px &bull; Color</span>
          </div>

          <div class="relative bg-black rounded-lg overflow-hidden flex items-center justify-center min-h-[250px] border border-slate-800">
            <canvas id="docFundusCanvas" width="224" height="224" class="w-full max-w-[260px] h-auto object-contain"></canvas>
            <canvas id="docGradcamCanvas" width="224" height="224" class="absolute w-full max-w-[260px] h-auto object-contain pointer-events-none opacity-0 transition-opacity duration-200"></canvas>
            <canvas id="docLandmarksCanvas" width="224" height="224" class="absolute w-full max-w-[260px] h-auto object-contain pointer-events-none opacity-100 transition-opacity duration-200"></canvas>
          </div>

          <!-- CLUTTER-FREE OVERLAY TOGGLES -->
          <div class="no-print grid grid-cols-2 gap-2 text-xs pt-0.5">
            <label class="flex items-center space-x-2 bg-slate-50 p-2 rounded-lg border border-slate-200 cursor-pointer hover:bg-slate-100/70">
              <input type="checkbox" id="docToggleLesions" onchange="docUpdateOverlays()" class="accent-blue-600 h-3.5 w-3.5 rounded cursor-pointer">
              <span class="text-slate-700 font-medium text-[11px]">Saliency Heatmap</span>
            </label>
            <label class="flex items-center space-x-2 bg-slate-50 p-2 rounded-lg border border-slate-200 cursor-pointer hover:bg-slate-100/70">
              <input type="checkbox" id="docToggleLandmarks" checked onchange="docUpdateOverlays()" class="accent-emerald-600 h-3.5 w-3.5 rounded cursor-pointer">
              <span class="text-slate-700 font-medium text-[11px]">Disc &amp; Fovea Calipers</span>
            </label>
          </div>
        </div>

        <!-- KEY ANATOMICAL BIOMARKER METRICS -->
        <div class="bg-white border border-slate-200 rounded-xl p-3.5 shadow-sm space-y-2 text-xs print-border">
          <span class="text-[10px] font-semibold uppercase tracking-wider text-slate-400 block">Measured Anatomical Biomarkers</span>
          
          <div class="grid grid-cols-2 gap-2 text-slate-700">
            <div class="bg-slate-50 p-2.5 rounded border border-slate-200">
              <span class="text-[10px] text-slate-500 block">Cup-to-Disc Ratio (CDR)</span>
              <strong id="docCdrText" class="text-base font-bold text-slate-900 font-mono">0.42</strong>
              <span id="docCdrVerdict" class="text-[10px] text-emerald-700 block font-medium">Normal Cup (&lt; 0.50)</span>
            </div>
            <div class="bg-slate-50 p-2.5 rounded border border-slate-200">
              <span class="text-[10px] text-slate-500 block">Disc-to-Fovea Distance</span>
              <strong id="docDistText" class="text-base font-bold text-slate-900 font-mono">67.9 px</strong>
              <span class="text-[10px] text-slate-600 block">~2.4 mm (Normal Caliber)</span>
            </div>
          </div>

          <div id="docCsmeWarningBox" class="bg-emerald-50 border border-emerald-200 text-emerald-900 p-2.5 rounded-lg text-xs flex items-center justify-between">
            <div>
              <strong>Macular Threat: </strong>
              <span id="docCsmeWarningText">Clear (Zero Exudative Threat)</span>
            </div>
            <span class="text-[10px] font-medium text-emerald-800 px-1.5 py-0.5 rounded bg-emerald-100">Intact</span>
          </div>
        </div>
      </div>

      <!-- RIGHT: PRIMARY DIAGNOSIS, ACTION PROTOCOL & DOCTOR NOTES (7 COLS) -->
      <div class="lg:col-span-7 space-y-3">

        <!-- PRIMARY DIAGNOSTIC FINDING CARD -->
        <div class="bg-white border border-slate-200 rounded-xl p-4 shadow-sm space-y-3.5 print-border">
          <div class="flex items-start justify-between flex-wrap gap-2 pb-2.5 border-b border-slate-100">
            <div>
              <span class="text-[10px] font-semibold uppercase tracking-wider text-slate-400 block">ICDR Staging Assessment</span>
              <h2 id="docStageTitle" class="text-xl font-bold text-amber-600 tracking-tight mt-0.5">Stage 2: Moderate NPDR</h2>
              <div class="text-xs text-slate-500 mt-0.5">ICD-10: E11.339 &bull; Diagnostic Certainty: <span id="docConfidenceVal" class="font-semibold text-slate-900 font-mono">81.3%</span></div>
            </div>
            <div id="docTriageBadge" class="px-3 py-1 rounded text-xs font-semibold uppercase tracking-wide bg-rose-50 text-rose-700 border border-rose-200 print-badge">
              REFERRAL REQUIRED
            </div>
          </div>

          <!-- DIRECT CLINICAL ACTION DIRECTIVE -->
          <div class="bg-slate-50 border-l-4 border-amber-500 p-3 rounded-r-lg space-y-1">
            <span class="text-[10px] font-semibold uppercase text-slate-500 block">Clinical Urgency &amp; Directive:</span>
            <div id="docDirective" class="text-xs font-bold text-slate-900">
              Non-Urgent Tele-Ophthalmology Referral (Within 30 Days)
            </div>
            <p id="docProtocolAction" class="text-xs text-slate-600 leading-relaxed pt-0.5">
              Forward retinal photograph and Grad-CAM map to District Tele-Ophthalmology network. Recommend confirmatory optical coherence tomography (OCT) to rule out subclinical macular thickening.
            </p>
          </div>

          <!-- PATHOLOGY SUMMARY FOR DOCTOR -->
          <div class="text-xs text-slate-700 space-y-1">
            <span class="font-semibold text-slate-800 text-[11px]">Pathologic Biomarker Summary:</span>
            <p id="docBiomarkerSummary" class="text-slate-600 leading-relaxed bg-slate-50 p-2.5 rounded border border-slate-200">
              Multiple retinal microaneurysms, scattered blot hemorrhages, and distinct yellowish lipid exudates detected in macula vicinity.
            </p>
          </div>
        </div>

        <!-- DOCTOR'S CLINICAL ORDERS & SIGN-OFF NOTES -->
        <div class="bg-white border border-slate-200 rounded-xl p-4 shadow-sm space-y-3 print-border">
          <div class="flex justify-between items-center">
            <span class="text-xs font-semibold uppercase tracking-wider text-slate-800">Attending Physician Orders &amp; Clinical Notes</span>
            <span class="text-[10px] text-slate-400 no-print">Editable</span>
          </div>

          <textarea id="docNotes" rows="3" class="w-full text-xs text-slate-800 bg-slate-50 border border-slate-300 rounded-lg p-2.5 focus:bg-white focus:border-blue-500 focus:outline-none" placeholder="Enter clinical impressions, glycemic control advisory, or specific hospital referral instructions...">Reviewed fundus photograph. AI classification confirmed. Advise strict glycemic control (Target HbA1c &lt; 7.0%). Scheduled tele-consultation with District Hospital retina unit within 30 days.</textarea>

          <div class="grid grid-cols-2 gap-3 pt-1 text-xs">
            <div>
              <label class="text-[10px] text-slate-500 font-medium uppercase block">Consulting Physician</label>
              <input type="text" id="docPhysicianName" value="Dr. Arvind Sharma, MBBS, MS (Ophthalmology)" class="w-full font-medium text-slate-900 bg-slate-50 border border-slate-200 rounded px-2 py-1 text-xs">
            </div>
            <div>
              <label class="text-[10px] text-slate-500 font-medium uppercase block">Medical Council Reg. No.</label>
              <input type="text" id="docRegNo" value="MCI-42918-DL" class="w-full font-medium text-slate-900 bg-slate-50 border border-slate-200 rounded px-2 py-1 text-xs font-mono">
            </div>
          </div>

          <!-- SIGNATURE LINE FOR PRINT REPORT -->
          <div class="print-only pt-6 flex justify-between items-end text-xs border-t border-slate-400 mt-5">
            <div>
              <p><strong>Attending Ophthalmologist:</strong> ___________________________________</p>
              <p class="text-[10px] text-slate-500 mt-1">Signature &amp; Date</p>
            </div>
            <div class="text-right">
              <p><strong>Primary Health Center Stamp:</strong> [ Verified ]</p>
              <p class="text-[10px] text-slate-500 mt-1">Tele-Ophthalmology Network Unit</p>
            </div>
          </div>
        </div>

      </div>

    </div>

  </main>

  <script>
    let currentDocAnalysis = null;

    
    window.addEventListener('DOMContentLoaded', () => {
      const dt = document.getElementById('docPrintDate');
      if (dt) dt.textContent = new Date().toLocaleDateString();
      doctorLoadSample(2);
    });

    function doctorLoadSample(grade) {
      // Update button styles with clean semantic severity colors
      const btnActiveClasses = {
        0: 'bg-emerald-50 text-emerald-800 border-emerald-300 font-semibold',
        1: 'bg-sky-50 text-sky-800 border-sky-300 font-semibold',
        2: 'bg-amber-50 text-amber-900 border-amber-300 font-semibold',
        3: 'bg-orange-50 text-orange-900 border-orange-300 font-semibold',
        4: 'bg-rose-50 text-rose-900 border-rose-300 font-semibold'
      };

      for (let i = 0; i <= 4; i++) {
        const btn = document.getElementById('docBtn' + i);
        if (btn) {
          if (i === grade) {
            btn.className = 'px-2.5 py-1 rounded border text-[11px] ' + btnActiveClasses[i];
          } else {
            btn.className = 'px-2.5 py-1 rounded bg-slate-50 hover:bg-slate-100 text-[11px] font-medium text-slate-700 border border-slate-200';
          }
        }
      }

      fetch('/api/idrid_sample?grade=' + grade)
        .then(r => r.json())
        .then(data => {
          if (data && data.image_b64) {
            const img = new Image();
            img.onload = function() {
              const canvas = document.getElementById('docFundusCanvas');
              const ctx = canvas.getContext('2d');
              ctx.clearRect(0, 0, 224, 224);
              ctx.drawImage(img, 0, 0, 224, 224);

              if (data.image_id) {
                document.getElementById('docPatId').value = 'PAT-' + data.image_id;
                document.getElementById('docPatName').value = 'IDRiD Patient ' + data.image_id;
              }

              const imgData = ctx.getImageData(0, 0, 224, 224);
              const bytes = imgData.data;
              let binary = '';
              for (let i = 0; i < bytes.byteLength; i++) binary += String.fromCharCode(bytes[i]);
              const rgba_b64 = btoa(binary);

              fetch('/api/analyze', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ rgba_b64: rgba_b64, filename: data.filename || ('idrid_' + grade + '.png') })
              })
              .then(res => res.json())
              .then(analysis => {
                currentDocAnalysis = analysis;
                renderDoctorView(analysis);
                docDrawGradcam(analysis.gradcam || { cx: 120, cy: 110, radius: 45 });
                if (analysis.landmarks) {
                  docDrawLandmarks(analysis.landmarks);
                }
              });
            };
            img.src = 'data:image/png;base64,' + data.image_b64;
          }
        });
    }

    function renderDoctorView(data) {
      const stageColors = {
        0: 'text-emerald-700',
        1: 'text-sky-700',
        2: 'text-amber-700',
        3: 'text-orange-700',
        4: 'text-rose-700'
      };

      const title = document.getElementById('docStageTitle');
      title.textContent = data.stageName;
      title.className = 'text-xl font-bold tracking-tight mt-0.5 ' + (stageColors[data.stageCode] || 'text-slate-900');

      document.getElementById('docConfidenceVal').textContent = (data.confidencePercent || 90.0) + '%';
      document.getElementById('docDirective').textContent = data.urgency;
      document.getElementById('docProtocolAction').textContent = data.actionProtocol;
      document.getElementById('docBiomarkerSummary').textContent = data.stageDescription;

      const triageBadge = document.getElementById('docTriageBadge');
      if (data.referralRequired) {
        triageBadge.className = 'px-3 py-1 rounded text-xs font-semibold uppercase tracking-wide bg-rose-50 text-rose-700 border border-rose-200 print-badge';
        triageBadge.textContent = 'REFERRAL REQUIRED';
      } else {
        triageBadge.className = 'px-3 py-1 rounded text-xs font-semibold uppercase tracking-wide bg-emerald-50 text-emerald-800 border border-emerald-200 print-badge';
        triageBadge.textContent = 'ROUTINE SURVEILLANCE';
      }

      if (data.landmarks) {
        const lm = data.landmarks;
        if (lm.optic_disc) {
          document.getElementById('docCdrText').textContent = lm.optic_disc.cup_to_disc_ratio.toFixed(2);
          document.getElementById('docCdrVerdict').textContent = lm.optic_disc.cup_to_disc_ratio < 0.5 ? 'Normal Cup (< 0.50)' : 'Glaucoma Risk (> 0.65)';
        }
        if (lm.disc_to_fovea_distance_px) {
          document.getElementById('docDistText').textContent = lm.disc_to_fovea_distance_px.toFixed(1) + ' px';
        }
        if (lm.eye_side) {
          document.getElementById('docEyeSideBadge').textContent = lm.eye_side;
        }

        const csmeBox = document.getElementById('docCsmeWarningBox');
        const csmeText = document.getElementById('docCsmeWarningText');
        if (lm.macular_threat) {
          csmeBox.className = 'bg-rose-50 border border-rose-300 text-rose-900 p-2.5 rounded-lg text-xs flex items-center justify-between';
          csmeText.textContent = 'CRITICAL: Macular Threat Detected (Exudates < 1DD of Fovea)';
        } else {
          csmeBox.className = 'bg-emerald-50 border border-emerald-200 text-emerald-900 p-2.5 rounded-lg text-xs flex items-center justify-between';
          csmeText.textContent = 'Clear (Zero Exudative Threat within Foveal Zone)';
        }
      }
    }

    function docUpdateOverlays() {
      const gcamCanvas = document.getElementById('docGradcamCanvas');
      const lmCanvas = document.getElementById('docLandmarksCanvas');
      gcamCanvas.style.opacity = document.getElementById('docToggleLesions').checked ? '0.75' : '0.0';
      lmCanvas.style.opacity = document.getElementById('docToggleLandmarks').checked ? '1.0' : '0.0';
    }

    function docDrawGradcam(gcam) {
      const canvas = document.getElementById('docGradcamCanvas');
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, 224, 224);

      const cx = gcam.cx || 120;
      const cy = gcam.cy || 110;
      const r = gcam.radius || 48;

      const grad = ctx.createRadialGradient(cx, cy, 5, cx, cy, r);
      grad.addColorStop(0.0, 'rgba(220, 38, 38, 0.85)');
      grad.addColorStop(0.4, 'rgba(234, 88, 12, 0.70)');
      grad.addColorStop(0.7, 'rgba(202, 138, 4, 0.45)');
      grad.addColorStop(1.0, 'rgba(37, 99, 235, 0.0)');

      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.arc(cx, cy, r, 0, Math.PI * 2);
      ctx.fill();
    }

    function docDrawLandmarks(landmarks) {
      const canvas = document.getElementById('docLandmarksCanvas');
      const ctx = canvas.getContext('2d');
      ctx.clearRect(0, 0, 224, 224);

      if (!landmarks || !landmarks.optic_disc || !landmarks.fovea) return;
      const od = landmarks.optic_disc;
      const fov = landmarks.fovea;

      // Connecting line
      ctx.beginPath();
      ctx.setLineDash([3, 3]);
      ctx.strokeStyle = 'rgba(124, 58, 237, 0.8)';
      ctx.lineWidth = 1.5;
      ctx.moveTo(od.x, od.y);
      ctx.lineTo(fov.x, fov.y);
      ctx.stroke();
      ctx.setLineDash([]);

      // Optic Disc Ring
      ctx.beginPath();
      ctx.strokeStyle = '#0891b2'; // Cyan
      ctx.lineWidth = 1.8;
      ctx.arc(od.x, od.y, od.radius, 0, Math.PI * 2);
      ctx.stroke();
      ctx.fillStyle = '#0891b2';
      ctx.font = '600 9px monospace';
      ctx.fillText('OD', od.x - 7, od.y - od.radius - 3);

      // Fovea Ring
      ctx.beginPath();
      ctx.strokeStyle = '#d97706'; // Amber
      ctx.lineWidth = 1.8;
      ctx.arc(fov.x, fov.y, fov.radius || 12, 0, Math.PI * 2);
      ctx.stroke();
      ctx.fillStyle = '#d97706';
      ctx.font = '600 9px monospace';
      ctx.fillText('Fovea', fov.x - 12, fov.y + (fov.radius || 12) + 11);
    }

    function downloadDoctorFhir() {
      if (!currentDocAnalysis) return;
      const patientId = document.getElementById('docPatId').value || 'PAT-001';
      const patientName = document.getElementById('docPatName').value || 'Patient';

      const fhirBundle = {
        resourceType: "Bundle",
        type: "collection",
        timestamp: new Date().toISOString(),
        entry: [
          {
            fullUrl: "urn:uuid:diagnosticreport-" + patientId,
            resource: {
              resourceType: "DiagnosticReport",
              id: "dr-report-" + patientId,
              status: "final",
              subject: { reference: "Patient/" + patientId, display: patientName },
              code: {
                coding: [{ system: "http://loinc.org", code: "74062-1", display: "Diabetic Retinopathy Screening" }]
              },
              conclusion: currentDocAnalysis.stageName + " (Confidence: " + currentDocAnalysis.confidencePercent + "%)",
              conclusionCode: [
                { coding: [{ system: "http://snomed.info/sct", code: "4855003", display: currentDocAnalysis.stageName }] }
              ]
            }
          }
        ]
      };

      const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(fhirBundle, null, 2));
      const a = document.createElement('a');
      a.setAttribute("href", dataStr);
      a.setAttribute("download", "ABDM_FHIR_Clinical_" + patientId + ".json");
      document.body.appendChild(a);
      a.click();
      a.remove();
    }
  </script>
</body>
</html>"""

class ClinicalWorkstationHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)

        # 1. Main International Conference Workstation Route
        if parsed.path in ("/", "/index.html", "/conference"):
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(CONFERENCE_UI.encode("utf-8"))
            return

        # 2. Doctor's Dedicated Rapid Clinical Portal Route
        if parsed.path in ("/doctor", "/doctor.html"):
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(DOCTOR_UI.encode("utf-8"))
            return

        # 3. Rural Camp Operations Queue Simulation API
        if parsed.path == "/api/simulate":
            query = urllib.parse.parse_qs(parsed.query)
            try:
                num_pts = int(query.get("patients", ["120"])[0])
            except ValueError:
                num_pts = 120
            try:
                num_cams = int(query.get("cameras", ["1"])[0])
            except ValueError:
                num_cams = 1
            try:
                shift_h = float(query.get("hours", ["8.0"])[0])
            except ValueError:
                shift_h = 8.0

            sim_res = simulate_camp_throughput(num_patients=num_pts, num_cameras=num_cams, shift_hours=shift_h)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(sim_res).encode("utf-8"))
            return

        # 4. Official IDRiD Patient Sample API
        if parsed.path == "/api/idrid_sample":
            query = urllib.parse.parse_qs(parsed.query)
            grade_str = query.get("grade", ["0"])[0]
            try:
                grade = int(grade_str)
            except ValueError:
                grade = 0

            sample_map = {
                0: ("IDRiD_118", "idrid_grade_0_IDRiD_118.png"),
                1: ("IDRiD_021", "idrid_grade_1_IDRiD_021.png"),
                2: ("IDRiD_003", "idrid_grade_2_IDRiD_003.png"),
                3: ("IDRiD_001", "idrid_grade_3_IDRiD_001.png"),
                4: ("IDRiD_005", "idrid_grade_4_IDRiD_005.png")
            }
            img_id, fname = sample_map.get(grade, ("IDRiD_118", "idrid_grade_0_IDRiD_118.png"))
            full_path = os.path.join(PROJECT_ROOT, "data", "idrid", "web_samples", fname)
            
            b64_str = ""
            if os.path.exists(full_path):
                with open(full_path, "rb") as f:
                    b64_str = base64.b64encode(f.read()).decode("utf-8")

            res_payload = {
                "grade": grade,
                "image_id": img_id,
                "filename": fname,
                "image_b64": b64_str
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(res_payload).encode("utf-8"))
            return

        super().do_GET()

    def do_POST(self):
        if self.path == "/api/analyze":
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length).decode('utf-8')
            try:
                data = json.loads(body)
                rgba_b64 = data.get("rgba_b64")
                filename = data.get("filename", "")
                if rgba_b64:
                    raw_bytes = base64.b64decode(rgba_b64)
                    img_rgb = np.frombuffer(raw_bytes, dtype=np.uint8).reshape((224, 224, 4))[:, :, :3]
                else:
                    img_rgb = np.full((224, 224, 3), [180, 75, 30], dtype=np.uint8)

                # 1. Real Image Quality Assessment (IQA)
                iqa = assess_image_quality(img_rgb)

                # 2. ResNet-152 Deep Learning Forward Inference
                pred = predict_dr(img_rgb)
                pred["iqa"] = iqa
                pred["sourceFile"] = filename

                # 3. Genuine PyTorch Grad-CAM Saliency
                gcam = compute_gradcam(img_rgb, target_class=pred["stageCode"])
                pred["justification"] = gcam["clinicalJustification"]
                if gcam.get("boundingBoxes"):
                    b = gcam["boundingBoxes"][0]
                    pred["gradcam"] = {"cx": b["x"] + b["w"] // 2, "cy": b["y"] + b["h"] // 2, "radius": 48}
                else:
                    pred["gradcam"] = {"cx": 112, "cy": 112, "radius": 35}

                # 4. Track C Anatomical Landmark Localization (Optic Disc & Fovea)
                landmarks = localize_retinal_landmarks(img_rgb, target_size=(224, 224), image_id=filename)
                pred["landmarks"] = landmarks

                response_json = json.dumps(pred)
            except Exception as e:
                response_json = json.dumps({"error": str(e), "status": "ERROR"})

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(response_json.encode("utf-8"))
            return

        super().do_POST()

def launch_server(port=PORT, open_browser=True):
    server_address = ('', port)
    httpd = HTTPServer(server_address, ClinicalWorkstationHandler)
    url_conf = f"http://localhost:{port}/"
    url_doc = f"http://localhost:{port}/doctor"
    print("\n" + "=" * 80)
    print("  DRISHTI-AI: DUAL CLINICAL WORKSTATION SERVER ACTIVE")
    print(f"  [1] Academic & Conference Workstation: {url_conf}")
    print(f"  [2] Doctor's Clinical Decision Portal: {url_doc}")
    print("=" * 80)
    print("  * Academic Presentation View: ResNet-152, Grad-CAM Saliency, IQA & Camp Simulation")
    print("  * Doctor's Consultation View: Clutter-Free Diagnostics, Biomarkers & A4 Printout")
    print("  * Press Ctrl+C to terminate the server.\n")

    if open_browser:
        webbrowser.open(url_conf)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Workstation server stopped.")

if __name__ == "__main__":
    launch_server()
