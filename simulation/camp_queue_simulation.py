"""
simulation/camp_queue_simulation.py
===================================
Rural Primary Health Centre (PHC) Screening Camp Queue Simulation.
Formulates M/M/c Erlang-C discrete-event queueing models to optimize
patient throughput and eliminate camera bottlenecks in mobile eye camps.
"""

import math
from typing import Dict, Any, List


def simulate_camp_throughput(num_patients: int = 120,
                             num_cameras: int = 1,
                             shift_hours: float = 8.0) -> Dict[str, Any]:
    """
    Simulates patient throughput, wait times, and camera queue dynamics.
    
    Args:
        num_patients: Estimated total patient cohort attending the camp (e.g. 50 - 300).
        num_cameras: Number of operating non-mydriatic fundus cameras (1 or 2).
        shift_hours: Camp operational shift duration in hours (e.g. 4.0 - 10.0).

    Returns:
        Dictionary with operational KPIs, queue metrics, hourly progression timeline,
        and comparison delta between 1-camera and 2-camera configurations.
    """
    shift_min = shift_hours * 60.0
    arrival_rate = num_patients / shift_min          # lambda (patients / minute)
    capture_time_min = 3.5                           # mean camera capture + positioning time
    service_rate_per_cam = 1.0 / capture_time_min    # mu (patients / minute / camera)

    # Traffic intensity and camera utilization
    c = max(1, int(num_cameras))
    traffic_intensity = arrival_rate / service_rate_per_cam
    rho = traffic_intensity / c
    rho_clamped = min(0.96, max(0.08, float(rho)))

    # Compute M/M/c Queue Waiting Time (Erlang-C Formula)
    if c == 1:
        # Standard M/M/1 queue model
        avg_wait_min = (rho_clamped / (service_rate_per_cam * (1.0 - rho_clamped)))
        p95_wait_min = avg_wait_min * 2.3
    else:
        # Multi-server M/M/2 queue model
        a = traffic_intensity
        # Erlang-C P0 calculation
        denom = 1.0 + a + ((a ** 2) / (2.0 * max(0.02, 1.0 - rho_clamped)))
        p0 = 1.0 / max(0.01, denom)
        prob_queue = ((a ** 2) / (2.0 * max(0.02, 1.0 - rho_clamped))) * p0
        avg_wait_min = prob_queue / max(0.01, (c * service_rate_per_cam - arrival_rate))
        p95_wait_min = avg_wait_min * 2.45

    # Daily maximum theoretical capacity at 90% target utilization
    daily_capacity = int((shift_min / capture_time_min) * c * 0.90)
    camera_utilization_pct = round(rho_clamped * 100.0, 1)

    # Bottleneck stage assessment
    if camera_utilization_pct > 80.0:
        bottleneck = "Fundus Camera Optical Acquisition (Queue Backlog)"
    elif num_patients > 220 and c >= 2:
        bottleneck = "Patient Registration & Pupil Assessment"
    else:
        bottleneck = "Optimal Flow - Zero Stage Bottleneck"

    # Generate Hourly Operational Timeline (showing mid-day rural camp surge)
    hourly_timeline: List[Dict[str, Any]] = []
    num_hours = max(4, min(12, int(round(shift_hours))))
    # Typical rural surge pattern (peaking between hours 2 and 5)
    surge_factors = [0.65, 1.10, 1.35, 1.45, 1.20, 0.95, 0.75, 0.55, 0.40, 0.30, 0.25, 0.20]

    running_screened = 0
    current_queue = 0
    for h in range(1, num_hours + 1):
        factor = surge_factors[h - 1] if (h - 1) < len(surge_factors) else 0.5
        hour_arrivals = int(round((num_patients / num_hours) * factor))
        camera_hourly_capacity = int((60.0 / capture_time_min) * c)
        served = min(hour_arrivals + current_queue, camera_hourly_capacity)
        current_queue = max(0, current_queue + hour_arrivals - served)
        running_screened += served
        hourly_wait = round(avg_wait_min * (0.6 + 0.8 * (current_queue / max(1, camera_hourly_capacity))), 1)

        hourly_timeline.append({
            "hour": h,
            "label": f"Hr {h}:00",
            "arrivals": hour_arrivals,
            "screened": served,
            "cumulativeScreened": min(num_patients, running_screened),
            "queueLength": current_queue,
            "estimatedWaitMin": max(2.0, hourly_wait)
        })

    # Comparative evaluation: 1 Camera vs 2 Cameras
    wait_reduction_pct = 0.0
    if c == 1:
        # Evaluate how much 2 cameras would help
        two_cam = simulate_camp_throughput(num_patients, num_cameras=2, shift_hours=shift_hours)
        wait_reduction_pct = round(((avg_wait_min - two_cam["averageWaitTimeMinutes"]) / max(0.1, avg_wait_min)) * 100.0, 1)

    return {
        "shiftDurationHours": shift_hours,
        "patientsScreened": num_patients,
        "cameraCount": c,
        "cameraUtilizationPercent": camera_utilization_pct,
        "averageWaitTimeMinutes": round(avg_wait_min, 1),
        "p95WaitTimeMinutes": round(p95_wait_min, 1),
        "aiEdgeUtilizationPercent": round(min(5.0, (num_patients * 0.045 / (shift_min * 60.0)) * 100.0 * 100.0), 2),
        "estimatedDailyCapacity": daily_capacity,
        "bottleneckStage": bottleneck,
        "waitReductionPct": wait_reduction_pct,
        "hourlyTimeline": hourly_timeline,
        "staffingRecommendation": {
            "optometrists": c,
            "ashaWorkers": 2 if c == 1 else 3,
            "fundusCameras": c,
            "edgeLaptops": 1,
            "throughputStatus": "Strained" if camera_utilization_pct > 85.0 else "Optimal"
        }
    }


if __name__ == "__main__":
    res1 = simulate_camp_throughput(120, num_cameras=1)
    res2 = simulate_camp_throughput(120, num_cameras=2)
    print("=" * 65)
    print("Rural PHC Screening Camp Simulation: 1 vs 2 Cameras")
    print("=" * 65)
    print(f"1-Camera Camp: Wait = {res1['averageWaitTimeMinutes']} min | Utilization = {res1['cameraUtilizationPercent']}% | Capacity = {res1['estimatedDailyCapacity']}")
    print(f"2-Camera Camp: Wait = {res2['averageWaitTimeMinutes']} min | Utilization = {res2['cameraUtilizationPercent']}% | Capacity = {res2['estimatedDailyCapacity']}")
    print(f"Wait Time Reduction with 2 Cameras: {res1['waitReductionPct']}%")
