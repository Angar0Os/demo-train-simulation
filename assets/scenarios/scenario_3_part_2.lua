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

api.LoadScene('scenario_3_part_2.scn', 'scene')

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
api.FadeIn(1.0)

api.GoToNode("interaction_point_start")

voice_over = api.PlaySound('sounds/voice_over/s3_voice_04.ogg', 1.0)
api.WaitSource(voice_over)

api.GoToWaypoint(1)
api.TeleportToWaypoint(1) 

api.GoToWaypoint(2)
api.TeleportToWaypoint(2)

api.GoToNode("interaction_point_end")

voice_over = api.PlaySound('sounds/voice_over/s3_voice_05.ogg', 1.0)
api.WaitSource(voice_over)

-- END
api.ChangeScenario('scenario_003_part_003')
-- api.EndCapture()