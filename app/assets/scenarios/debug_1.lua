local VIDEO_RECORD = true
local AMBIENT_AUDIO = true
local audio_guide_gain = 1.0

api.LoadScene('debug_1.scn', 'scene')
api.LoadScene('envs/environment_day.scn', 'environment')

-- START
api.FadeIn(1.0)

api.GoToWaypoint(1)
api.TeleportToWaypoint(1)

api.GoToWaypoint(2)
api.TeleportToWaypoint(2)

-- END
api.EndCapture()
