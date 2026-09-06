# @date 2026-09-07
# @file constants.py
# @brief MediaPipe landmark constants and skeleton mappings.
# @project Ascension
# @author Nicolas TORO <nicolas.toro@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
"""MediaPipe landmark definitions and mappings."""


class LM:
    """MediaPipe landmark indices."""

    L_SHOULDER = 11
    R_SHOULDER = 12
    L_ELBOW = 13
    R_ELBOW = 14
    L_WRIST = 15
    R_WRIST = 16
    L_HIP = 23
    R_HIP = 24
    L_KNEE = 25
    R_KNEE = 26
    L_ANKLE = 27
    R_ANKLE = 28

    NAMES = {
        11: "left_shoulder",
        12: "right_shoulder",
        13: "left_elbow",
        14: "right_elbow",
        15: "left_wrist",
        16: "right_wrist",
        23: "left_hip",
        24: "right_hip",
        25: "left_knee",
        26: "right_knee",
        27: "left_ankle",
        28: "right_ankle",
    }


BODY_CONNECTIONS = [
    (LM.L_SHOULDER, LM.R_SHOULDER),
    (LM.L_SHOULDER, LM.L_ELBOW),
    (LM.L_ELBOW, LM.L_WRIST),
    (LM.R_SHOULDER, LM.R_ELBOW),
    (LM.R_ELBOW, LM.R_WRIST),
    (LM.L_SHOULDER, LM.L_HIP),
    (LM.R_SHOULDER, LM.R_HIP),
    (LM.L_HIP, LM.R_HIP),
    (LM.L_HIP, LM.L_KNEE),
    (LM.L_KNEE, LM.L_ANKLE),
    (LM.R_HIP, LM.R_KNEE),
    (LM.R_KNEE, LM.R_ANKLE),
]

LM_HUMAN_NAMES = {
    "11": "épaule_gauche",
    "12": "épaule_droite",
    "13": "coude_gauche",
    "14": "coude_droit",
    "15": "poignet_gauche",
    "16": "poignet_droit",
    "23": "hanche_gauche",
    "24": "hanche_droite",
    "25": "genou_gauche",
    "26": "genou_droit",
    "27": "cheville_gauche",
    "28": "cheville_droite",
}

ANGLE_HUMAN_NAMES = {
    "11": "épaule_gauche",
    "12": "épaule_droite",
    "13": "coude_gauche",
    "14": "coude_droit",
    "23": "hanche_gauche",
    "24": "hanche_droite",
    "25": "genou_gauche",
    "26": "genou_droit",
}
