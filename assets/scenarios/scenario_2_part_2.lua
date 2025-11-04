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

api.LoadScene('scenario_2_part_2.scn', 'scene')

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
local sgn_reperes_voies_quai_anim = api.PlayNodeAnimation("sgn_reperes_voies_quai", "scenario_2_depart_state_1")

-- START
api.PlayNodeAnimation('incoming_message', "init")

api.FadeIn(1.0)

api.GoToNode("interaction_point_start")

voice_over = api.PlaySound('sounds/voice_over/s2_voice_03.ogg', 1.0)
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

api.GoToWaypoint(5)
api.TeleportToWaypoint(5)

WaitEnterOBB("wp_list/wp_005/obb_enable_exit_point")

api.GoToWaypoint(6)
api.TeleportToWaypoint(6)

WaitEnterOBB("wp_list/wp_006/obb_enable_exit_point")

api.GoToWaypoint(7)
api.WaitFor(0.5)
api.FadeOut(0.5)
api.StopAnimation(sgn_reperes_voies_quai_anim)
sgn_reperes_voies_quai_anim = api.PlayNodeAnimation("sgn_reperes_voies_quai", "scenario_2_depart_state_2")
api.TeleportToWaypoint(7)

api.GoToNode("interaction_point_incoming_message")

api.WaitFor(0.5)
api.PlayNodeAnimation('incoming_message', "show")
api.WaitFor(2.0)

--sms_notification_sound = api.PlaySound('sounds/sms_notification.ogg', 1.0)
--api.StartQCM("Le train pour Sedan change de voie suite à un incident.\nLa nouvelle voie sera affichée prochainement.", 'OK', 'Retour')
--api.WaitQCM()

voice_over = api.PlaySound('sounds/voice_over/s2_voice_04.ogg', 1.0)
api.WaitSource(voice_over)

api.PlayNodeAnimation('incoming_message', "hide")

api.GoToNode("interaction_point_end")

-- END
api.ChangeScenario('scenario_002_part_003')
--api.EndCapture()