# @date 2026-09-05
# @file constants.py
# @brief SAM-3D keypoint definitions and angle definitions.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""SAM-3D Body landmark indices and mappings."""


class KP:
    """MHR-70 keypoint indices (main body)."""

    NOSE = 0
    L_EYE = 1
    R_EYE = 2
    L_EAR = 3
    R_EAR = 4
    L_SHOULDER = 5
    R_SHOULDER = 6
    L_ELBOW = 7
    R_ELBOW = 8
    L_HIP = 9
    R_HIP = 10
    L_KNEE = 11
    R_KNEE = 12
    L_ANKLE = 13
    R_ANKLE = 14
    R_WRIST = 41
    L_WRIST = 62

    NAMES = {
        0: "nose",
        5: "left_shoulder",
        6: "right_shoulder",
        7: "left_elbow",
        8: "right_elbow",
        9: "left_hip",
        10: "right_hip",
        11: "left_knee",
        12: "right_knee",
        13: "left_ankle",
        14: "right_ankle",
        41: "right_wrist",
        62: "left_wrist",
    }


BODY_CONNECTIONS = [
    (KP.NOSE, KP.L_SHOULDER),
    (KP.NOSE, KP.R_SHOULDER),
    (KP.L_SHOULDER, KP.R_SHOULDER),
    (KP.L_SHOULDER, KP.L_ELBOW),
    (KP.L_ELBOW, KP.L_WRIST),
    (KP.R_SHOULDER, KP.R_ELBOW),
    (KP.R_ELBOW, KP.R_WRIST),
    (KP.L_SHOULDER, KP.L_HIP),
    (KP.R_SHOULDER, KP.R_HIP),
    (KP.L_HIP, KP.R_HIP),
    (KP.L_HIP, KP.L_KNEE),
    (KP.L_KNEE, KP.L_ANKLE),
    (KP.R_HIP, KP.R_KNEE),
    (KP.R_KNEE, KP.R_ANKLE),
]

ANGLE_DEFS = [
    ("left_elbow", KP.L_SHOULDER, KP.L_ELBOW, KP.L_WRIST),
    ("right_elbow", KP.R_SHOULDER, KP.R_ELBOW, KP.R_WRIST),
    ("left_shoulder", KP.L_ELBOW, KP.L_SHOULDER, KP.L_HIP),
    ("right_shoulder", KP.R_ELBOW, KP.R_SHOULDER, KP.R_HIP),
    ("left_knee", KP.L_HIP, KP.L_KNEE, KP.L_ANKLE),
    ("right_knee", KP.R_HIP, KP.R_KNEE, KP.R_ANKLE),
    ("left_hip", KP.L_SHOULDER, KP.L_HIP, KP.L_KNEE),
    ("right_hip", KP.R_SHOULDER, KP.R_HIP, KP.R_KNEE),
]

ANGLE_JOINT_MAP = {name: joint for name, _, joint, _ in ANGLE_DEFS}
