# Autonomous Train Simulator Prototype

## Project Overview
This project aims to develop a prototype train driving simulator using the Harfang 3D engine. The simulator will serve as a training environment for an AI focused on the development of autonomous train systems. Through this simulator, the AI will gain experience in navigating rail environments under various conditions, from weather to lighting changes, to prepare it for real-world challenges.

## Implementation

### Technologies Used
- **Programming Language**: Lua
- **3D Engine**: Harfang 3D
- **Simulation**: Custom-built train simulation environment leveraging Harfang 3D's features for realistic rendering and physical dynamics.

### Key Features
- **Environmental Realism**: Simulation of day and night cycles, adjustable to any hour with a heliodon system, as well as various weather conditions (rain, fog, snow).
- **Lighting and Material Fidelity**: Utilizes Harfang 3D's AAA capabilities, including screenspace radiosity, reflections, and PBR (Physically Based Rendering) materials. This ensures that the visual output closely resembles what an RGB camera would capture in a real environment.
- **Train Dynamics**: Basic physics modeling, including speed and braking, will allow the AI to understand and interact with train control commands. While designed to replicate realistic movement, the simulator does not support crash or derailment scenarios.

### Directory Structure
- `assets/` - Contains all 3D assets, such as rails, scenery, skyboxes, train stations, and vegetation.
- `scripts/` - Lua scripts for handling the simulation logic, environment settings, and AI interfaces.
- `output/` - Stores logs and any output data generated during simulation runs.

## Output Specifications
The simulator generates visuals tailored for RGB camera perception, with the following specifications:
- **Resolution**: Configurable based on AI requirements (e.g., 720p, 1080p).
- **Frame Rate**: Variable, with options to sync with real-time processing or higher rates for accelerated AI training.
- **Environmental Data**: Logs of conditions during each run (e.g., time, weather, position) for analysis and benchmarking.
- **Camera View Distortions**: Potential support for sensor deformations, such as fisheye, barrel distortion, or other artifacts that could mimic real-world RGB camera characteristics in embedded systems.

## Pending Clarifications
To ensure that the simulator meets the requirements for AI training, we need clarification on the following:

1. **AI Model Specifications**:
   - Will the AI operate using reinforcement learning, and if so, are there specific reward structures or target outcomes?
   
2. **Sensors and Data Inputs**:
   - Beyond RGB camera data, are additional simulated train sensors needed? For example, speed indicators, occupancy sensors, or data on track curvature/elevation.
   - Are there specific camera distortions (e.g., fisheye, barrel distortion) required to better simulate the embedded RGB camera experience?

3. **Performance Expectations**:
   - Are there specific frame rates or latency requirements, especially for real-time vs. accelerated training scenarios?

4. **Environmental Scope**:
   - Should the simulator include specific landscape features (e.g., tunnels, bridges) or unique scenarios that the AI must navigate?

5. **Data Logging and Output**:
   - What types of logs or analytics are needed for the AI’s learning and evaluation processes?
