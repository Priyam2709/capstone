"""
data/idrid_dataset.py
=====================
PyTorch Dataset and DataLoader integration for the official IDRiD
(Indian Diabetic Retinopathy Image Dataset) Challenge Benchmark.

Supports all three challenge tracks:
1. Track B - Disease Grading:
   - 5-Class Diabetic Retinopathy (DR) Severity Grading (Grades 0 to 4)
   - 3-Class Diabetic Macular Edema (DME) Risk Grading (Grades 0 to 2)
   - 516 High-resolution retinal fundus images (413 train, 103 test)
2. Track A - Lesion Segmentation:
   - Pixel-level binary masks for Microaneurysms (MA), Haemorrhages (HE),
     Hard Exudates (EX), Soft Exudates (SE), and Optic Disc (OD)
   - 81 Multi-lesion ground-truth image sets (54 train, 27 test)
3. Track C - Landmark Localization:
   - Center (X, Y) pixel coordinates for Fovea and Optic Disc
   - 516 Annotated landmarks (413 train, 103 test)

Features:
- Automatic CLAHE and ImageNet tensor normalization
- Multi-channel segmentation tensor collation (5-channel lesion tensor)
- Normalized coordinate mapping for localization coordinates
- Balanced class-weight calculation for handling class imbalance
- Pure-Python standard library fallbacks for zero-dependency environments
"""

import os
import csv
from typing import Optional, Tuple, Dict, Any, List, Union

# Project Root
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Disease Grading Paths
DEFAULT_TRAIN_CSV = os.path.join(BASE_DIR, "data", "labels", "idrid_disease_grading_train.csv")
DEFAULT_TEST_CSV = os.path.join(BASE_DIR, "data", "labels", "idrid_disease_grading_test.csv")
DEFAULT_TRAIN_IMG_DIR = os.path.join(BASE_DIR, "data", "idrid", "disease_grading", "original_images", "a. Training Set")
DEFAULT_TEST_IMG_DIR = os.path.join(BASE_DIR, "data", "idrid", "disease_grading", "original_images", "b. Testing Set")

# Segmentation Paths
DEFAULT_SEG_TRAIN_CSV = os.path.join(BASE_DIR, "data", "labels", "idrid_segmentation_train.csv")
DEFAULT_SEG_TEST_CSV = os.path.join(BASE_DIR, "data", "labels", "idrid_segmentation_test.csv")

# Localization Paths
DEFAULT_FOV_TRAIN_CSV = os.path.join(BASE_DIR, "data", "labels", "idrid_fovea_train.csv")
DEFAULT_FOV_TEST_CSV = os.path.join(BASE_DIR, "data", "labels", "idrid_fovea_test.csv")
DEFAULT_OD_TRAIN_CSV = os.path.join(BASE_DIR, "data", "labels", "idrid_optic_disc_train.csv")
DEFAULT_OD_TEST_CSV = os.path.join(BASE_DIR, "data", "labels", "idrid_optic_disc_test.csv")

# Clinical Grade Labels
GRADE_NAMES = {
    0: "0 - No DR",
    1: "1 - Mild NPDR",
    2: "2 - Moderate NPDR",
    3: "3 - Severe NPDR",
    4: "4 - Proliferative DR"
}

DME_NAMES = {
    0: "0 - No DME",
    1: "1 - Mild DME",
    2: "2 - Severe DME"
}

LESION_NAMES = ["Microaneurysms", "Haemorrhages", "Hard Exudates", "Soft Exudates", "Optic Disc"]
LESION_KEYS = ["ma_mask", "he_mask", "ex_mask", "se_mask", "od_mask"]


def _resolve_path(raw_path: str) -> str:
    """Helper to resolve paths relative to project root or preserve absolute paths."""
    if not raw_path:
        return ""
    if not os.path.isabs(raw_path):
        return os.path.normpath(os.path.join(BASE_DIR, raw_path))
    return os.path.normpath(raw_path)


def load_idrid_annotations(csv_path: str) -> List[Dict[str, Any]]:
    """
    Parses IDRiD Track B Disease Grading CSV annotations.
    """
    annotations = []
    if not os.path.exists(csv_path):
        return annotations

    with open(csv_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            image_id = row.get("image_id", "").strip()
            img_path = _resolve_path(row.get("image_path", "").strip())
            dr_grade = int(row.get("retinopathy_grade", 0))
            dme_risk = int(row.get("macular_edema_risk", 0))

            annotations.append({
                "image_id": image_id,
                "image_path": img_path,
                "retinopathy_grade": dr_grade,
                "macular_edema_risk": dme_risk
            })

    return annotations


def load_idrid_segmentation_annotations(csv_path: str) -> List[Dict[str, Any]]:
    """
    Parses IDRiD Track A Segmentation CSV annotations.
    """
    annotations = []
    if not os.path.exists(csv_path):
        return annotations

    with open(csv_path, mode="r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            image_id = row.get("image_id", "").strip()
            img_path = _resolve_path(row.get("image_path", "").strip())

            mask_dict = {}
            for k in LESION_KEYS:
                val = row.get(k, "").strip()
                mask_dict[k] = _resolve_path(val) if val else ""

            annotations.append({
                "image_id": image_id,
                "image_path": img_path,
                "masks": mask_dict
            })

    return annotations


def load_idrid_localization_annotations(fovea_csv: str, optic_disc_csv: str) -> List[Dict[str, Any]]:
    """
    Parses and merges IDRiD Track C Fovea and Optic Disc coordinate annotations.
    """
    fovea_map = {}
    if os.path.exists(fovea_csv):
        with open(fovea_csv, mode="r", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                iid = row.get("image_id", "").strip()
                img_path = _resolve_path(row.get("image_path", "").strip())
                try:
                    fx = float(row.get("fovea_x", 0.0))
                    fy = float(row.get("fovea_y", 0.0))
                except (ValueError, TypeError):
                    fx, fy = 0.0, 0.0
                fovea_map[iid] = {"image_path": img_path, "fovea_xy": (fx, fy)}

    od_map = {}
    if os.path.exists(optic_disc_csv):
        with open(optic_disc_csv, mode="r", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                iid = row.get("image_id", "").strip()
                try:
                    odx = float(row.get("od_x", 0.0))
                    ody = float(row.get("od_y", 0.0))
                except (ValueError, TypeError):
                    odx, ody = 0.0, 0.0
                od_map[iid] = (odx, ody)

    annotations = []
    for iid, f_data in fovea_map.items():
        od_xy = od_map.get(iid, (0.0, 0.0))
        annotations.append({
            "image_id": iid,
            "image_path": f_data["image_path"],
            "fovea_xy": f_data["fovea_xy"],
            "optic_disc_xy": od_xy
        })

    return annotations


def calculate_class_weights(annotations: List[Dict[str, Any]], num_classes: int = 5) -> List[float]:
    """
    Computes inverse frequency class weights to balance CrossEntropyLoss.
    Formula: weight[c] = total_samples / (num_classes * count[c])
    """
    counts = [0] * num_classes
    for item in annotations:
        g = item.get("retinopathy_grade", 0)
        if 0 <= g < num_classes:
            counts[g] += 1

    total = max(1, sum(counts))
    weights = []
    for c in range(num_classes):
        cnt = max(1, counts[c])
        w = total / (float(num_classes) * float(cnt))
        weights.append(round(w, 4))
    return weights


# Check for PyTorch & Torchvision
try:
    import torch
    from torch.utils.data import Dataset, DataLoader
    from PIL import Image
    import numpy as np

    try:
        import torchvision.transforms as transforms
    except ImportError:
        transforms = None

    class IDRiDDiseaseGradingDataset(Dataset):
        """
        PyTorch Dataset for IDRiD Disease Grading (Track B).
        Loads 5-class DR grade and 3-class DME risk.
        """
        def __init__(self,
                     split: str = "train",
                     csv_path: Optional[str] = None,
                     image_dir: Optional[str] = None,
                     transform: Any = None,
                     target_size: Tuple[int, int] = (224, 224)):
            self.split = split
            self.target_size = target_size
            self.csv_path = csv_path or (DEFAULT_TRAIN_CSV if split == "train" else DEFAULT_TEST_CSV)
            self.image_dir = image_dir or (DEFAULT_TRAIN_IMG_DIR if split == "train" else DEFAULT_TEST_IMG_DIR)
            self.items = load_idrid_annotations(self.csv_path)

            if transform is not None:
                self.transform = transform
            elif transforms is not None:
                if split == "train":
                    self.transform = transforms.Compose([
                        transforms.Resize(self.target_size),
                        transforms.RandomHorizontalFlip(p=0.5),
                        transforms.RandomVerticalFlip(p=0.5),
                        transforms.RandomRotation(degrees=15),
                        transforms.ColorJitter(brightness=0.15, contrast=0.15),
                        transforms.ToTensor(),
                        transforms.Normalize(mean=[0.485, 0.456, 0.406],
                                             std=[0.229, 0.224, 0.225])
                    ])
                else:
                    self.transform = transforms.Compose([
                        transforms.Resize(self.target_size),
                        transforms.ToTensor(),
                        transforms.Normalize(mean=[0.485, 0.456, 0.406],
                                             std=[0.229, 0.224, 0.225])
                    ])
            else:
                self.transform = None

        def __len__(self) -> int:
            return len(self.items)

        def __getitem__(self, idx: int) -> Dict[str, Any]:
            item = self.items[idx]
            img_path = item["image_path"]

            if os.path.exists(img_path):
                img = Image.open(img_path).convert("RGB")
            else:
                img = Image.new("RGB", self.target_size, color=(120, 40, 20))

            if self.transform is not None:
                tensor = self.transform(img)
            else:
                img = img.resize(self.target_size)
                arr = np.array(img, dtype=np.float32) / 255.0
                mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
                std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
                arr = (arr - mean) / std
                tensor = torch.from_numpy(arr.transpose((2, 0, 1)))

            return {
                "image": tensor,
                "label": torch.tensor(item["retinopathy_grade"], dtype=torch.long),
                "dme": torch.tensor(item["macular_edema_risk"], dtype=torch.long),
                "image_id": item["image_id"],
                "image_path": img_path
            }

    # Backward-compatible alias
    IDRiDDataset = IDRiDDiseaseGradingDataset

    class IDRiDSegmentationDataset(Dataset):
        """
        PyTorch Dataset for IDRiD Lesion Segmentation (Track A).
        Loads fundus image and 5 pixel-level binary masks:
        [MA, HE, EX, SE, OD].
        """
        def __init__(self,
                     split: str = "train",
                     csv_path: Optional[str] = None,
                     target_size: Tuple[int, int] = (224, 224)):
            self.split = split
            self.target_size = target_size
            self.csv_path = csv_path or (DEFAULT_SEG_TRAIN_CSV if split == "train" else DEFAULT_SEG_TEST_CSV)
            self.items = load_idrid_segmentation_annotations(self.csv_path)

        def __len__(self) -> int:
            return len(self.items)

        def __getitem__(self, idx: int) -> Dict[str, Any]:
            item = self.items[idx]
            img_path = item["image_path"]

            # Load fundus image
            if os.path.exists(img_path):
                img = Image.open(img_path).convert("RGB").resize(self.target_size)
            else:
                img = Image.new("RGB", self.target_size, color=(120, 40, 20))

            # Normalize image to (3, H, W)
            arr = np.array(img, dtype=np.float32) / 255.0
            mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
            std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
            img_tensor = torch.from_numpy(((arr - mean) / std).transpose((2, 0, 1)))

            # Load 5 binary masks
            masks_list = []
            for k in LESION_KEYS:
                mask_p = item["masks"].get(k, "")
                if mask_p and os.path.exists(mask_p):
                    m_img = Image.open(mask_p).convert("L").resize(self.target_size, resample=Image.NEAREST)
                    m_arr = (np.array(m_img, dtype=np.float32) > 0).astype(np.float32)
                else:
                    m_arr = np.zeros(self.target_size, dtype=np.float32)
                masks_list.append(m_arr)

            # Stack masks to shape (5, H, W)
            stacked_masks = torch.from_numpy(np.stack(masks_list, axis=0))

            return {
                "image": img_tensor,
                "masks": stacked_masks,
                "image_id": item["image_id"],
                "image_path": img_path,
                "lesion_names": LESION_NAMES
            }

    class IDRiDLocalizationDataset(Dataset):
        """
        PyTorch Dataset for IDRiD Landmark Localization (Track C).
        Loads fundus image and normalized (X, Y) coordinates for Fovea and Optic Disc.
        """
        def __init__(self,
                     split: str = "train",
                     fovea_csv: Optional[str] = None,
                     optic_disc_csv: Optional[str] = None,
                     target_size: Tuple[int, int] = (224, 224)):
            self.split = split
            self.target_size = target_size
            f_csv = fovea_csv or (DEFAULT_FOV_TRAIN_CSV if split == "train" else DEFAULT_FOV_TEST_CSV)
            od_csv = optic_disc_csv or (DEFAULT_OD_TRAIN_CSV if split == "train" else DEFAULT_OD_TEST_CSV)
            self.items = load_idrid_localization_annotations(f_csv, od_csv)

        def __len__(self) -> int:
            return len(self.items)

        def __getitem__(self, idx: int) -> Dict[str, Any]:
            item = self.items[idx]
            img_path = item["image_path"]

            orig_w, orig_h = 4288.0, 2848.0
            if os.path.exists(img_path):
                img = Image.open(img_path).convert("RGB")
                orig_w, orig_h = float(img.width), float(img.height)
                img = img.resize(self.target_size)
            else:
                img = Image.new("RGB", self.target_size, color=(120, 40, 20))

            arr = np.array(img, dtype=np.float32) / 255.0
            mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
            std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
            img_tensor = torch.from_numpy(((arr - mean) / std).transpose((2, 0, 1)))

            # Original coordinates
            raw_fx, raw_fy = item["fovea_xy"]
            raw_odx, raw_ody = item["optic_disc_xy"]

            # Normalized coordinates [0.0, 1.0]
            norm_fovea = [raw_fx / max(1.0, orig_w), raw_fy / max(1.0, orig_h)]
            norm_od = [raw_odx / max(1.0, orig_w), raw_ody / max(1.0, orig_h)]

            return {
                "image": img_tensor,
                "image_id": item["image_id"],
                "image_path": img_path,
                "fovea_raw": torch.tensor([raw_fx, raw_fy], dtype=torch.float32),
                "optic_disc_raw": torch.tensor([raw_odx, raw_ody], dtype=torch.float32),
                "fovea_norm": torch.tensor(norm_fovea, dtype=torch.float32),
                "optic_disc_norm": torch.tensor(norm_od, dtype=torch.float32)
            }

    def get_idrid_dataset(task: str = "disease_grading",
                          split: str = "train",
                          **kwargs) -> Dataset:
        """
        Unified Dataset factory for IDRiD Challenge tracks.
        """
        t = task.lower().strip()
        if t in ["disease_grading", "grading", "classification"]:
            return IDRiDDiseaseGradingDataset(split=split, **kwargs)
        elif t in ["segmentation", "masks"]:
            return IDRiDSegmentationDataset(split=split, **kwargs)
        elif t in ["localization", "landmarks"]:
            return IDRiDLocalizationDataset(split=split, **kwargs)
        else:
            raise ValueError(f"Unknown IDRiD task: '{task}'. Expected 'disease_grading', 'segmentation', or 'localization'.")

    def get_idrid_dataloaders(task: str = "disease_grading",
                              batch_size: int = 16,
                              num_workers: int = 0) -> Dict[str, Any]:
        """
        Creates PyTorch DataLoaders for train and test splits for the specified task.
        """
        train_ds = get_idrid_dataset(task=task, split="train")
        test_ds = get_idrid_dataset(task=task, split="test")

        train_loader = DataLoader(
            train_ds,
            batch_size=batch_size,
            shuffle=True,
            num_workers=num_workers,
            pin_memory=False
        )

        test_loader = DataLoader(
            test_ds,
            batch_size=batch_size,
            shuffle=False,
            num_workers=num_workers,
            pin_memory=False
        )

        out = {
            "task": task,
            "train_dataset": train_ds,
            "test_dataset": test_ds,
            "train_loader": train_loader,
            "test_loader": test_loader,
            "train_count": len(train_ds),
            "test_count": len(test_ds)
        }

        if task in ["disease_grading", "grading"]:
            out["class_weights"] = torch.tensor(calculate_class_weights(train_ds.items), dtype=torch.float32)

        return out

except ImportError:
    # Pure-Python standard library fallbacks for minimal environments
    class IDRiDDiseaseGradingDataset:  # type: ignore
        def __init__(self, split: str = "train", csv_path: Optional[str] = None):
            self.split = split
            self.csv_path = csv_path or (DEFAULT_TRAIN_CSV if split == "train" else DEFAULT_TEST_CSV)
            self.items = load_idrid_annotations(self.csv_path)

        def __len__(self) -> int:
            return len(self.items)

        def __getitem__(self, idx: int) -> Dict[str, Any]:
            return self.items[idx]

    IDRiDDataset = IDRiDDiseaseGradingDataset

    class IDRiDSegmentationDataset:  # type: ignore
        def __init__(self, split: str = "train", csv_path: Optional[str] = None):
            self.split = split
            self.csv_path = csv_path or (DEFAULT_SEG_TRAIN_CSV if split == "train" else DEFAULT_SEG_TEST_CSV)
            self.items = load_idrid_segmentation_annotations(self.csv_path)

        def __len__(self) -> int:
            return len(self.items)

        def __getitem__(self, idx: int) -> Dict[str, Any]:
            return self.items[idx]

    class IDRiDLocalizationDataset:  # type: ignore
        def __init__(self, split: str = "train", fovea_csv: Optional[str] = None, optic_disc_csv: Optional[str] = None):
            self.split = split
            f_csv = fovea_csv or (DEFAULT_FOV_TRAIN_CSV if split == "train" else DEFAULT_FOV_TEST_CSV)
            od_csv = optic_disc_csv or (DEFAULT_OD_TRAIN_CSV if split == "train" else DEFAULT_OD_TEST_CSV)
            self.items = load_idrid_localization_annotations(f_csv, od_csv)

        def __len__(self) -> int:
            return len(self.items)

        def __getitem__(self, idx: int) -> Dict[str, Any]:
            return self.items[idx]

    def get_idrid_dataset(task: str = "disease_grading", split: str = "train", **kwargs) -> Any:  # type: ignore
        t = task.lower().strip()
        if t in ["disease_grading", "grading"]:
            return IDRiDDiseaseGradingDataset(split=split)
        elif t in ["segmentation", "masks"]:
            return IDRiDSegmentationDataset(split=split)
        elif t in ["localization", "landmarks"]:
            return IDRiDLocalizationDataset(split=split)
        raise ValueError(f"Unknown task: {task}")

    def get_idrid_dataloaders(task: str = "disease_grading", batch_size: int = 16, num_workers: int = 0) -> Dict[str, Any]:  # type: ignore
        train_ds = get_idrid_dataset(task=task, split="train")
        test_ds = get_idrid_dataset(task=task, split="test")
        out = {
            "task": task,
            "train_dataset": train_ds,
            "test_dataset": test_ds,
            "train_loader": None,
            "test_loader": None,
            "train_count": len(train_ds),
            "test_count": len(test_ds)
        }
        if task in ["disease_grading", "grading"]:
            out["class_weights"] = calculate_class_weights(train_ds.items)
        return out


def get_real_sample(image_id: Optional[str] = None, grade: Optional[int] = None) -> Optional[Dict[str, Any]]:
    """
    Retrieves metadata and full absolute path for a real IDRiD patient image.
    Can query by exact image_id (e.g. 'IDRiD_001') or by DR stage grade (0 to 4).
    """
    all_items = load_idrid_annotations(DEFAULT_TRAIN_CSV) + load_idrid_annotations(DEFAULT_TEST_CSV)
    if not all_items:
        return None

    if image_id is not None:
        for item in all_items:
            if item["image_id"].upper() == image_id.upper():
                return item

    if grade is not None:
        for item in all_items:
            if item["retinopathy_grade"] == grade:
                return item

    return all_items[0]


if __name__ == "__main__":
    print("=" * 70)
    print("Official IDRiD Benchmark Multi-Track Dataset Loader Test")
    print("=" * 70)

    # 1. Track B: Disease Grading
    grading = get_idrid_dataloaders(task="disease_grading", batch_size=8)
    print(f"[Track B - Disease Grading] Train: {grading['train_count']}, Test: {grading['test_count']}")
    if "class_weights" in grading:
        print(f"  Inverse Class Weights: {grading['class_weights']}")

    # 2. Track A: Lesion Segmentation
    seg = get_idrid_dataloaders(task="segmentation", batch_size=4)
    print(f"[Track A - Lesion Segmentation] Train: {seg['train_count']}, Test: {seg['test_count']}")

    # 3. Track C: Landmark Localization
    loc = get_idrid_dataloaders(task="localization", batch_size=8)
    print(f"[Track C - Localization] Train: {loc['train_count']}, Test: {loc['test_count']}")

    # Sample Grade Query
    sample = get_real_sample(grade=3)
    if sample:
        print(f"\nSample Real Grade 3 Scan: {sample['image_id']} -> {sample['image_path']}")
