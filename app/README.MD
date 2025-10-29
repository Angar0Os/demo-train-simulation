# Autonomous Train Simulator Prototype

This is a simple prototype that demonstrates Yolo tracking on Harfang 3D of a railway scene in different weather conditions (fog, night, day).

![labeled_day_image](screenshots/labeled_day_image.png)

## Project Overview

 > This project aims to develop a prototype train driving simulator using the Harfang 3D engine. The simulator will serve as a training environment for an AI focused on the development of autonomous train systems. Through this simulator, the AI will gain experience in navigating rail environments under various conditions, from weather to lighting changes, to prepare it for real-world challenges.

## Technologies Used

- **Programming Language**: Lua/Python
- **3D Engine**: Harfang 3D
- **Simulation**: In the current version, the simulation environment is limited to the visual domain, leveraging realistic rendering and physical features of Harfang's AAA rendering.

### Features
- **Environmental Realism**: Simulation of day and night situations.
- **Lighting and Material Fidelity**: Utilizes Harfang 3D's SSR, SSGI & TAA, showcasing radiosity, reflections, and Physically Based Rendering materials. This ensures that the visual output closely resembles what an RGB camera would capture in a real environment.
- **Train Dynamics**: So far the train motion are REALLY BASIC, using a simple linear interpolation to evaluate the train's position along time.

### Process

 1. Build assets using `build.bat`.
 2. Then use `start.bat` to dump images into image_reims_{weather_mode} (fog, day, night).
 3. Once your `image_reims_{weather_mode}` start `encode_video.bat`, replace images_reims_{night} folder's name by your actual weather mode.
  4. This will create a video named `double_train_reims_{weather_mode}_QHD.mp4`.
  5. Finaly, start `python simulated_image_analyser.py`.
  6. This will create a video in `output_videos/` folder named `{weather_mode}_labeled_final.mp4`.


### Project Parameters

 - In main.lua file you can change the following parameters
    ```lua 
        weather_mode = "night" /* "fog", "day" */
        capture_mode = true 
        /* If you change this to false, it will show the screen else, press F9 to start capturing*/
    ```

 - In train_image_analyser.py
    ```python
        video_path = "double_train_reims_night_QHD.mp4" # Path to video created afted using main.lua
        output_path = "output_videos/night_labeled_final.mp4" # Path to the output video
    ```

 - In encode_video.bat
    ```
        images_reims_night\capture_%%04d.png 
        you can change night by fog or day
    ```
