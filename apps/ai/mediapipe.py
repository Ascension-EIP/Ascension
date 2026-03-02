import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import json
import numpy as np
import os

# --- Config ---
# Utilise le chemin absolu pour éviter les surprises selon d'où tu lances pixi
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
VIDEO_PATH  = os.path.join(BASE_DIR, "vid.mp4")
MODEL_PATH  = os.path.join(BASE_DIR, "pose_landmarker.task")
OUTPUT_PATH = os.path.join(BASE_DIR, "biomechanics.json")

LANDMARKS = {
    11: "left_shoulder", 12: "right_shoulder", 13: "left_elbow", 14: "right_elbow",
    15: "left_wrist", 16: "right_wrist", 23: "left_hip", 24: "right_hip",
    25: "left_knee", 26: "right_knee", 27: "left_ankle", 28: "right_ankle"
}

def vec3(a, b): return [b["x"]-a["x"], b["y"]-a["y"], b["z"]-a["z"]]
def magnitude(v): return float(np.linalg.norm(v))
def normalize(v): return [x/magnitude(v) for x in v] if magnitude(v)>0 else v
def angle_between(v1,v2):
    u1,u2 = normalize(v1), normalize(v2)
    return float(np.degrees(np.arccos(np.clip(np.dot(u1,u2),-1,1))))

def process_pose(landmarks_raw):
    lm = {}
    for idx, name in LANDMARKS.items():
        l = landmarks_raw[idx]
        # On baisse le seuil à 0.3 car l'escalade cache souvent des membres
        if l.presence < 0.3: continue
        lm[name] = {"x": round(l.x, 5), "y": round(l.y, 5), "z": round(l.z, 5), "presence": round(l.presence, 3)}
    
    angles = {}
    if all(k in lm for k in ["left_shoulder", "left_elbow", "left_wrist"]):
        v1 = vec3(lm["left_elbow"], lm["left_shoulder"])
        v2 = vec3(lm["left_elbow"], lm["left_wrist"])
        angles["left_elbow"] = round(angle_between(v1, v2), 2)
    
    return {"landmarks": lm, "angles": angles}

def analyze():
    if not os.path.exists(VIDEO_PATH):
        print(f"❌ Fichier vidéo introuvable : {VIDEO_PATH}")
        return

    cap = cv2.VideoCapture(VIDEO_PATH)
    if not cap.isOpened():
        print(f"❌ OpenCV ne peut pas ouvrir la vidéo. Vérifie tes codecs (ffmpeg).")
        return

    fps = cap.get(cv2.CAP_PROP_FPS)
    if fps <= 0: fps = 30 # Fallback si le header est mal lu
    
    n_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    print(f"🎬 Vidéo chargée : {n_frames} frames à {fps} FPS")

    base_options = python.BaseOptions(model_asset_path=MODEL_PATH)
    options = vision.PoseLandmarkerOptions(
        base_options=base_options,
        running_mode=vision.RunningMode.VIDEO
    )

    with vision.PoseLandmarker.create_from_options(options) as landmarker:
        output = {"frames": []}

        for i in range(n_frames):
            ret, frame = cap.read()
            if not ret:
                print(f"⚠️  Lecture interrompue à la frame {i}")
                break
            
            # Conversion pour MediaPipe
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
            
            timestamp_ms = int((i / fps) * 1000)
            result = landmarker.detect_for_video(mp_image, timestamp_ms)
            
            frame_data = {"frame": i, "timestamp_ms": timestamp_ms, "pose_detected": False}
            
            if result.pose_landmarks:
                frame_data["pose_detected"] = True
                frame_data.update(process_pose(result.pose_landmarks[0]))
            
            output["frames"].append(frame_data)
            
            if i % 30 == 0:
                det_status = "OK" if result.pose_landmarks else "NO_POSE"
                print(f"Processing... {i}/{n_frames} ({det_status})")

        cap.release()
        with open(OUTPUT_PATH, "w") as f:
            json.dump(output, f, indent=2)
        print(f"✅ Terminé ! {len(output['frames'])} frames sauvées dans {OUTPUT_PATH}")

if __name__ == "__main__":
    analyze()