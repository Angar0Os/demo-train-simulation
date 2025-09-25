local CONFIGURATION = session.options["[1] Configuration"]

local VIDEO_RECORD = true
local AMBIENT_AUDIO = true
local audio_guide_gain = 1.0

-- OBB triggers
function WaitEnterOBB(obb_node_name)
    print("Wait until visitor enters OBB '" .. obb_node_name .. "'.")
    local has_entered_obb = false

    local function Callback()
        print("Visitor has entered OBB '" .. obb_node_name .. "'.")
        has_entered_obb = true
    end

    api.OnActorEntersNodeOBB(obb_node_name, Callback)

    while not has_entered_obb do
        api.WaitFor(1.0 / 30.0)
    end

    api.RemoveOnActorEntersNodeOBB(obb_node_name)
end
-- End OBB triggers

api.LoadScene('scenario_1_part_4.scn', 'scene')

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
local sgn_reperes_voies_quai_anim = api.PlayNodeAnimation("sgn_reperes_voies_quai", "scenario_1_depart_state_2")

train_ter_hdf_anim = api.PlayNodeAnimation("train_ter_hdf", "far_backward")

-- START
api.FadeIn(1.0)

voice_over = api.PlaySound('sounds/voice_over/s1_voice_07.ogg', 1.0)
api.WaitSource(voice_over)

WaitEnterOBB("wp_list/wp_000/obb_enable_exit_point")

api.GoToWaypoint(1)
api.TeleportToWaypoint(1)

WaitEnterOBB("wp_list/wp_001/obb_enable_exit_point")

api.GoToWaypoint(2)
api.TeleportToWaypoint(2)

WaitEnterOBB("wp_list/wp_002/obb_enable_exit_point")

api.GoToWaypoint(3)
api.TeleportToWaypoint(3)

WaitEnterOBB("wp_list/wp_003/obb_enable_exit_point")

api.GoToWaypoint(4)
api.TeleportToWaypoint(4)

WaitEnterOBB("wp_list/wp_004/obb_enable_exit_point")

api.StopAnimation(train_ter_hdf_anim)
train_ter_hdf_anim = api.PlayNodeAnimation("train_ter_hdf", "train_arrive_forward_30sec")

api.GoToWaypoint(5)
api.StopAnimation(sgn_reperes_voies_quai_anim)
sgn_reperes_voies_quai_anim = api.PlayNodeAnimation("sgn_reperes_voies_quai", "scenario_1_depart_state_3")
api.TeleportToWaypoint(5)

WaitEnterOBB("wp_list/wp_005/obb_enable_exit_point")

api.GoToWaypoint(6)
api.TeleportToWaypoint(6)

api.GoToNode("interaction_point_train_v_2")

api.StopAnimation(train_ter_hdf_anim)
train_ter_hdf_anim = api.PlayNodeAnimation("train_ter_hdf", "open_doors_left")

api.WaitFor(0.5)

sound_feedback = api.PlaySound('sounds/helpers/end_sound.ogg', 1.0)
api.WaitSource(sound_feedback)

-- END
api.EndCapture()
