ffmpeg -i images_reims_night\capture_%%04d.png -framerate 60 -r 60 -c:v libx264 -preset slow -crf 18 double_train_reims_night.mp4
pause
