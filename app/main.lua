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

res_x, res_y = 1920, 1080 -- 1280, 720
win = hg.RenderInit('Train Simulator', res_x, res_y, hg.RF_VSync) -- | hg.RF_MSAA4X)

hg.AddAssetsFolder("assets_compiled")

--
pipeline = hg.CreateForwardPipeline(4096, false)
res = hg.PipelineResources()

max_len = 4967.400 - 40.350-- in meters

-- load main scene
main_scene = hg.Scene()
hg.LoadSceneFromAssets("camera.scn", main_scene, res, hg.GetForwardPipelineInfo())
hg.LoadSceneFromAssets("skybox_day.scn", main_scene, res, hg.GetForwardPipelineInfo())
hg.LoadSceneFromAssets("demo_scene.scn", main_scene, res, hg.GetForwardPipelineInfo())

-- AAA pipeline
pipeline_aaa_config = hg.ForwardPipelineAAAConfig()
pipeline_aaa = hg.CreateForwardPipelineAAAFromAssets("core", pipeline_aaa_config, hg.BR_Equal, hg.BR_Equal)

pipeline_aaa_config.sample_count = 1
pipeline_aaa_config.motion_blur = 0.001
pipeline_aaa_config.exposure = 1.4
pipeline_aaa_config.gamma = 1.6
pipeline_aaa_config.z_thickness = 1.0 / 2.0
pipeline_aaa_config.sharpen = 0.5

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

-- main loop
frame = 0

while not hg.ReadKeyboard():Key(hg.K_Escape) and hg.IsWindowOpen(win) do
	dt = hg.TickClock() -- hg.time_from_sec_f(1.0 / 60.0) -- hg.TickClock()

	local view_id = 0
	local pass_id

	-- trs = main_scene:GetNode('engine_master'):GetTransform()
	-- trs:SetRot(trs:GetRot() + hg.Vec3(0, hg.Deg(15) * hg.time_to_sec_f(dt), 0))
	local variable_speed, dist_to_mile, idx
	variable_speed = 0.0
	
	for idx = 1, 2 do
		dist_to_mile = hg.Dist(cam_pos, miles_pos[idx])
		-- print(idx .. "," .. dist_to_mile)
		dist_to_mile = EaseInOutQuick(clamp(map(dist_to_mile, 1200, 550, 0.0, 1.0), 0.0, 1.0))
		variable_speed = variable_speed + dist_to_mile * max_speed
	end

	variable_speed = variable_speed + min_speed
	-- print("variable_speed = " .. variable_speed)

	cam_pos.x = cam_pos.x + hg.time_to_sec_f(dt) * variable_speed
	main_camera_node:GetTransform():SetPos(cam_pos)
	skybox_pos.x = cam_pos.x
	skybox_node:GetTransform():SetPos(skybox_pos)

	if cam_pos.x > max_len then
		cam_pos.x = cam_pos.x - max_len
	end

	main_scene:Update(dt)

	-- render main scene
	view_id, pass_id = hg.SubmitSceneToPipeline(view_id, main_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)
	-- view_id, pass_id = hg.SubmitSceneToPipeline(view_id, main_scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)

	frame = hg.Frame()
	hg.UpdateWindow(win)
end

hg.RenderShutdown()
hg.DestroyWindow(win)
