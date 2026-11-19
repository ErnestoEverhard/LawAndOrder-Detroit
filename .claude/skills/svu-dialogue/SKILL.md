---
name: svu-dialogue
description: How people talk in this game - the Law & Order SVU register. Use before writing or editing any spoken line in godot/story.gd (detectives, witnesses, suspects, the ADA, the judge, the victim), when a line sounds like a report or a narrator instead of a person, and when the user says dialogue is stiff, too detailed or unnatural.
---

# How SVU characters talk

Measured from 101 episode transcripts (every sixth episode, seasons 1-28, about 90,000 sentences),
read in the browser from transcripts.foreverdreaming.org. Those are subtitle files with no speaker
names, so the numbers are per sentence, not per speaker turn. The transcripts are reference only:
never copy lines from them into the game.

| Measure | The show | Check ours with |
|---|---|---|
| Words per sentence | median 5, mean 6.4 | `python3 godot/tools/dialogue_stats.py` |
| Sentences of 3 words or fewer | 30% | same |
| Sentences over 15 words | 5% (over 25: 0.5%) | `--long` lists ours |
| Sentences that are questions | 20% | same |
| A question answered by another question | 17% of questions | read it |
| Sentence that names a colour and a garment together | 21 in 101 episodes | read it |
| Addressing someone by name or title | about 1 sentence in 80 | read it |
| "Objection" / the ruling | median 1 word each; 77% of rulings are one word | read it |

The first version of this script matched the sentence lengths but had 5% questions against the
show's 20%, and a median of 15 words per turn. That is the fault to watch for: **people volunteering
complete information in a block.** On the show, facts come out because someone asked.

## The rules

1. **Nobody volunteers a description.** A witness says what happened to *them* ("some guy had her
   bag"). Looks, clothes, vehicle, time only come when a detective asks, one attribute per answer,
   as a fragment: "White." "Skinny." "Thirty, maybe." Detectives prompt each next attribute
   ("Age?" "What about his hair?").
2. **Witnesses are unsure and self-interested.** "I don't know." "Maybe." They compare ("like a
   janitor"), give one odd specific detail and miss the obvious ones, and explain why they noticed
   or did not ("I was looking at her, not him").
3. **One fact per sentence, two sentences per turn at most** for anyone under stress. If a turn
   carries three facts, split it and give the other person a line in between, even just "And?"
4. **Detectives talk in shorthand to each other.** No full reports. Name, then fragments: "Wade
   Harlan. Thirty-four. Maintenance." The partner finishes the thought, or undercuts it with a dry
   line. They already share context, so they never explain the job to each other.
5. **Questions drive scenes.** Aim for one sentence in five being a question. Detectives ask short
   ones and repeat the witness's last words back as a question ("His van?").
6. **People dodge.** Suspects answer a different question, answer with a question, or go to rights
   and lawyers. Reluctant friends say "I don't know" before they say the true thing.
7. **Interruptions and trailing off** are for frightened people, and rare (about 2% of sentences).
   Do not put a dash on every line.
8. **Names are rare.** A detective uses a first name to steady someone or to turn the screw, not
   as punctuation. Lawyers say "Your Honor" and "Detective"; friends do not say names at all.
9. **Courtroom is clipped.** "Objection." "Sustained." A reason is two or three words
   ("Hearsay." "Argumentative."). A judge explains only when the ruling is the point of the scene,
   and then in one or two plain sentences. Cross-examination is short leading questions that take
   yes or no.
10. **The ADA and the captain talk about consequences, not doctrine.** "Without a warrant I lose
    the van." They name the legal rule only when arguing to the judge.
11. **Victims understate.** Flat, short, concrete. They do not summarise their own ordeal or make
    speeches about the system; one plain sentence does the work.
12. **End a scene on a short line** that turns it: a dry remark, a new fact, or an order ("Go.").
13. **Narration is not dialogue.** The unvoiced narrator lines may carry exact times, counts and
    descriptions. Characters may not.

## Example from this script

Before (one turn, volunteered, exact):

    EVAN: I went to the library to talk to her after her shift. Around nine she came out the
          service door, and a maintenance guy in a gray work shirt was carrying her bag. She got
          into his van.

After (dragged out, vague first, detail only when asked):

    OKONKWO: You were there tonight.
    EVAN:    I just wanted to talk to her.
    OKONKWO: And?
    EVAN:    She came out the back with some guy. He had her bag.
    REYES:   What guy?
    EVAN:    I don't know. He works there. A janitor or something.
    OKONKWO: What did he look like?
    EVAN:    I wasn't looking at him.

## Game constraints

- The player still has to learn the facts each branch depends on (names, the van, the key). Move a
  fact to a question-and-answer or to a narrator line rather than cutting it.
- Lines are `["WHO", "text", "shot"?]` in `scene(...)` lists in `godot/story.gd`; some are followed
  by `if ... else null`. Keep those conditions when splitting a line.
- After editing run `godot --headless --path godot -s tools/validate.gd` and
  `python3 godot/tools/dialogue_stats.py`.
