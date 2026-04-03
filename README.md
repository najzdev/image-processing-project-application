# 🖼️ IISE Image Analyzer Pro

> A MATLAB-based desktop application for image processing and analysis, developed as part of the IISE 2026 program.

**Authors:** Hamza Labbaalli & Abdelouahed Id-Boubrik  
**Program:** IISE 2026

---

## 📋 Overview

IISE Image Analyzer Pro is an interactive GUI application built with MATLAB's `uicontrol` framework. It allows users to load images, apply a variety of intensity transformations and filters, visualize histograms, and export processed results — all from a clean, intuitive interface.

---

## ✨ Features

- **Image Loading** — Supports `.jpg`, `.png`, `.bmp`, and `.tif` formats
- **Multiple Transformations:**
  - Original (no filter)
  - Gamma Correction (adjustable via slider)
  - Exponential Transformation
  - Logarithmic Transformation
  - Linear Contrast Stretching
  - Histogram Equalization
  - Edge Detection (Sobel)
  - Binary Segmentation (Otsu's method)
- **Live Histogram** — Updates with each transformation
- **Statistical Analysis** — Displays filter name, mean, and standard deviation
- **Image Export** — Save processed images as `.png`

---

## 🖥️ Requirements

| Requirement | Details |
|-------------|---------|
| MATLAB | R2013b or later (compatible with older versions) |
| Toolboxes | Image Processing Toolbox |

> **Note:** The `.exe` version (`Project_TI_App.exe`) can be run without a MATLAB license using the free MATLAB Runtime (MCR). Download the appropriate MCR version from MathWorks.

---

## 🚀 Getting Started

### Running from MATLAB

1. Open MATLAB.
2. Navigate to the project directory.
3. Run the main function:
   ```matlab
   Projet_TI_IISE_2026()
   ```

### Running the Standalone Executable

1. Ensure the MATLAB Runtime (MCR) is installed on your machine.
2. Double-click `Project_TI_App.exe` or run it from the command line:
   ```
   Project_TI_App.exe
   ```

---

## 🗂️ Project Structure

```
📁 Project
├── Projet_TI_App.m          # Main MATLAB source file
├── Project_TI_App.exe       # Compiled standalone executable
└── README.md                # This file
```

---

## 🧪 How to Use

1. **Load an Image** — Click the **CHARGER** button and select an image file.
2. **Choose a Filter** — Use the dropdown menu to select a transformation.
3. **Adjust Gamma** (if applicable) — A slider appears for Gamma Correction; drag to tune.
4. **View Results** — The processed image, histogram, and stats update automatically.
5. **Save Output** — Click the **SAUVEGARDER** button to export the result.

---

## 📊 Transformations — Technical Reference

| Filter | Description |
|--------|-------------|
| **Originale** | Displays the unmodified original image |
| **Correction Gamma** | Applies `imadjust` with a user-defined γ ∈ [0.1, 4.0] |
| **Exponentielle** | Maps intensity via `(e^x − 1) / (e − 1)` |
| **Logarithmique** | Maps intensity via `log(1 + x) / log(2)` |
| **Étirement Linéaire** | Auto contrast stretch using `imadjust` |
| **Égalisation Hist.** | Histogram equalization via `histeq` |
| **Contours (Sobel)** | Edge detection using the Sobel operator |
| **Segmentation (OTSU)** | Binary thresholding using Otsu's method |

---

## 📄 License

This project was developed for academic purposes as part of the IISE 2026 program. All rights reserved by the authors.
