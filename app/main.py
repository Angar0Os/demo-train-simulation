import harfang as hg
import math

# Maps a value from one range to another.
def map_value(value, min1, max1, min2, max2):
    return min2 + (value - min1) * (max2 - min2) / (max1 - min1)

# Clamps a value between a minimum and maximum value.
def clamp(value, min1, max1):
    return min(max(value, min1), max1)

# Ease-in-out function for smoother transitions.
def EaseInOutQuick(x):
    x = clamp(x, 0.0, 1.0)
    return x * x * (3 - 2 * x)

hg.InputInit()
hg.WindowSystemInit()

res_x, res_y = 1920, 1080
# res_x, res_y = 1280, 720
win = hg.RenderInit('Train Simulator', res_x, res_y, hg.RF_VSync)  # | hg.RF_MSAA4X

hg.AddAssetsFolder("assets_compiled_py")

# Forward pipeline setup
pipeline = hg.CreateForwardPipeline(4096, False)
res = hg.PipelineResources()

max_len = 4967.400 - 40.350  # in meters

# Load main scene
main_scene = hg.Scene()

weather_mode = "day"
# weather_mode = "fog"
# weather_mode = "night"

if weather_mode == "night":
    hg.LoadSceneFromAssets("camera_night.scn", main_scene, res, hg.GetForwardPipelineInfo())
    hg.LoadSceneFromAssets("demo_scene.scn", main_scene, res, hg.GetForwardPipelineInfo())
    hg.LoadSceneFromAssets("skybox_night.scn", main_scene, res, hg.GetForwardPipelineInfo())
elif weather_mode == "day":
    hg.LoadSceneFromAssets("camera_day.scn", main_scene, res, hg.GetForwardPipelineInfo())
    hg.LoadSceneFromAssets("demo_scene.scn", main_scene, res, hg.GetForwardPipelineInfo())
    hg.LoadSceneFromAssets("skybox_day.scn", main_scene, res, hg.GetForwardPipelineInfo())
elif weather_mode == "fog":
    hg.LoadSceneFromAssets("camera_day.scn", main_scene, res, hg.GetForwardPipelineInfo())
    hg.LoadSceneFromAssets("demo_scene.scn", main_scene, res, hg.GetForwardPipelineInfo())
    hg.LoadSceneFromAssets("skybox_fog.scn", main_scene, res, hg.GetForwardPipelineInfo())

# AAA pipeline
# pipeline_aaa_config = hg.ForwardPipelineAAAConfig()
# pipeline_aaa = hg.CreateForwardPipelineAAAFromAssets("core", pipeline_aaa_config, hg.BR_Equal, hg.BR_Equal)

# pipeline_aaa_config.sample_count = 1
# pipeline_aaa_config.motion_blur = 0.001
# pipeline_aaa_config.exposure = 1.4
# pipeline_aaa_config.gamma = 1.6
# pipeline_aaa_config.z_thickness = 1.0 / 2.0
# pipeline_aaa_config.sharpen = 0.5

# Set camera
main_camera_node = main_scene.GetNode("RenderCamera")
cam_pos = main_camera_node.GetTransform().GetPos()
cam_pos.z = cam_pos.z + 1.8
min_speed = 5.0
max_speed = 50.0

main_scene.SetCurrentCamera(main_camera_node)

skybox_node = main_scene.GetNode("skydome")
skybox_pos = skybox_node.GetTransform().GetPos()

miles_pos = [
    main_scene.GetNode("mile_0").GetTransform().GetPos(),
    main_scene.GetNode("mile_1").GetTransform().GetPos()
]

# Main loop
frame = 0
speed_factor = 0.0
state = "running"
keyboard = hg.Keyboard('raw')

while not hg.ReadKeyboard().Key(hg.K_Escape) and hg.IsWindowOpen(win) and state == "running":
    keyboard.Update()

    if keyboard.Released(hg.K_F9) and speed_factor < 1.0:
        speed_factor = 1.0
        print(state)

    dt = hg.time_from_sec_f(1.0 / 60.0)
    # dt = hg.TickClock()

    view_id = 0

    # Example rotating node (commented out like in Lua)
    # trs = main_scene.GetNode('engine_master').GetTransform()
    # trs.SetRot(trs.GetRot() + hg.Vec3(0, hg.Deg(15) * hg.time_to_sec_f(dt), 0))

    variable_speed = 0.0

    # Lua indexes from 1..2; in Python we iterate 0..1
    for idx in range(2):
        dist_to_mile = hg.Dist(cam_pos, miles_pos[idx])
        # Map and ease the distance factor
        dist_to_mile = EaseInOutQuick(clamp(map_value(dist_to_mile, 1200, 550, 0.0, 1.0), 0.0, 1.0))
        variable_speed += dist_to_mile * max_speed

    variable_speed += min_speed
    # print(f"variable_speed = {variable_speed}")

    cam_pos.x = cam_pos.x + hg.time_to_sec_f(dt) * variable_speed * speed_factor
    main_camera_node.GetTransform().SetPos(cam_pos)

    skybox_pos.x = cam_pos.x
    skybox_node.GetTransform().SetPos(skybox_pos)

    if cam_pos.x > max_len:
        # cam_pos.x = cam_pos.x - max_len
        state = "quit"

    main_scene.Update(dt)

    # Render main scene
    # view_id, pass_id = hg.SubmitSceneToPipeline(view_id, main_scene, hg.IntRect(0, 0, res_x, res_y), True, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
    view_id, pass_id = hg.SubmitSceneToPipeline(view_id, main_scene, hg.IntRect(0, 0, res_x, res_y), True, pipeline, res)
    # Alternative without AAA pipeline:
    # view_id, pass_id = hg.SubmitSceneToPipeline(view_id, main_scene, hg.IntRect(0, 0, res_x, res_y), True, pipeline, res)

    frame = hg.Frame()
    hg.UpdateWindow(win)

hg.RenderShutdown()
hg.DestroyWindow(win)