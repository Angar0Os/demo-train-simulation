hg = require("harfang")

-- Maps a value from one range to another.
function map(value, min1, max1, min2, max2)
    return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
end

-- Clamps a value between a minimum and maximum value.
function clamp(value, min1, max1)
    return math.min(math.max(value, min1), max1)
end

-- Ease-in-out function for smoother transitions.
function EaseInOutQuick(x)
	x = clamp(x, 0.0, 1.0)
	return	(x * x * (3 - 2 * x))
end

hg.InputInit()
hg.WindowSystemInit()

res_x, res_y, tex_size_x, tex_size_y = 2560, 1440, 2560, 1440
-- res_x, res_y = 1280, 720
win = hg.RenderInit('Train Simulator', res_x, res_y, hg.RF_VSync) -- | hg.RF_MSAA4X)

hg.AddAssetsFolder("assets_compiled")

--
pipeline = hg.CreateForwardPipeline(4096, false)
res = hg.PipelineResources()

max_len = 4967.400 - 40.350-- in meters

-- load main scene
main_scene = hg.Scene()
local weather_mode 
--weather_mode = "day"
-- weather_mode = "fog"
weather_mode = "day"
capture_mode = true


if weather_mode == "night" then
	hg.LoadSceneFromAssets("camera_night.scn", main_scene, res, hg.GetForwardPipelineInfo())
	hg.LoadSceneFromAssets("demo_scene.scn", main_scene, res, hg.GetForwardPipelineInfo())
	hg.LoadSceneFromAssets("skybox_night.scn", main_scene, res, hg.GetForwardPipelineInfo())
elseif weather_mode == "day" then
	hg.LoadSceneFromAssets("camera_day.scn", main_scene, res, hg.GetForwardPipelineInfo())
	hg.LoadSceneFromAssets("demo_scene.scn", main_scene, res, hg.GetForwardPipelineInfo())
	hg.LoadSceneFromAssets("skybox_day.scn", main_scene, res, hg.GetForwardPipelineInfo())
elseif weather_mode == "fog" then
	hg.LoadSceneFromAssets("camera_day.scn", main_scene, res, hg.GetForwardPipelineInfo())
	hg.LoadSceneFromAssets("demo_scene.scn", main_scene, res, hg.GetForwardPipelineInfo())
	hg.LoadSceneFromAssets("skybox_fog.scn", main_scene, res, hg.GetForwardPipelineInfo())
end

-- hg.LoadSceneFromAssets("demo_scene.scn", main_scene, res, hg.GetForwardPipelineInfo())

-- AAA pipeline
pipeline_aaa_config = hg.ForwardPipelineAAAConfig()
pipeline_aaa = hg.CreateForwardPipelineAAAFromAssets("core", pipeline_aaa_config, hg.BR_Equal, hg.BR_Equal)

pipeline_aaa_config.sample_count = 1
pipeline_aaa_config.motion_blur = 0.1
pipeline_aaa_config.exposure = 1.70
pipeline_aaa_config.gamma = 1.620
pipeline_aaa_config.z_thickness = 1.0 / 2.0
pipeline_aaa_config.sharpen = 0.75

-- Set camera
local main_camera_node = main_scene:GetNode("RenderCamera")
local cam_pos = main_camera_node:GetTransform():GetPos()
cam_pos.z = cam_pos.z + 1.8
local min_speed = 5.0
local max_speed = 50.0

main_scene:SetCurrentCamera(main_camera_node)

local skybox_node = main_scene:GetNode("skydome")
local skybox_pos = skybox_node:GetTransform():GetPos()

local miles_pos = {main_scene:GetNode("mile_0"):GetTransform():GetPos(), main_scene:GetNode("mile_1"):GetTransform():GetPos()}
local moving_train = main_scene:GetNode("train_track_W")


frame_buffer = hg.CreateFrameBuffer(tex_size_x, tex_size_y, hg.TF_RGBA8, hg.TF_D24, 4, 'framebuffer')
tex_color = hg.GetColorTexture(frame_buffer)

tex_color_ref = res:AddTexture("tex_rb", tex_color)
tex_readback = hg.CreateTexture(tex_size_x, tex_size_y, "readback", hg.TF_ReadBack | hg.TF_BlitDestination, hg.TF_RGBA8)
picture = hg.Picture(tex_size_x, tex_size_y, hg.PF_RGBA32)

state = "none"

-- main loop
local frame = 0
local dist_to_mile = 0.0
local speed = 0.01
local speed_factor = 0.0
local app_state = "running"
local sim_running = false
local keyboard = hg.Keyboard()
local image_counter = 0001

moving_train_pos = moving_train:GetTransform():GetPos()

while not hg.ReadKeyboard():Key(hg.K_Escape) and hg.IsWindowOpen(win) and app_state == "running" do
    keyboard:Update()
   

	if keyboard:Released(hg.K_F9) and speed_factor < 1.0 then
		speed_factor = 1.0
        sim_running = true
		print(app_state)
	end

	dt = hg.time_from_sec_f(1.0 / 60.0)
	-- dt = hg.TickClock()

	local view_id = 0
	local pass_id

	local cam_pos = hg.Lerp(miles_pos[1], miles_pos[2], EaseInOutQuick(clamp(dist_to_mile, 0.0, 1.0)))

	main_camera_node:GetTransform():SetPos(cam_pos + hg.Vec3(0.0, 1.5, 0.0))

    moving_train_pos = moving_train_pos - hg.Vec3(0.1, 0.0, 0.0)
    moving_train:GetTransform():SetPos(moving_train_pos)
    
	skybox_pos.x = cam_pos.x
	skybox_node:GetTransform():SetPos(skybox_pos)

	if dist_to_mile >= 1.0 then
		-- cam_pos.x = cam_pos.x - max_len
		app_state = "quit"
	end

	dist_to_mile = dist_to_mile + hg.time_to_sec_f(dt) * speed * speed_factor

    main_scene:Update(dt)

	-- render main scene
	--view_id, pass_id = hg.SubmitSceneToPipeline(view_id, main_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

    if capture_mode then
	    view_id, pass_id = hg.SubmitSceneToPipeline(view_id, main_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame, frame_buffer.handle)
        if(state == "none" and sim_running == true) then
            state = "capture"
            frame_count_capture, view_id = hg.CaptureTexture(view_id, res, tex_color_ref, tex_readback, picture)

        elseif (state == "capture" and frame_count_capture <= frame) then
            png_filename = string.format("images_reims/capture_%04d.png", image_counter)
            hg.SavePNG(picture, png_filename)
            image_counter = image_counter + 1
	    	state = "none"
	    end
    else
        view_id, pass_id = hg.SubmitSceneToPipeline(view_id, main_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
    end

	frame = hg.Frame()
	hg.UpdateWindow(win)
end

hg.RenderShutdown()
hg.DestroyWindow(win)
