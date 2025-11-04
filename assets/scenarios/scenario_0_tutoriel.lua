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

api.LoadScene('scenario_0_tutoriel.scn', 'scene')

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

-- START
api.FadeIn(1.0)

api.GoToNode("interaction_point_start_1")

-- "Bienvenue dans ce tutoriel de navigation en réalité virtuelle. Vous allez apprendre à vous déplacer, à suivre les indications de guidage, puis à vous déplacer sans guidage.
-- Pour commencer, dirigez vous vers le cercle bleu le plus proche puis marquez un arrêt."
voice_over = api.PlaySound('sounds/voice_over/tuto_voice_01.ogg', 1.0)
api.WaitSource(voice_over)
api.WaitFor(0.5)
voice_over = api.PlaySound('sounds/voice_over/tuto_voice_02.ogg', 1.0)
api.WaitSource(voice_over)

api.GoToNode("interaction_point_start_2")

-- "Vous allez maintenant vous déplacer vers un téléporteur. Marchez jusqu'au prochain cercle bleu, puis marquez un arrêt."
voice_over = api.PlaySound('sounds/voice_over/tuto_voice_03.ogg', 1.0)
api.WaitSource(voice_over)

api.GoToWaypoint(1)
api.TeleportToWaypoint(1)

-- "Parfait. Maintenant, retournez-vous pour vous reprendre le sens de la marche et rendez-vous au téléporteur suivant."
voice_over = api.PlaySound('sounds/voice_over/tuto_voice_04.ogg', 1.0)
api.WaitSource(voice_over)

api.GoToWaypoint(2)
api.TeleportToWaypoint(2)

-- "Maintenant, vous allez vous orientez par vous même. Retournez-vous et cherchez le passage à gauche de l'escalier."
voice_over = api.PlaySound('sounds/voice_over/tuto_voice_05.ogg', 1.0)
api.WaitSource(voice_over)

WaitEnterOBB("wp_list/wp_002/obb_enable_exit_point")

api.GoToWaypoint(3)
api.TeleportToWaypoint(3)

-- "Bravo, vous maîtrisez complètement la navigation en réalité virtuelle. Retournez-vous une dernière fois et dirigez-vous vers le bout du quai."
voice_over = api.PlaySound('sounds/voice_over/tuto_voice_06.ogg', 1.0)
api.WaitSource(voice_over)

WaitEnterOBB("wp_list/wp_003/obb_enable_exit_point")

api.GoToNode("interaction_point_end")

sound_feedback = api.PlaySound('sounds/helpers/end_sound.ogg', 1.0)
api.WaitSource(sound_feedback)

api.WaitFor(0.5)

-- END
api.EndCapture()
