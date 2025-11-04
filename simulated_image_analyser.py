from ultralytics import YOLO
from pathlib import Path
import cv2
import random
import os
import numpy as np
import csv
from collections import defaultdict

video_path = "double_train_reims_fog_QHD.mp4"
output_path = "output_videos/fog_labeled_final.mp4"
stats_path = "output_stats/fog_tracking_data.csv"

os.makedirs(Path(output_path).parent, exist_ok=True)
os.makedirs(Path(stats_path).parent, exist_ok=True)

model = YOLO("yolov8l-worldv2.pt")

def hex_to_bgr(hex_color: str):
    hex_color = hex_color.lstrip('#')
    rgb = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    return rgb[::-1]

CLASS_COLORS = {
    "person":           hex_to_bgr('#E6607F'),
    "handbag":          hex_to_bgr('#00A7E6'),
    "suitcase":         hex_to_bgr('#E6DE60'),
    "bench":            hex_to_bgr('#918E6D'),
    "tv":               hex_to_bgr('#665A5D'),
    "clock":            hex_to_bgr('#5A6366'),
    "traffic light":    hex_to_bgr('#7B6D91'),
    "car":              hex_to_bgr('#9560E6'),
    "train":            hex_to_bgr('#60E67D'),
}

def get_class_color(class_name):
    """Renvoie une couleur cohérente par classe."""
    if class_name in CLASS_COLORS:
        return CLASS_COLORS[class_name]
    random.seed(hash(class_name) % 10000)
    return tuple(random.randint(0, 255) for _ in range(3))

class_confidences = defaultdict(list)

def log_detection(class_name, conf):
    """Stocke les valeurs de confidence pour analyse finale."""
    class_confidences[class_name].append(float(conf))

cap = cv2.VideoCapture(video_path)
fourcc = cv2.VideoWriter_fourcc(*"mp4v")
fps = cap.get(cv2.CAP_PROP_FPS)
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

frame_idx = 0

while cap.isOpened():
    success, frame = cap.read()
    if not success or frame is None:
        break

    results = model.track(frame, persist=True, verbose=False)

    if len(results) > 0 and results[0].boxes is not None:
        boxes = results[0].boxes.xyxy
        classes = results[0].boxes.cls
        confs = results[0].boxes.conf
        ids = results[0].boxes.id  # ID tracking

        overlay = frame.copy()

        for i, (box, cls, conf) in enumerate(zip(boxes, classes, confs)):
            class_name = model.names[int(cls)].capitalize()
            color = get_class_color(class_name.lower())
            obj_id = int(ids[i]) if ids is not None else None

            log_detection(class_name, conf)

            x1, y1, x2, y2 = map(int, box)
            label = f"{class_name} {conf:.2f}"
            if obj_id is not None:
                label += f" ID:{obj_id}"

            alpha = float(conf) * 2.0 if conf < 0.5 else 1.0
            cv2.rectangle(overlay, (x1, y1), (x2, y2), color, 2)
            (text_w, text_h), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
            cv2.rectangle(overlay, (x1, y1 - text_h - baseline - 4), (x1 + text_w + 4, y1), color, -1)
            cv2.putText(overlay, label, (x1 + 2, y1 - 4),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1, cv2.LINE_AA)

            frame = cv2.addWeighted(overlay, alpha, frame, 1 - alpha, 0)

    cv2.imshow("YOLO Tracking", frame)
    out.write(frame)
    frame_idx += 1

    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
out.release()
cv2.destroyAllWindows()

print("Analyse terminée. Calcul des statistiques...")

csv_file = open(stats_path, mode="w", newline="", encoding="utf-8")
fieldnames = ["class", "mean_conf", "std_conf", "median_conf", "min_conf", "max_conf", "num_samples"]
csv_writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
csv_writer.writeheader()

all_confs = []

for class_name, confs in class_confidences.items():
    if not confs:
        continue
    arr = np.array(confs)
    csv_writer.writerow({
        "class": class_name,
        "mean_conf": round(np.mean(arr), 4),
        "std_conf": round(np.std(arr), 4),
        "median_conf": round(float(np.median(arr)), 4),
        "min_conf": round(np.min(arr), 4),
        "max_conf": round(np.max(arr), 4),
        "num_samples": len(confs)
    })
    all_confs.extend(confs)

if all_confs:
    arr = np.array(all_confs)
    csv_writer.writerow({
        "class": "OVERALL",
        "mean_conf": round(np.mean(arr), 4),
        "std_conf": round(np.std(arr), 4),
        "median_conf": round(float(np.median(arr)), 4),
        "min_conf": round(np.min(arr), 4),
        "max_conf": round(np.max(arr), 4),
        "num_samples": len(arr)
    })

csv_file.close()
print(f"Statistiques écrites dans : {stats_path}")
print("Vidéo exportée :", output_path)
