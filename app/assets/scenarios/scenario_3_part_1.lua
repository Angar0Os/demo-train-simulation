local CONFIGURATION = session.options["[1] Configuration"]

local VIDEO_RECORD = true
local AMBIENT_AUDIO = true
local audio_guide_gain = 1.0

----------------------
-- OBB triggers
----------------------
function WaitEnterOBB(obb_node_name)
   local has_entered_obb = false

    local function Callback()
        has_entered_obb = true
    end

    api.OnActorEntersNodeOBB(obb_node_name, Callback)

    while not has_entered_obb do
        api.WaitFor(1.0 / 30.0)
    end

    api.RemoveOnActorEntersNodeOBB(obb_node_name)
end
----------------------
-- End OBB triggers
----------------------

----------------------
-- Follower logic
----------------------
Follower = {}
Follower.__index = Follower

-- Constructor
-- 'f' stands for 'follower' i.e. the npc
-- 'a' stands for 'actor' i.e. the participant
function Follower.new(f_instance_path, f_start_idx, a_start_idx, hide_follower_instance)
	
	-- Init variables for a new follower
	self = setmetatable({}, Follower)
	self.f_instance = f_instance_path:match("[^/]+$")
	self.f_start_idx = f_start_idx
	self.f_current_idx = f_start_idx
	self.f_distance_from_a = a_start_idx - f_start_idx
	self.f_anim_source = nil
	self.a_current_idx = a_start_idx
	self.obb_list = {}

	f_root_path = f_instance_path:match("(.+)/[^/]+$")
	for i = 0, 9 do
		table.insert(self.obb_list, f_root_path .. "/obb_" .. i)
	end

	-- Hide follower instance at init if requested
	if hide_follower_instance then
		self:Hide()
	end

	return self
end

-- Public methods
function Follower:ShowAtStartPosition()
	-- Play the animation "-1" to place the follower at his starting point
	self:_PlayAnimation("move_ahead_step_-1")
end

function Follower:StartTracking()
	-- Register all listeners at start
	for i = 1, #self.obb_list do
		self:_RegisterListener(i - 1)
	end
end

function Follower:StopTracking()
	-- Remove all listeners
	for i = 1, #self.obb_list do
		api.RemoveOnActorEntersNodeOBB(self.obb_list[i])
	end
end

function Follower:Hide()
	-- Disable visibility by playing a "disable" animation
	self:_PlayAnimation("disable")
end

-- Private methods
function Follower:_PlayAnimation(anim_name)
	-- Play an the targeted animation
	if self.f_anim_source then
		api.StopAnimation(self.f_anim_source)
	end
	self.f_anim_source = api.PlayNodeAnimation(self.f_instance, anim_name)
end

function Follower:_RegisterListener(idx)
	-- Register the listener based on the index
	obb_path = self.obb_list[idx + 1]
	api.OnActorEntersNodeOBB(obb_path, function()
		self:_MoveFollower(idx)
	end)
end

function Follower:_MoveFollower(obb_idx)
	-- Determine the direction
	direction = 0
	if obb_idx > self.a_current_idx then
		direction = 1
	elseif obb_idx < self.a_current_idx then
		direction = -1
	end

	f_next_idx = self.f_current_idx + direction

	-- Forward movement
	if direction == 1 then
		-- Check if initial minimum distance between a and f is respected
		if f_next_idx <= obb_idx - self.f_distance_from_a then
			anim_name = "move_ahead_step_" .. (self.f_current_idx - self.f_start_idx)
			self:_PlayAnimation(anim_name)
			self.f_current_idx = f_next_idx
		end

	-- Backward movement
	elseif direction == -1 then
		-- Check if initial minimum distance between a and f is respected
		if f_next_idx >= obb_idx + self.f_distance_from_a then
			anim_name = "move_back_step_" .. (self.f_current_idx - self.f_start_idx)
			self:_PlayAnimation(anim_name)
			self.f_current_idx = f_next_idx
		end
	end

	-- Re-register the listener for the triggered OBB
	self:_RegisterListener(self.a_current_idx)

	-- Save actor's new position
	self.a_current_idx = obb_idx
end
----------------------
-- End Follower logic
----------------------

api.LoadScene('scenario_3_part_1.scn', 'scene')

if CONFIGURATION == "Etat actuel" then
    api.LoadScene('stairs_simple.scn', 'stairs')
    api.LoadScene('signaletique/pistes_de_solutions/piste_solution_0.scn', 'signaletique')
elseif CONFIGURATION == "Piste 1 - Suspendue" then
    api.LoadScene('stairs_simple.scn', 'stairs')
    api.LoadScene('signaletique/pistes_de_solutions/piste_solution_1.scn', 'signaletique')
elseif CONFIGURATION == "Piste 2 - Coloree" then
    api.LoadScene('stairs_simple.scn', 'stairs')
    api.LoadScene('signaletique/pistes_de_solutions/piste_solution_2.scn', 'signaletique')
elseif CONFIGURATION == "Piste 3 - Ascenseur" then
    api.LoadScene('stairs_doubles.scn', 'stairs')
    api.LoadScene('signaletique/pistes_de_solutions/piste_solution_3.scn', 'signaletique')
end

api.LoadScene('envs/environment_day.scn', 'environment')
api.LoadScene('envs/sfx_ambient_outdoor.scn', 'sfx_ambient_outdoor')
local sgn_reperes_voies_quai_anim = api.PlayNodeAnimation("sgn_reperes_voies_quai", "scenario_3_depart_state_1")

-- START
follower_0 = Follower.new("wp_list/wp_000/follower/follower_0", 2, 3, true)
follower_1 = Follower.new("wp_list/wp_001/follower/follower_1", 0, 1, true)
follower_2 = Follower.new("wp_list/wp_002/follower/follower_2", 0, 1, true)
follower_3 = Follower.new("wp_list/wp_003/follower/follower_3", 0, 1, true)
follower_4 = Follower.new("wp_list/wp_004/follower/follower_4", 0, 1, true)
follower_5 = Follower.new("wp_list/wp_005/follower/follower_5", 0, 1, true)
follower_6 = Follower.new("wp_list/wp_006/follower/follower_6", 0, 1, true)
follower_7 = Follower.new("wp_list/wp_007/follower/follower_7", 0, 1, true)

api.PlayNodeAnimation("wallet", "disable")

follower_0:ShowAtStartPosition()

api.FadeIn(1.0)

api.GoToNode("interaction_point_start")

follower_0:StartTracking()

voice_over = api.PlaySound('sounds/voice_over/s3_voice_01.ogg', 1.0)
api.WaitSource(voice_over)

WaitEnterOBB("wp_list/wp_000/obb_enable_exit_point")

api.GoToWaypoint(1)
api.FadeOut(0.5)
follower_0:StopTracking()
follower_0:Hide()
follower_1:ShowAtStartPosition()
api.TeleportToWaypoint(1, true) 
follower_1:StartTracking()

WaitEnterOBB("wp_list/wp_001/obb_enable_exit_point")

api.GoToWaypoint(2)
api.FadeOut(0.5)
follower_1:StopTracking()
follower_1:Hide()
follower_2:ShowAtStartPosition()
api.TeleportToWaypoint(2, true)
follower_2:StartTracking()

WaitEnterOBB("wp_list/wp_002/obb_enable_exit_point")

api.GoToWaypoint(3)
api.FadeOut(0.5)
follower_2:StopTracking()
follower_2:Hide()
follower_3:ShowAtStartPosition()
api.TeleportToWaypoint(3, true)
follower_3:StartTracking()

WaitEnterOBB("wp_list/wp_003/obb_enable_exit_point")

api.GoToWaypoint(4)
api.FadeOut(0.5)
follower_3:StopTracking()
follower_3:Hide()
follower_4:ShowAtStartPosition()
api.TeleportToWaypoint(4, true)
follower_4:StartTracking()

WaitEnterOBB("wp_list/wp_004/obb_enable_exit_point")

api.GoToWaypoint(5)
api.FadeOut(0.5)
follower_4:StopTracking()
follower_4:Hide()
follower_5:ShowAtStartPosition()
api.TeleportToWaypoint(5, true)
follower_5:StartTracking()

WaitEnterOBB("wp_list/wp_005/obb_enable_exit_point")

api.GoToWaypoint(6)
api.FadeOut(0.5)
follower_5:StopTracking()
follower_5:Hide()
follower_6:ShowAtStartPosition()
api.TeleportToWaypoint(6, true)
follower_6:StartTracking()

WaitEnterOBB("wp_list/wp_006/obb_enable_exit_point")

api.GoToWaypoint(7)
api.FadeOut(0.5)
follower_6:StopTracking()
follower_6:Hide()
follower_7:ShowAtStartPosition()
api.TeleportToWaypoint(7, true)
follower_7:StartTracking()

api.GoToNode("interaction_point_uturn")

follower_7:StopTracking()

voice_over = api.PlaySound('sounds/voice_over/s3_voice_02.ogg', 1.0)
api.WaitSource(voice_over)

api.GoToWaypoint(8)
api.TeleportToWaypoint(8)

api.PlayNodeAnimation("wallet", "enable")

api.GoToWaypoint(9)
api.TeleportToWaypoint(9)

api.GoToNode("interaction_point_wallet")

pick_up_wallet = api.PlayNodeAnimation("wallet", "pick_up")
--WaitAnimation(pick_up_wallet)
api.WaitFor(2.0)

api.GoToNode("interaction_point_end")

voice_over = api.PlaySound('sounds/voice_over/s3_voice_03.ogg', 1.0)
api.WaitSource(voice_over)

-- END
api.ChangeScenario('scenario_003_part_002')
-- api.EndCapture()