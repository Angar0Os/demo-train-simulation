hg = require("harfang")

hg.InputInit()
hg.WindowSystemInit()

res_x, res_y = 1280, 720
win = hg.RenderInit('AAA Scene', res_x, res_y, hg.RF_VSync | hg.RF_MSAA4X)

hg.AddAssetsFolder("assets_compiled")

--
pipeline = hg.CreateForwardPipeline()
res = hg.PipelineResources()


-- load scene
scene = hg.Scene()
hg.LoadSceneFromAssets("Demo_scene.scn", scene, res, hg.GetForwardPipelineInfo())

-- AAA pipeline
pipeline_aaa_config = hg.ForwardPipelineAAAConfig()
pipeline_aaa = hg.CreateForwardPipelineAAAFromAssets("core", pipeline_aaa_config, hg.BR_Half, hg.BR_Half)
pipeline_aaa_config.sample_count = 1
pipeline_aaa_config.motion_blur = 0.001
pipeline_aaa_config.exposure = 1.2
pipeline_aaa_config.gamma = 1.8
pipeline_aaa_config.z_thickness  = 0.25
pipeline_aaa_config.sharpen = 0.25

local camera_node = scene:GetNode("Camera")
local cam_pos = camera_node:GetTransform():GetPos()
local speed = 10.0

-- main loop
frame = 0

while not hg.ReadKeyboard():Key(hg.K_Escape) and hg.IsWindowOpen(win) do
	dt = hg.TickClock()

	-- trs = scene:GetNode('engine_master'):GetTransform()
	-- trs:SetRot(trs:GetRot() + hg.Vec3(0, hg.Deg(15) * hg.time_to_sec_f(dt), 0))
	cam_pos.x = cam_pos.x + hg.time_to_sec_f(dt) * speed
	camera_node:GetTransform():SetPos(cam_pos)

	if cam_pos.x > 200.0 then
		cam_pos.x = cam_pos.x - 100.0
	end

	scene:Update(dt)
	-- hg.SubmitSceneToPipeline(0, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res)
	hg.SubmitSceneToPipeline(0, scene, hg.IntRect(0, 0, res_x, res_y), true, pipeline, res, pipeline_aaa, pipeline_aaa_config, frame)

	frame = hg.Frame()
	hg.UpdateWindow(win)
end

hg.RenderShutdown()
hg.DestroyWindow(win)
