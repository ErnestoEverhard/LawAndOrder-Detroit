---
name: freesound-audio
description: Add recorded sound to the Godot game from Freesound - location backgrounds, effects, tension loops. Use whenever a scene needs a sound, a sound is too loud or too quiet, a location needs its own ambience, or the user mentions audio, ambience, sound effects or Freesound.
---

# Sound from Freesound

Files are `godot/assets/audio/<name>.ogg`, committed to git. Every file needs a row in
`godot/assets/audio/SOURCES.md` (file, title, author, URL, licence).

## Getting files
- Only **Creative Commons 0** sounds, confirmed on the sound's own page, so no credit is owed.
- Freesound needs the owner's sign-in in Brave, and Brave must allow multiple downloads for
  freesound.org. If either is missing, stop and ask the owner.
- Hand the downloading to a cheaper model (Agent, `model: haiku`). Give it a table of
  `save as | search words | what is wanted`, and these rules: own browser tab; one download at a time;
  check `ls -t ~/Downloads | head -3` after each; convert from the exact downloaded filename (a helper
  once converted the wrong file by taking "the newest").
- Search URL with the CC0 filter:
  `https://freesound.org/search/?q=WORDS&f=license%3A%22Creative+Commons+0%22+duration%3A%5B2+TO+90%5D&s=Rating+descending`
- Convert: `ffmpeg -y -i "<download>" -t 60 -ac 2 -ar 44100 -c:a libvorbis -q:a 4 <name>.ogg`
  (one-shot effects: `-t 8`). Then `godot --headless --path godot --import`.
- A helper tends to stop part-way through a long list. Compare its report with the table and send it
  back for the rest.

## How the game plays them (`godot/game.gd`)
- **Background:** each set sets `ambience = "<name>"` in `build()`; `_ambience()` loops that file and
  falls back to `room.ogg`. Volume per file is in `AMB_DB`.
- **Tension loop:** `_tension(true, "heartbeat")` runs under timed choices and action sequences;
  chase tracks listed in `CHASE_TRACKS` use `footsteps_run`.
- **Effects:** `CUES` maps words in narration to a sound and volume ("knocks" → `door_knock`). To give a
  line a sound, add a word from that line to `CUES`, or call `_sound("name", db)`.
- Missing files are skipped silently, and nothing plays in `--auto` runs.

## Set volumes from measurement
Downloaded files differ by 40 dB or more, so never guess a volume. Measure:

    for f in godot/assets/audio/*.ogg; do echo "$f $(ffmpeg -i $f -af volumedetect -f null - 2>&1 | grep -o 'mean_volume: [-0-9.]* dB\|max_volume: [-0-9.]* dB' | tr '\n' ' ')"; done

Then set playback gain = target minus measured mean. Targets that were used: backgrounds about -34 dB
mean (courtroom murmur -38, fire -30), tension loops about -26 dB, effects judged by peak (aim for a
peak of -6 to -10 dB). You cannot hear the result: say so in the report and ask the owner to judge the mix.

Test with a `--robot` run (see the `playtest` skill); `--auto` does not exercise sound.
