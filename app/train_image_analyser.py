from ultralytics import YOLO
from pathlib import Path
import cv2
import random
import os
import numpy as np

video_path = "double_train_reims_fog_QHD.mp4"
output_path = "output_videos/labeled_double_train_reims_fog_QHD.mp4"
os.makedirs(Path(output_path).parent, exist_ok=True)

model = YOLO("yolov8l-worldv2.pt")

# CLASS_COLORS = {
#     "person": (255, 0, 0),
#     "handbag": (255, 0, 255),
#     "suitcase": (0, 255, 255),
#     "bench": (0, 128, 0),
#     "tv": (255, 255, 0),
#     "clock": (128, 0, 128),
#     "traffic light": (0, 165, 255),
#     "car": (0, 255, 0),
#     "train": (147, 20, 255),
# }

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

def hex_to_bgr(hex_color: str):
    hex_color = hex_color.lstrip('#')
    rgb = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
    return rgb[::-1]

def get_class_color(class_name):
    """Renvoie une couleur cohérente par classe."""
    if class_name in CLASS_COLORS:
        return CLASS_COLORS[class_name]
    random.seed(hash(class_name) % 10000)
    return tuple(random.randint(0, 255) for _ in range(3))

cap = cv2.VideoCapture(video_path)

fourcc = cv2.VideoWriter_fourcc(*"mp4v")
fps = cap.get(cv2.CAP_PROP_FPS)
width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

while cap.isOpened():
    success, frame = cap.read()
    if not success:
        break

    results = model.track(frame, persist=True, verbose=False)

    if len(results) > 0 and results[0].boxes is not None:
        boxes = results[0].boxes.xyxy
        classes = results[0].boxes.cls
        confs = results[0].boxes.conf
        ids = results[0].boxes.id  # ID 

        overlay = frame.copy()

        for i, (box, cls, conf) in enumerate(zip(boxes, classes, confs)):
            x1, y1, x2, y2 = map(int, box)
            class_name = model.names[int(cls)].capitalize()
            color = get_class_color(class_name.lower())
            label = f"{class_name} {conf:.2f}"
            if ids is not None:
                label += f" ID:{int(ids[i])}"

            alpha = float(conf) * 2.0 if conf < 0.5 else 1.0

            cv2.rectangle(overlay, (x1, y1), (x2, y2), color, 2)
            (text_w, text_h), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
            cv2.rectangle(overlay, (x1, y1 - text_h - baseline - 4), (x1 + text_w + 4, y1), color, -1)
            cv2.putText(overlay, label, (x1 + 2, y1 - 4),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1, cv2.LINE_AA)

            frame = cv2.addWeighted(overlay, alpha, frame, 1 - alpha, 0)

    cv2.imshow("YOLO Tracking", frame)
    out.write(frame)

    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

cap.release()
out.release()
cv2.destroyAllWindows()
