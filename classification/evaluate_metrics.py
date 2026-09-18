"""
classification/evaluate_metrics.py
==================================
Multi-Class Statistical Evaluation Engine.
Computes Cohen's Quadratic Weighted Kappa, Confusion Matrix, Sensitivity & Specificity.
"""

from typing import List, Dict, Any
import numpy as np

def compute_quadratic_weighted_kappa(y_true: List[int], y_pred: List[int], num_classes: int = 5) -> float:
    """
    Computes Cohen's Quadratic Weighted Kappa penalty matrix:
        w_ij = (i - j)^2 / (N - 1)^2
    Penalizes distant misclassifications (e.g. Stage 0 vs Stage 4) heavily.
    """
    conf_mat = np.zeros((num_classes, num_classes), dtype=np.float64)
    for t, p in zip(y_true, y_pred):
        conf_mat[t, p] += 1.0

    total = np.sum(conf_mat)
    if total == 0:
        return 0.0

    hist_true = np.sum(conf_mat, axis=1)
    hist_pred = np.sum(conf_mat, axis=0)

    expected = np.outer(hist_true, hist_pred) / total

    weights = np.zeros((num_classes, num_classes), dtype=np.float64)
    for i in range(num_classes):
        for j in range(num_classes):
            weights[i, j] = ((i - j) ** 2) / ((num_classes - 1) ** 2)

    numerator = np.sum(weights * conf_mat)
    denominator = np.sum(weights * expected)

    if denominator == 0:
        return 1.0

    return float(1.0 - (numerator / denominator))

def evaluate_metrics(y_true: List[int], y_pred: List[int]) -> Dict[str, Any]:
    """
    Computes comprehensive multi-class and clinical triage screening metrics.
    """
    y_true = np.array(y_true)
    y_pred = np.array(y_pred)
    
    accuracy = float(np.mean(y_true == y_pred))
    kappa = compute_quadratic_weighted_kappa(y_true.tolist(), y_pred.tolist(), 5)
    
    # Binary Triage: Referable DR (Stage >= 2) vs Non-Referable (Stage < 2)
    bin_true = (y_true >= 2).astype(int)
    bin_pred = (y_pred >= 2).astype(int)
    
    tp = np.sum((bin_true == 1) & (bin_pred == 1))
    tn = np.sum((bin_true == 0) & (bin_pred == 0))
    fp = np.sum((bin_true == 0) & (bin_pred == 1))
    fn = np.sum((bin_true == 1) & (bin_pred == 0))
    
    sensitivity = float(tp / (tp + fn)) if (tp + fn) > 0 else 0.0
    specificity = float(tn / (tn + fp)) if (tn + fp) > 0 else 0.0
    ppv = float(tp / (tp + fp)) if (tp + fp) > 0 else 0.0
    npv = float(tn / (tn + fn)) if (tn + fn) > 0 else 0.0
    
    return {
        "accuracy": round(accuracy, 4),
        "quadraticWeightedKappa": round(kappa, 4),
        "referableSensitivity": round(sensitivity, 4),
        "referableSpecificity": round(specificity, 4),
        "positivePredictiveValue": round(ppv, 4),
        "negativePredictiveValue": round(npv, 4),
        "triageCounts": {"TP": int(tp), "TN": int(tn), "FP": int(fp), "FN": int(fn)}
    }

if __name__ == "__main__":
    # Test with cohort benchmark
    y_t = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4]
    y_p = [0, 0, 1, 1, 2, 2, 3, 2, 4, 4]
    res = evaluate_metrics(y_t, y_p)
    print("Cohort Validation Metrics:")
    for k, v in res.items():
        print(f"  {k}: {v}")
