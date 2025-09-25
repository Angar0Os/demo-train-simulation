from pydub import AudioSegment

sounds = [AudioSegment.from_ogg(f"sfx_foot_man_{i}.ogg") for i in range(7)]

for i in range(len(sounds)):
    sound1 = sounds[i]
    sound2 = sounds[(i + 1) % len(sounds)]

    min_len = min(len(sound1), len(sound2))
    s1 = sound1[:min_len]
    s2 = sound2[:min_len]

    s1_quiet = s1 - 6
    s2_quiet = s2 - 6

    mixed = s1_quiet.overlay(s2_quiet)

    out_name = f"mixed_sfx_foot_man_{i}.ogg"
    mixed.export(out_name, format="ogg")
    print(f"Saved {out_name}")
