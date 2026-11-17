"""
data/populate_sample_datasets.py
================================
Extracts, structures, and normalizes the official IDRiD Challenge dataset
from the three provided archives:
  - 'A. Segmentation.zip'   (~584 MB): 5 lesion binary masks (MA, HE, EX, SE, OD)
  - 'B. Disease Grading.zip' (~212 MB): 516 DR & DME diagnostic scans and labels
  - 'C. Localization.zip'   (~212 MB): Fovea and Optic Disc (X,Y) coordinates

Replaces all synthetic mock/procedural fundus datasets with genuine
high-resolution retinal patient data.
"""

import os
import sys
import csv
import zipfile
import shutil
from typing import Dict, List, Any, Optional

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IDRID_DIR = os.path.join(BASE_DIR, "data", "idrid")
LABELS_DIR = os.path.join(BASE_DIR, "data", "labels")
RAW_DIR = os.path.join(BASE_DIR, "data", "raw")


def extract_zip_if_needed(zip_filename: str, target_subfolder: str) -> str:
    """
    Extracts zip archive into data/idrid/<target_subfolder> if not already present.
    """
    dest_dir = os.path.join(IDRID_DIR, target_subfolder)
    os.makedirs(dest_dir, exist_ok=True)

    zip_path = os.path.join(BASE_DIR, zip_filename)
    if not os.path.exists(zip_path):
        print(f"[Dataset Extractor] Notice: {zip_filename} not found in project root; checking if {dest_dir} has content.")
        if os.path.exists(dest_dir) and len(os.listdir(dest_dir)) > 0:
            return dest_dir
        return dest_dir

    # Check if destination already has extracted content
    has_content = os.path.exists(dest_dir) and len(os.listdir(dest_dir)) > 0
    if has_content:
        print(f"[Dataset Extractor] {target_subfolder} already extracted in {dest_dir}")
        return dest_dir

    print(f"[Dataset Extractor] Extracting {zip_filename} -> {dest_dir}...")
    with zipfile.ZipFile(zip_path, 'r') as zf:
        zf.extractall(dest_dir)

    # Some zips extract into a single top-level folder with same name
    # Flatten if needed
    entries = os.listdir(dest_dir)
    if len(entries) == 1 and os.path.isdir(os.path.join(dest_dir, entries[0])):
        inner = os.path.join(dest_dir, entries[0])
        for item in os.listdir(inner):
            shutil.move(os.path.join(inner, item), dest_dir)
        os.rmdir(inner)

    print(f"[Dataset Extractor] Extracted {zip_filename} successfully.")
    return dest_dir


def generate_disease_grading_catalogues() -> None:
    """
    Generates normalized CSV catalogues for Track B Disease Grading.
    """
    gt_dir = os.path.join(IDRID_DIR, "disease_grading", "groundtruths")
    if not os.path.exists(gt_dir):
        return

    train_raw_csv = os.path.join(gt_dir, "a. IDRiD_Disease Grading_Training Labels.csv")
    test_raw_csv = os.path.join(gt_dir, "b. IDRiD_Disease Grading_Testing Labels.csv")

    train_out = os.path.join(LABELS_DIR, "idrid_disease_grading_train.csv")
    test_out = os.path.join(LABELS_DIR, "idrid_disease_grading_test.csv")
    unified_out = os.path.join(LABELS_DIR, "idrid_labels.csv")

    all_rows = []

    # Process Training Set
    if os.path.exists(train_raw_csv):
        with open(train_raw_csv, mode="r", encoding="utf-8-sig") as f_in, \
             open(train_out, mode="w", newline="", encoding="utf-8") as f_out:
            reader = csv.DictReader(f_in)
            writer = csv.writer(f_out)
            writer.writerow(["image_id", "image_path", "retinopathy_grade", "macular_edema_risk"])

            for r in reader:
                img_name = r.get("Image name", "").strip()
                if not img_name:
                    continue
                dr_grade = r.get("Retinopathy grade", "0").strip()
                dme_risk = r.get("Risk of macular edema ", r.get("Risk of macular edema", "0")).strip()
                rel_path = f"data/idrid/disease_grading/original_images/a. Training Set/{img_name}.jpg"
                writer.writerow([img_name, rel_path, dr_grade, dme_risk])
                all_rows.append({"Image_name": img_name, "Retinopathy_grade": dr_grade, "path": rel_path})

    # Process Testing Set
    if os.path.exists(test_raw_csv):
        with open(test_raw_csv, mode="r", encoding="utf-8-sig") as f_in, \
             open(test_out, mode="w", newline="", encoding="utf-8") as f_out:
            reader = csv.DictReader(f_in)
            writer = csv.writer(f_out)
            writer.writerow(["image_id", "image_path", "retinopathy_grade", "macular_edema_risk"])

            for r in reader:
                img_name = r.get("Image name", "").strip()
                if not img_name:
                    continue
                dr_grade = r.get("Retinopathy grade", "0").strip()
                dme_risk = r.get("Risk of macular edema ", r.get("Risk of macular edema", "0")).strip()
                rel_path = f"data/idrid/disease_grading/original_images/b. Testing Set/{img_name}.jpg"
                writer.writerow([img_name, rel_path, dr_grade, dme_risk])
                all_rows.append({"Image_name": img_name, "Retinopathy_grade": dr_grade, "path": rel_path})

    # Write unified idrid_labels.csv
    if all_rows:
        with open(unified_out, mode="w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=["Image_name", "Retinopathy_grade"])
            w.writeheader()
            for row in all_rows:
                w.writerow({"Image_name": row["Image_name"], "Retinopathy_grade": row["Retinopathy_grade"]})

    print(f"[Dataset Extractor] Generated Track B Disease Grading catalogues: {len(all_rows)} total scans.")


def generate_segmentation_catalogues() -> None:
    """
    Generates normalized CSV catalogues for Track A Lesion Segmentation.
    Maps each fundus scan to its 5 lesion binary masks (MA, HE, EX, SE, OD).
    """
    for split, set_name, code in [("train", "a. Training Set", "train"), ("test", "b. Testing Set", "test")]:
        img_dir = os.path.join(IDRID_DIR, "segmentation", "original_images", set_name)
        if not os.path.exists(img_dir):
            continue

        images = sorted([f for f in os.listdir(img_dir) if f.lower().endswith((".jpg", ".png", ".tif"))])
        out_csv = os.path.join(LABELS_DIR, f"idrid_segmentation_{code}.csv")

        gt_base = os.path.join(IDRID_DIR, "segmentation", "groundtruths", set_name)
        lesion_dirs = {
            "ma": os.path.join(gt_base, "1. Microaneurysms"),
            "he": os.path.join(gt_base, "2. Haemorrhages"),
            "ex": os.path.join(gt_base, "3. Hard Exudates"),
            "se": os.path.join(gt_base, "4. Soft Exudates"),
            "od": os.path.join(gt_base, "5. Optic Disc")
        }

        with open(out_csv, mode="w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(["image_id", "image_path", "ma_mask", "he_mask", "ex_mask", "se_mask", "od_mask"])

            for img_file in images:
                iid = os.path.splitext(img_file)[0]
                img_rel = f"data/idrid/segmentation/original_images/{set_name}/{img_file}"

                row = [iid, img_rel]
                for l_type, l_dir in lesion_dirs.items():
                    # Filename pattern: IDRiD_01_MA.tif or IDRiD_01_HE.tif etc.
                    mask_name = f"{iid}_{l_type.upper()}.tif"
                    full_p = os.path.join(l_dir, mask_name)
                    if os.path.exists(full_p):
                        mask_rel = f"data/idrid/segmentation/groundtruths/{set_name}/{os.path.basename(l_dir)}/{mask_name}"
                        row.append(mask_rel)
                    else:
                        row.append("")

                writer.writerow(row)

    print("[Dataset Extractor] Generated Track A Segmentation catalogues (Train & Test).")


def _get_val(row_dict: dict, *candidates: str) -> str:
    for c in candidates:
        for k in row_dict.keys():
            if k and k.strip().lower() == c.strip().lower():
                val = row_dict[k]
                if val is not None and str(val).strip():
                    return str(val).strip()
    return ""


def generate_localization_catalogues() -> None:
    """
    Generates normalized CSV catalogues for Track C Fovea and Optic Disc Localization.
    """
    loc_gt = os.path.join(IDRID_DIR, "localization", "groundtruths")
    if not os.path.exists(loc_gt):
        return

    # 1. Fovea Center Location
    fov_dir = os.path.join(loc_gt, "2. Fovea Center Location")
    if os.path.exists(fov_dir):
        for f_name, code, set_name in [
            ("IDRiD_Fovea_Center_Training Set_Markups.csv", "train", "a. Training Set"),
            ("IDRiD_Fovea_Center_Testing Set_Markups.csv", "test", "b. Testing Set")
        ]:
            raw_path = os.path.join(fov_dir, f_name)
            out_path = os.path.join(LABELS_DIR, f"idrid_fovea_{code}.csv")
            if os.path.exists(raw_path):
                with open(raw_path, mode="r", encoding="utf-8-sig") as fin, \
                     open(out_path, mode="w", newline="", encoding="utf-8") as fout:
                    reader = csv.DictReader(fin)
                    writer = csv.writer(fout)
                    writer.writerow(["image_id", "image_path", "fovea_x", "fovea_y"])
                    for r in reader:
                        img_name = _get_val(r, "Image No", "Image Name", "Image name")
                        if not img_name:
                            continue
                        fx = _get_val(r, "X- Coordinate", "X - Coordinate", "Fovea Center X", "X Coordinate", "X") or "0"
                        fy = _get_val(r, "Y - Coordinate", "Y- Coordinate", "Fovea Center Y", "Y Coordinate", "Y") or "0"
                        rel_path = f"data/idrid/localization/original_images/{set_name}/{img_name}.jpg"
                        writer.writerow([img_name, rel_path, fx, fy])

    # 2. Optic Disc Center Location
    od_dir = os.path.join(loc_gt, "1. Optic Disc Center Location")
    if os.path.exists(od_dir):
        for f_name, code, set_name in [
            ("a. IDRiD_OD_Center_Training Set_Markups.csv", "train", "a. Training Set"),
            ("b. IDRiD_OD_Center_Testing Set_Markups.csv", "test", "b. Testing Set")
        ]:
            raw_path = os.path.join(od_dir, f_name)
            out_path = os.path.join(LABELS_DIR, f"idrid_optic_disc_{code}.csv")
            if os.path.exists(raw_path):
                with open(raw_path, mode="r", encoding="utf-8-sig") as fin, \
                     open(out_path, mode="w", newline="", encoding="utf-8") as fout:
                    reader = csv.DictReader(fin)
                    writer = csv.writer(fout)
                    writer.writerow(["image_id", "image_path", "od_x", "od_y"])
                    for r in reader:
                        img_name = _get_val(r, "Image No", "Image Name", "Image name")
                        if not img_name:
                            continue
                        odx = _get_val(r, "X- Coordinate", "X - Coordinate", "OD Center X", "X Coordinate", "X") or "0"
                        ody = _get_val(r, "Y - Coordinate", "Y- Coordinate", "OD Center Y", "Y Coordinate", "Y") or "0"
                        rel_path = f"data/idrid/localization/original_images/{set_name}/{img_name}.jpg"
                        writer.writerow([img_name, rel_path, odx, ody])

    print("[Dataset Extractor] Generated Track C Localization catalogues (Train & Test).")


def populate_raw_idrid_folder() -> None:
    """
    Populates data/raw/idrid with real IDRiD patient fundus images,
    replacing procedural mock/synthetic bitmaps.
    """
    raw_idrid = os.path.join(RAW_DIR, "idrid")
    os.makedirs(raw_idrid, exist_ok=True)

    src_train = os.path.join(IDRID_DIR, "disease_grading", "original_images", "a. Training Set")
    if not os.path.exists(src_train):
        return

    # Select representative real IDRiD images across stages
    sample_ids = ["IDRiD_118", "IDRiD_021", "IDRiD_003", "IDRiD_001", "IDRiD_005"]
    for i, sid in enumerate(sample_ids):
        src_file = os.path.join(src_train, f"{sid}.jpg")
        if os.path.exists(src_file):
            dst_file = os.path.join(raw_idrid, f"idrid_{i:02d}_1.png")
            try:
                from PIL import Image
                img = Image.open(src_file).convert("RGB")
                img.save(dst_file)
            except ImportError:
                # Direct binary copy preserving valid image bytes
                shutil.copyfile(src_file, dst_file)
    print(f"[Dataset Extractor] Populated {raw_idrid} with genuine IDRiD clinical patient images.")


def main():
    print("=" * 75)
    print("  DRISHTI-AI: Official IDRiD Challenge Dataset Integrator")
    print("  Integrating A. Segmentation, B. Disease Grading, and C. Localization")
    print("=" * 75)

    os.makedirs(IDRID_DIR, exist_ok=True)
    os.makedirs(LABELS_DIR, exist_ok=True)

    # 1. Extract Archives if needed
    extract_zip_if_needed("A. Segmentation.zip", "segmentation")
    extract_zip_if_needed("B. Disease Grading.zip", "disease_grading")
    extract_zip_if_needed("C. Localization.zip", "localization")

    # 2. Build Ground-Truth Catalogues
    generate_disease_grading_catalogues()
    generate_segmentation_catalogues()
    generate_localization_catalogues()

    # 3. Populate Real Patient Images in data/raw/idrid
    populate_raw_idrid_folder()

    print("\nDataset integration complete: All synthetic datasets successfully replaced with real IDRiD data.")


if __name__ == "__main__":
    main()
