class_name Story
extends RefCounted
## DEAD SIGNAL — the story graph. Original characters and case.
## Node types: card, scene, choice, roam, qte, branch, chapterEnd, ending.
## `bg` is "location:arrangement" and picks the 3D set. A beat is [speaker, text] or [speaker, text, shot].
## Conditions and effects are small functions of the CaseState `s`.

const START := "c1_card"
var N := {}
var FLOW := {}

func scene(id: String, bg: String, beats: Variant, next: Variant, fx: Variant = null) -> void:
	N[id] = {"type": "scene", "bg": bg, "beats": beats, "next": next, "do": fx}

func choice(id: String, prompt: String, timer: float, options: Array, timeout: Dictionary) -> void:
	N[id] = {"type": "choice", "prompt": prompt, "timer": timer, "options": options, "timeout": timeout}

func opt(label: String, sub: String, next: String, fx: Variant = null, req: Variant = null, lock := "") -> Dictionary:
	return {"label": label, "sub": sub, "next": next, "do": fx, "req": req, "lock": lock}

func branch(id: String, next: Callable) -> void:
	N[id] = {"type": "branch", "next": next}

func press(key: String, act: String, text: String, ms := 1500) -> Dictionary:
	return {"type": "press", "key": key, "act": act, "ms": ms, "text": text}

func mash(act: String, n: int, text: String, ms := 3200) -> Dictionary:
	return {"type": "mash", "key": "SPACE", "act": act, "n": n, "ms": ms, "text": text}

func hold(act: String, hold_ms: int, text: String, ms := 2200) -> Dictionary:
	return {"type": "hold", "key": "E", "act": act, "hold": hold_ms, "ms": ms, "text": text}

func _init() -> void:
	_chapter1()
	_chapter2_ex()
	_chapter2()
	_chapter3()
	_chapter4()
	_endings()
	_flow()

# ───────────── CHAPTER 1 — THE EMPTY APARTMENT ─────────────

func _chapter1() -> void:
	N.c1_card = {"type": "card", "chapter": 1, "bg": "apartment:search", "next": "c1_arrive",
		"lines": ["APARTMENT OF TESSA BRANDT", "418 MERCER STREET, APT 3C", "TUESDAY, OCTOBER 14 — 11:42 PM", "— YOU PLAY DETECTIVE NADIA OKONKWO —"]}

	scene("c1_arrive", "apartment:search", [
		["", "You are Detective Nadia Okonkwo of the Special Victims Division, 9th Precinct. Your partner, Detective Sam Reyes, got here four minutes before you did.", "door"],
		["REYES", "Roommate called it in around ten. Tessa Brandt. Nineteen."],
		["REYES", "Never came home from work. Phone's off."],
		["OKONKWO", "A few hours late doesn't get us out of bed."],
		["REYES", "It does when patrol runs her name. Open stalking complaint."],
		["OKONKWO", "I know. I took it."],
		["REYES", "You took it?"],
		["OKONKWO", "Three weeks ago. Texts from a number she didn't know. No threats, no name."],
		["OKONKWO", "I told her to keep a record."],
		["REYES", "Then she kept one. You want to find it? Crime scene's a few minutes out, and then we're reading about it."],
		["OKONKWO", "Then we look now."],
	], "c1_inv")

	N.c1_inv = {"type": "roam", "bg": "apartment:search", "budget": 4, "next": "c1_priya",
		"title": "SEARCH TESSA'S ROOM",
		"intro": "This is Tessa Brandt's bedroom, in the apartment she shares with Priya Nair. Six things in this room are worth your attention, and you have time to examine four before the crime scene unit seals it.\n\nClick to look around. WASD to walk. Look at a glowing marker and press E. You can also talk to your partner. When you are done, go out to the hall and talk to Priya.",
		"spent": "The crime scene unit is at the door. Time to step out and talk to Priya, on the stairs in the hall.",
		"exit": {"talk": "PRIYA", "early": "Leave the room and hear her out? You still have time to look at more."},
		"hotspots": [
			{"name": "Tablet", "text": "Her tablet, showing her text messages. 73 unread, all from the unknown number in her complaint. It was a few dozen when she came to you. The most recent, 8:51 PM: \"You looked tired today. I can help with that.\"",
				"do": func(s): s.clue("tablet", "73 messages from an unsaved number")},
			{"name": "Bookshelf", "text": "A coffee can of dried flowers. Under it, a stack of index cards in careful block capitals. \"I SAW YOU ON THE THIRD FLOOR.\" \"SIT BY THE WINDOW AGAIN.\" She kept every one, the way you keep things you might need as proof.",
				"do": func(s): s.clue("notes", "Index cards — \"sit by the window again\"")},
			{"name": "Laptop", "text": "Open to a rideshare receipt. She ordered a ride home at 9:14 PM from the Hollis University Library service entrance. The ride was cancelled at 9:16, two minutes later. She never got home.",
				"do": func(s): s.clue("receipt", "Ride cancelled at library service entrance, 9:16 PM")},
			{"name": "Window", "text": "The fire-escape window. The latch is intact. Outside, behind a dead plant on the fire escape, two cut zip ties hang from the railing around a clean patch in the rust. Something small was strapped there, low and out of sight from inside, aimed at her window.",
				"do": func(s): s.clue("window", "Cut zip ties on the fire escape — a hidden camera was mounted there")},
			{"name": "Corkboard", "text": "Her class schedule and her work calendar. She works the closing shift at the library circulation desk on Tuesdays and Thursdays. Tonight is Tuesday. A sticky note in her handwriting: \"ask Campus Safety AGAIN about my report.\"",
				"do": func(s): s.clue("report", "Worked closing shifts at the library; had filed a report")},
			{"name": "Wastebasket", "text": "A photo-booth strip, torn in half. Tessa's half is here; whoever sat beside her has been ripped away. On the back, in pen: \"E + T\", with the E scratched out hard enough to tear the paper.",
				"do": func(s): s.clue("ex", "Torn photo strip — an ex, initial \"E\"")},
		]}

	scene("c1_priya", "apartment:hall", [
		["", "The roommate, Priya Nair, is sitting on the hallway stairs with her knees pulled up, holding her phone in both hands in case it rings.", "wide"],
		["PRIYA", "She texts me when she leaves work. Every time. \"Leaving.\" That's it."],
		["PRIYA", "Tonight, nothing."],
		["REYES", "Anyone bothering her? An ex? Somebody from class?"],
		["PRIYA", "No. I don't know."],
		["REYES", "You don't know?"],
		["PRIYA", "She would have told me."],
	], "c1_priya_choice")

	choice("c1_priya_choice", "Priya is staring at the floor. She knows something, and she thinks it isn't hers to tell.", 12, [
		opt("REASSURE", "You're not betraying her.", "c1_priya_soft"),
		opt("THE CARDS", "Show her what Tessa kept.", "c1_priya_cards", null, func(s): return s.has("notes"), "Requires: index cards"),
		opt("PRESS", "Every minute matters. Talk.", "c1_priya_hard"),
	], {"next": "c1_priya_silent"})

	scene("c1_priya_soft", "apartment:hall", [
		["OKONKWO", "Priya. She asked you to keep something quiet."],
		["OKONKWO", "That was before tonight."],
		["PRIYA", "Everybody thinks it's Evan. Her ex. He texts her all day."],
		["REYES", "But?"],
		["PRIYA", "Evan's just pathetic. He's not who she was scared of."],
		["OKONKWO", "Who was she scared of?"],
		["PRIYA", "There's a guy at the library. Maintenance. He's always fixing something when she's on."],
		["PRIYA", "She reported him. They said he hadn't done anything."],
		["OKONKWO", "Does he have a name?"],
		["PRIYA", "Wade."],
	], "c1_lead", func(s):
		s.f.evanName = true
		s.clue("name", "Roommate statement — \"Wade\", library maintenance")
		s.partner(1, "liked how you handled her"))

	scene("c1_priya_cards", "apartment:hall", [
		["", "You lay the index cards on the stair beside her, one at a time."],
		["PRIYA", "Oh my god."],
		["PRIYA", "She said he stopped."],
		["OKONKWO", "Who?"],
		["PRIYA", "Wade. He does maintenance at the library. Nights."],
		["PRIYA", "She thought if she ignored him, he'd go away. She made me promise."],
	], "c1_lead", func(s): s.clue("name", "Roommate statement — \"Wade\", library maintenance"))

	scene("c1_priya_hard", "apartment:hall", [
		["OKONKWO", "Every minute you sit on this, she's out there alone. A name."],
		["PRIYA", "Evan! Okay? Evan Kessler. Her ex."],
		["PRIYA", "She blocked him, so he got a new number. Is that what you want?"],
		["", "She is crying now. Reyes steps between the two of you without making it obvious."],
		["REYES", "That helps. Thank you. You okay to stay here?"],
	], "c1_lead", func(s):
		s.f.evanName = true
		s.say("LEAD — Evan Kessler, ex-boyfriend")
		s.partner(-1, "thinks you pushed a witness too hard"))

	scene("c1_priya_silent", "apartment:hall", [
		["", "You say nothing and wait for her to fill the silence. She doesn't."],
		["PRIYA", "...Can I go back inside? I want to be there if she calls."],
	], "c1_lead")

	branch("c1_lead", func(s): return "c1_lead_talk" if (s.can_lib() or s.can_ex()) else "c1_lead_slow")

	scene("c1_lead_talk", "apartment:hall", func(s): return [
		["REYES", "An ex who won't let go. Nine times out of ten, it's the boyfriend."] if s.can_ex() else null,
		["OKONKWO", "Her whole night runs through that library."] if s.can_lib() else null,
		["REYES", "One car. Where to?"],
	], "c1_lead_choice")

	choice("c1_lead_choice", "Two possible leads, one car. Whichever you choose, the other waits.", 14, [
		opt("THE LIBRARY", "Where she was last seen, and who was there.", "c1_lead_good", null, func(s): return s.can_lib(), "Requires: evidence pointing to the library"),
		opt("THE EX", "Whoever sent her 73 messages.", "c1_lead_ex", null, func(s): return s.can_ex(), "Requires: evidence pointing to an ex"),
	], {"next": "c1_lead_timeout"})
	branch("c1_lead_timeout", func(s): return "c1_lead_ex" if s.can_ex() else "c1_lead_good")

	scene("c1_lead_good", "apartment:hall", [
		["REYES", "Library it is. Three names on the night roster."],
		["REYES", "One's got a trespass charge. Dropped."],
		["OKONKWO", "Who?"],
		["REYES", "Wade Harlan. Thirty-four. Maintenance."],
	], "c1_end")

	scene("c1_lead_ex", "apartment:hall", [
		["REYES", "The number's a burner. But the account email starts with \"ekessler.\""],
		["OKONKWO", "The ex."],
		["REYES", "Evan Kessler. Twenty-one. Rents a place on Delancey Court."],
		["OKONKWO", "Let's go wake him up."],
	], "c1_end", func(s): s.f.wentEx = true)

	scene("c1_lead_slow", "apartment:hall", [
		["REYES", "We've got nothing that points anywhere."],
		["", "It takes most of an hour on the phone before a tired Campus Safety dispatcher mentions a harassment report Tessa filed in September. That is an hour Tessa Brandt does not have."],
		["REYES", "The report names a Wade Harlan. Night maintenance at the library. Let's move."],
	], "c1_end", func(s): s.lost(1, "no lead from the apartment"))

	N.c1_end = {"type": "chapterEnd", "chapter": 1, "next": "c1_out"}
	branch("c1_out", func(s): return "c2e_card" if s.on("wentEx") else "c2_card")

# ───────────── CHAPTER 2 (detour) — THE EX ─────────────

func _chapter2_ex() -> void:
	N.c2e_card = {"type": "card", "chapter": 2, "bg": "delancey:door", "next": "c2e_door",
		"lines": ["RESIDENCE OF EVAN KESSLER", "88 DELANCEY COURT", "WEDNESDAY, OCTOBER 15 — 12:51 AM"]}

	scene("c2e_door", "delancey:door", [
		["", "A student rental with a couch on the porch and one light on upstairs. Somebody's recycling has been at the curb for more than one week.", "wide"],
		["", "Reyes knocks hard. The door opens. A young man with his phone still in his hand sees two badges, and the color drains out of his face.", "EVAN"],
		["EVAN", "Is this about Tessa? I didn't — I only —"],
		["", "He slams the door. You hear him running for the back of the house.", "wide"],
		["REYES", "Innocent people don't run. Go!"],
	], "c2e_chase")

	N.c2e_chase = {"type": "qte", "bg": "delancey:yards", "title": "BACK YARDS", "track": "yards",
		"steps": [
			press("D", "CUT HIM OFF", "He comes out the kitchen door."),
			press("W", "OVER THE FENCE", "A six-foot wooden fence."),
			mash("RUN", 9, "Three back yards in a row."),
			press("A", "SIDESTEP", "He kicks a trash can at you.", 1400),
			hold("PIN HIM", 1000, "He trips and goes down."),
		],
		"do": func(s, r):
			s.f.evanFails = r.fails
			if r.fails >= 2:
				s.lost(1, "Kessler got away from you"),
		"next": "c2e_caught"}

	scene("c2e_caught", "delancey:caught", func(s): return [
		["", "You lose him. Twenty minutes later a patrol car finds him hiding behind a dumpster two streets away."] if s.num("evanFails") >= 2
			else ["", "You get a knee on his back. He doesn't fight. He just keeps saying her name."],
		["EVAN", "I didn't do anything! I just text her! That's all I do, I just text her!"],
		["REYES", "Seventy-three times. Let's go, Romeo."],
	], "c2e_int_card")

	N.c2e_int_card = {"type": "card", "bg": "precinct:evan", "next": "c2e_int",
		"lines": func(s): return ["9TH PRECINCT, SPECIAL VICTIMS DIVISION", "INTERVIEW ROOM 2", "WEDNESDAY, OCTOBER 15 — " + s.clock(1, 40)]}

	scene("c2e_int", "precinct:evan", [
		["", "Interview Room 2. Evan Kessler, twenty-one. Since the arrest he has cried twice and asked for his mother once. He signed the rights form without reading it.", "wide"],
		["EVAN", "She blocked me. So I got a new number. I know how that sounds."],
		["EVAN", "I just wanted her to answer. One time."],
		["OKONKWO", "\"You looked tired today.\" You saw her tonight."],
		["EVAN", "I went to the library. To talk. That's all."],
		["OKONKWO", "And?"],
		["EVAN", "She came out the back with some guy. He had her bag."],
		["REYES", "What guy?"],
		["EVAN", "I don't know. He works there. A janitor or something."],
		["OKONKWO", "What did he look like?"],
		["EVAN", "I wasn't looking at him. He had a van. She got in."],
		["REYES", "And you did what?"],
		["EVAN", "I figured she was with him now. I went home."],
		["REYES", "(to you, quietly) Convenient. Our stalker saw a different stalker."],
	], "c2e_decide")

	choice("c2e_decide", "He ran from police, he lied to get around being blocked, and he admits he was there. Reyes wants to book him.", 14, [
		opt("HANDWRITING", "Make him copy out the index cards.", "c2e_hand", null, func(s): return s.has("notes"), "Requires: index cards"),
		opt("BELIEVE HIM", "Check his story about the van. It will cost time.", "c2e_believe"),
		opt("BOOK HIM", "It's always the boyfriend.", "c2e_book"),
	], {"next": "c2e_book"})

	scene("c2e_hand", "precinct:evan", [
		["", "You hand him a pen and read the index cards aloud. He writes them out in a cramped, slanted script that looks nothing like the block capitals on the cards.", "table"],
		["REYES", "That's not his handwriting. Not even close."],
		["REYES", "He didn't write those."],
		["OKONKWO", "A janitor with a van. Who works nights at that library?"],
		["REYES", "Wade Harlan. Maintenance. Let's go."],
	], "c2_card", func(s):
		s.f.cleared = true
		s.mark("evan_cleared")
		s.clue("witness", "Kessler saw Tessa get into a maintenance van", 6)
		s.lost(1, "an hour spent on the wrong man"))

	scene("c2e_believe", "precinct:evan", [
		["", "It takes Reyes over an hour to get the library's outdoor camera footage. At 9:16 PM, Tessa Brandt climbs into a white maintenance van. Evan Kessler is at the edge of the frame, watching, then walking away.", "wide"],
		["REYES", "Kid was telling the truth. The van's signed out to a Wade Harlan. Night maintenance."],
		["REYES", "Two hours. On the wrong guy."],
	], "c2_card", func(s):
		s.f.cleared = true
		s.mark("evan_cleared")
		s.clue("witness", "Camera: Tessa enters maintenance van, 9:16 PM", 8)
		s.lost(2, "two hours spent on the wrong man"))

	scene("c2e_book", "precinct:evan", [
		["OKONKWO", "Evan Kessler, you are under arrest for the kidnapping of Tessa Brandt."],
		["EVAN", "What? No — the van! Check the van! Please!"],
		["DIAZ", "(from the doorway) Stalker ex, no alibi, ran from police. Good work. Go home.", "door"],
		["DIAZ", "He'll tell us where she is in the morning."],
		["REYES", "He ran. He lied. Seventy-three texts. What more do you want?"],
		["REYES", "So why don't I feel good about it?"],
		["", "Nobody checks the van.", "wide"],
	], "c2_end", func(s):
		s.f.wrong = true
		s.add(-15)
		s.say("ARREST — Evan Kessler booked for kidnapping"))

# ───────────── CHAPTER 2 — THE SERVICE ENTRANCE ─────────────

func _chapter2() -> void:
	N.c2_card = {"type": "card", "chapter": 2, "bg": "library:dock", "next": "c2_call",
		"lines": func(s): return ["HOLLIS UNIVERSITY LIBRARY", "SERVICE ENTRANCE", "WEDNESDAY, OCTOBER 15 — " + s.clock(1, 7)]}

	scene("c2_call", "library:dock", [
		["", "A white maintenance van is parked at the loading dock with its rear doors shut. The service door beside the roller shutter is propped open with a mop bucket, and there is a light on inside.", "wide"],
		["DIAZ", "(on the phone) Okonkwo. Cole's waking up a judge. Van and locker. Thirty minutes."],
		["OKONKWO", "Thirty minutes?"],
		["DIAZ", "Do not go in there without it."],
		["REYES", "(quietly) Thirty minutes? If she's in that van, that's thirty more minutes.", "REYES"],
		["REYES", "And if she isn't, and we open it anyway? Some lawyer argues about everything in there for a year."],
	], "c2_warrant")

	choice("c2_warrant", "Captain Diaz is still on the line, waiting for your answer.", 14, [
		opt("WAIT", "Get the warrant. Use the thirty minutes to canvass the dock.", "c2_wait"),
		opt("GO NOW", "Search without it. Her life is at risk.", "c2_go"),
	], {"next": "c2_wait"})

	scene("c2_wait", "library:dock", [
		["OKONKWO", "Understood, Captain. We'll hold for the paper."],
		["REYES", "For the record, I hate this."],
		["OKONKWO", "The van needs a warrant. The dock doesn't."],
	], "c2_canvass", func(s):
		s.f.warrant = true
		s.late += 1)

	N.c2_canvass = {"type": "roam", "bg": "library:dock", "budget": 2, "next": "c2_warrant_in",
		"title": "CANVASS THE DOCK",
		"intro": "Thirty minutes until the warrant. You can't open the van or his locker yet, but three things in plain view on this dock are worth a look, and you have time for two.\n\nLook at a glowing marker and press E. When you are done, talk to Reyes.",
		"spent": "Your phone buzzes. Go and tell Reyes.",
		"exit": {"talk": "REYES", "early": "Stop looking and wait by the van? You still have time for more."},
		"hotspots": [
			{"name": "Dumpster", "text": "On top of the flattened boxes in the dumpster: a phone in a cracked green case, battery pulled. The sticker on the back is a Hollis library barcode with BRANDT, T. printed under it. Nobody has a privacy claim over what they throw away. You bag it.",
				"do": func(s): s.clue("phone", "Tessa's phone, battery pulled, in the dock dumpster")},
			{"name": "Time clock", "text": "The staff time clock, just inside the propped door. One card is out of its slot: HARLAN, W. Punched out at 9:02 PM. His van is still here four hours later, and so, by the light inside, is he.",
				"do": func(s): s.clue("timecard", "Harlan punched out at 9:02 PM but never left", 4)},
			{"name": "Dock camera", "text": "The security camera over the dock has been turned on its bracket to face the brick, and there is a strip of duct tape across the lens. The dust on the bracket is freshly smeared. Somebody planned for tonight.",
				"do": func(s): s.clue("camera", "Dock camera turned to the wall and taped over", 4)},
		]}

	scene("c2_warrant_in", "library:dock", [
		["", "Thirty-one minutes after you hung up, the warrant arrives on your phone with a one-word text from Diaz: \"Now.\"", "REYES"],
		["REYES", "Van and locker. Locker first? It's ten feet inside the door."],
		["", "Locker 14, HARLAN. A spare gray shirt, a thermos, and a shoebox. In the shoebox: a small battery camera with zip-tie mounts, and two memory cards labelled in block capitals. \"WINDOW — SEPT.\" \"WINDOW — OCT.\"", "locker"],
		["REYES", "Two months. He's been watching her bedroom for two months."],
		["OKONKWO", "And a judge signed for every bit of it."],
	], "c2_van", func(s):
		s.add(8)
		s.say("WARRANT SECURED — this search will hold up in court")
		s.clue("locker", "Camera and memory cards from Harlan's locker", 8))

	scene("c2_go", "library:dock", [
		["OKONKWO", "Captain, you're breaking up. Bad signal."],
		["DIAZ", "Nadia, don't you d—"],
		["", "You hang up."],
		["REYES", "\"Bad signal.\" That's what we're going with?", "REYES"],
	], "c2_van", func(s):
		s.f.warrant = false
		s.partner(1, "respects the call"))

	scene("c2_van", "library:van", [
		["", "Reyes opens the van's rear doors. Nobody inside. But there is a moving blanket, a roll of duct tape, and one white sneaker — a woman's, size seven.", "van"],
		["", "The service door swings wide. A man in a gray work shirt stands in the doorway. He looks at the open van, then at you.", "HARLAN"],
		["HARLAN", "That's university property. You can't be in there."],
	], "c2_harlan", func(s): s.clue("sneaker", "Tessa's sneaker in the maintenance van", 8))

	choice("c2_harlan", "Wade Harlan, twelve feet away. He is already leaning toward the door behind him.", 8, [
		opt("CALM", "We just want to talk, Wade.", "c2_h_calm"),
		opt("THE CARDS", "Quote his own notes back to him.", "c2_h_cards", null, func(s): return s.has("notes"), "Requires: index cards"),
		opt("RUSH", "Grab him before he runs.", "c2_h_rush"),
	], {"next": "c2_h_rush"})

	scene("c2_h_calm", "library:van", [
		["OKONKWO", "Wade? Nobody's in trouble yet. Can we talk?"],
		["", "He hesitates. It buys you half a second."],
	], "c2_chase", func(s):
		s.f.edge = true
		s.say("HEAD START — the chase will be easier"))
	scene("c2_h_cards", "library:van", [
		["OKONKWO", "\"Sit by the window again.\""],
		["HARLAN", "She... kept those?"],
		["", "For one full second he forgets to run."],
	], "c2_chase", func(s):
		s.f.edge = true
		s.say("HEAD START — the chase will be easier"))
	scene("c2_h_rush", "library:van", [
		["", "You lunge. He is faster — he turns and bolts back through the service door."],
	], "c2_chase")

	N.c2_chase = {"type": "qte", "bg": "library:chase", "title": "PURSUIT", "track": "chase",
		"scale": func(s): return 1.3 if s.on("edge") else 1.0,
		"steps": [
			press("A", "DODGE", "He throws a wrench at your head."),
			press("W", "VAULT", "A book cart rolls into your path."),
			mash("PUSH THROUGH", 8, "He pulls shelves down behind him."),
			press("S", "SLIDE THE RAIL", "He takes the stairs down.", 1400),
			press("D", "SHOULDER IT", "A fire door is swinging shut.", 1400),
			mash("SPRINT", 10, "Outside. He runs for the rail yard fence."),
			hold("GRAB HIS BELT", 1000, "He is halfway up the fence."),
		],
		"do": func(s, r): s.f.chaseFails = r.fails,
		"next": func(s, r): return "c2_caught" if r.fails <= 1 else "c2_fled"}

	scene("c2_caught", "library:fence", [
		["", "You drag him off the fence and the two of you hit the gravel. He is stronger than he looks, but Reyes is there with the handcuffs.", "wide"],
		["REYES", "Wade Harlan, you are under arrest. You have the right to remain silent —"],
		["", "Harlan says nothing. He keeps looking over your shoulder, toward the rail yard.", "HARLAN"],
	], "c2_int_card", func(s): s.f.caught = true)

	scene("c2_fled", "library:fence", func(s): return [
		["", "He drops down the far side of the fence and disappears between the freight cars.", "wide"],
		["", "Reyes climbs over after him and lands badly. You hear her hit the ground."] if s.num("chaseFails") >= 4 else null,
		["REYES", "It's my ankle. I can still walk. Keep going."] if s.num("chaseFails") >= 4 else null,
		["", "Something is caught on the top of the fence: a belt loop torn from his shorts, with a single old brass key clipped to it. The key is stamped \"C.R.\"", "key"],
		["REYES", "C.R. Calder Rail. That's a signal tower key."],
		["REYES", "He wasn't running from us. He was running to her."],
	], "c2_end", func(s):
		s.f.fled = true
		s.late += 1
		if s.num("chaseFails") >= 4:
			s.f.reyesHurt = true
			s.mark("reyes_hurt")
		s.clue("key", "Calder Rail key torn from Harlan's belt", 4))

	N.c2_int_card = {"type": "card", "bg": "precinct:booking", "next": "c2_booking",
		"lines": func(s): return ["9TH PRECINCT, SPECIAL VICTIMS DIVISION", "BOOKING DESK", "WEDNESDAY, OCTOBER 15 — " + s.clock(2, 15)]}

	scene("c2_booking", "precinct:booking", [
		["", "Booking. Reyes empties Harlan's pockets into a property tray and names each item for the desk sergeant.", "wide"],
		["REYES", "Wallet. University ID. Phone, no SIM card. Work keys."],
		["REYES", "And one more. Loose, other pocket. Old brass. Tag says \"C.R.\"", "tray"],
		["REYES", "What's it open, Wade?"],
		["HARLAN", "That's nothing. It's for a shed."],
		["", "It is the first thing he has said since the arrest. You take the key with you."],
	], "c2_int", func(s): s.clue("key", "Brass key tagged \"C.R.\" from Harlan's pocket", 4))

	scene("c2_int", "precinct:harlan", [
		["", "Interview Room 2. The camera in the corner has a red light on. Harlan sits very still with both hands flat on the table.", "wide"],
		["OKONKWO", "Before anything else, Wade. You have the right to remain silent. You have the right to a lawyer, here, while we talk."],
		["OKONKWO", "If you can't afford one, you get one anyway. You understand?"],
		["HARLAN", "I understand. I've got nothing to hide."],
		["HARLAN", "I maintain the building. I see who comes and goes. That's not a crime."],
		["REYES", "Where is Tessa Brandt, Wade?"],
		["HARLAN", "At home, I'd think. It's late."],
	], "c2_int1", func(s): s.f.pts = 0)

	choice("c2_int1", "He is calm and in no hurry. You need to shake that. How do you start?", 14, [
		opt("EMPATHY", "Nobody notices the man who fixes things.", "c2_int1_emp"),
		opt("EVIDENCE", "Show him everything you have.", "c2_int1_ev", null, func(s): return s.pre_van() >= 3, "Requires: 3 pieces of evidence found before the van"),
		opt("THREATEN", "Kidnapping is twenty-five to life.", "c2_int1_thr"),
	], {"next": "c2_int1_none"})

	scene("c2_int1_emp", "precinct:harlan", [
		["OKONKWO", "Eleven years in that building. You keep it all running. Does anybody even know your name?"],
		["HARLAN", "...Do you know how many people in that library know my name? Two. And one of them does the payroll."],
	], "c2_int2", func(s):
		s.f.pts += 1
		s.f.emp = true
		s.say("HARLAN — opening up"))
	scene("c2_int1_ev", "precinct:harlan", [
		["", "You lay the evidence on the table one piece at a time, slowly. By the third piece, Harlan has stopped smiling.", "table"],
		["HARLAN", "You're making it sound like something it wasn't."],
	], "c2_int2", func(s):
		s.f.pts += 2
		s.say("HARLAN — rattled"))
	scene("c2_int1_thr", "precinct:harlan", [
		["OKONKWO", "Kidnapping is twenty-five to life, Wade. How old will you be?"],
		["HARLAN", "Then I had better not say anything at all."],
	], "c2_int2", func(s):
		s.f.hostile = true
		s.say("HARLAN — shut down"))
	scene("c2_int1_none", "precinct:harlan", [
		["", "You wait too long. Reyes steps in with questions Harlan has clearly prepared for."],
	], "c2_int2")

	choice("c2_int2", "One more try before he stops talking altogether.", 14, [
		opt("HER SHOE", "The sneaker in your van.", "c2_int2_shoe"),
		opt("HIS SIDE", "Ask him to tell it his way.", "c2_int2_ver"),
		opt("BLUFF", "Claim the van's GPS already led you to her.", "c2_int2_lie"),
	], {"next": "c2_int_gate"})

	scene("c2_int2_shoe", "precinct:harlan", [
		["OKONKWO", "A white sneaker, size seven, in the back of your van. Where is the other one, Wade?"],
		["HARLAN", "She was cold. I gave her a blanket. Is that what a monster does?"],
		["", "Reyes writes that down word for word. He has just admitted she was in the van.", "REYES"],
	], "c2_int_gate", func(s):
		s.f.pts += 1
		s.add(4)
		s.say("ADMISSION — \"I gave her a blanket\""))
	scene("c2_int2_ver", "precinct:harlan", func(s): return [
		["OKONKWO", "Forget how it looks. What happened, Wade? Your way."],
		["HARLAN", "She was going to quit. I heard her say it at the desk. If she quit, I'd never see her again. I just needed more time. That's all it was."] if s.on("emp")
			else ["HARLAN", "I would tell it to somebody who actually wanted to hear it. That isn't you."],
	], "c2_int_gate", func(s): s.f.pts += 2 if s.on("emp") else 1)
	scene("c2_int2_lie", "precinct:harlan", func(s): return [
		["OKONKWO", "University vans have GPS, Wade. We know where you took her. I'm letting you be the one who says it."],
		["HARLAN", "If you knew where she was, you wouldn't be sitting here with me."] if s.on("hostile")
			else ["HARLAN", "...Then you know she's warm. You know I left the heater on for her."],
	], "c2_int_gate", func(s):
		s.f.bluffed = true
		if not s.on("hostile"):
			s.f.pts += 2)

	branch("c2_int_gate", func(s): return "c2_confess" if s.num("pts") >= 3 else "c2_lawyer")

	scene("c2_confess", "precinct:harlan", [
		["HARLAN", "The old signal tower in the rail yard. Number six. She's fine. She's warm. I left the heater on for her."],
		["", "A voluntary confession, on video, after he was read his rights and said he understood them. Reyes is already out the door.", "wide"],
	], "c2_end", func(s):
		s.f.confession = true
		s.add(15)
		s.say("CONFESSION — voluntary and on video"))

	scene("c2_lawyer", "precinct:harlan", [
		["HARLAN", "I think... I think I would like a lawyer now."],
		["", "The room goes quiet. The rule is simple and it is old: once he asks for a lawyer, the questions stop until one is sitting beside him. Tessa is still out there somewhere.", "wide"],
	], "c2_lawyer_choice")

	choice("c2_lawyer_choice", "\"I think I would like a lawyer.\" Anything you get out of him by questioning after this, a judge can throw out.", 12, [
		opt("STOP", "Follow the law. Find her another way.", "c2_stop"),
		opt("CLARIFY", "\"Are you asking for a lawyer, Wade?\" Make it clean on the tape.", "c2_clarify"),
		opt("KEEP PUSHING", "Break the rule. \"Where is she, Wade?\"", "c2_push"),
	], {"next": "c2_stop"})

	scene("c2_stop", "precinct:harlan", [
		["", "You pick up the file and walk out, leaving him alone with the camera.", "wide"],
		["REYES", "The brass key. \"C.R.\" is Calder Rail. Yard office says it fits the old signal towers."],
		["OKONKWO", "How many towers?"],
		["REYES", "Nine."],
		["", "You start at tower one. It takes forty minutes to search the first five."],
	], "c2_end", func(s):
		s.lost(1, "searching the towers one by one")
		s.partner(1, "knows what that cost you"))

	scene("c2_clarify", "precinct:harlan", [
		["OKONKWO", "I need to be sure, Wade. You want a lawyer before we go on?"],
		["HARLAN", "Yes. A lawyer."],
		["OKONKWO", "Then we're done. Nobody is going to ask you anything else."],
		["", "You stand. You have your hand on the door when he speaks again, to the table, not to you."],
		["HARLAN", "She'll be all right till morning. The tank's good for four hours. Maybe five."],
		["", "Nobody asked him. Reyes looks at the camera's red light, then at you. A man who has asked for a lawyer can't be questioned. He can still talk.", "REYES"],
		["REYES", "A tank. He left a heater running. Nobody's watching it."],
		["REYES", "\"C.R.\" Calder Rail. Nine signal towers in that yard. Go."],
	], "c2_end", func(s):
		s.f.clarified = true
		s.add(5)
		s.say("VOLUNTEERED — \"the tank's good for four hours\"")
		s.lost(1, "searching the towers one by one")
		s.partner(1, "that's how it's supposed to be done"))

	scene("c2_push", "precinct:harlan", [
		["OKONKWO", "Forget the lawyer. Forget the case. She's nineteen and she's alone. Where is she?"],
		["HARLAN", "...The signal tower in the rail yard. Number six. The heater is on. She's fine."],
		["REYES", "(in the hallway, quietly) Cole is going to pay for that in front of a judge.", "REYES"],
		["OKONKWO", "I know."],
	], "c2_end", func(s):
		s.f.pushed = true
		s.say("RIGHTS VIOLATION — this statement will be challenged in court"))

	N.c2_end = {"type": "chapterEnd", "chapter": 2, "next": "c2_out"}
	branch("c2_out", func(s): return "c3w_card" if s.on("wrong") else "c3_card")

# ───────────── CHAPTER 3 — TOWER SIX ─────────────

func _calm(s: CaseState, n: int) -> void:
	s.f.calm = s.num("calm") + n
	s.say("HARLAN — calmer" if n > 0 else ("HARLAN — more agitated" if n < 0 else "HARLAN — no change"))

func _chapter3() -> void:
	N.c3_card = {"type": "card", "chapter": 3, "bg": "yard:night", "next": "c3_split",
		"lines": func(s): return ["CALDER RAIL YARD", "SIGNAL TOWER 6", "WEDNESDAY, OCTOBER 15 — " + s.clock(3, 2)]}
	branch("c3_split", func(s): return "c3_standoff" if s.on("fled") else "c3_fire")

	scene("c3_fire", "yard:fire", func(s): return [
		["", "Signal tower six is a two-story brick box at the dead end of a siding, with its windows boarded up. There is light behind the boards, and it is flickering.", "wide"],
		["REYES", "That's not a lamp. That's a fire."],
		["", "Thick smoke is pouring out from under the door. You are very late." if s.late >= 2 else "A thin line of smoke is coming out from under the door.", "tower"],
	], "c3_fire_qte")

	N.c3_fire_qte = {"type": "qte", "bg": "yard:inside", "title": "TOWER SIX", "track": "rescue",
		"scale": func(s): return 0.85 if s.late >= 2 else 1.0,
		"steps": [
			hold("TURN THE KEY", 900, "A padlocked steel door. Use the brass key."),
			press("S", "GET LOW", "Heat and smoke roll out at you."),
			mash("UP THE STAIRS", 10, "Someone is coughing upstairs."),
			press("A", "DODGE", "A ceiling beam falls.", 1400),
			hold("CUT THE TIES", 1200, "Tessa. Zip-tied to a pipe."),
			mash("KICK OUT THE BOARDS", 12, "The stairs are burning. Use the window.", 3400),
			press("W", "LOWER HER DOWN", "Reyes is below, arms out."),
			press("D", "JUMP", "Now you.", 1400),
		],
		"do": func(s, r):
			s.f.tessa = "safe" if r.fails <= 1 else "hurt"
			s.mark("tessa_" + s.f.tessa),
		"next": "c3_after"}

	scene("c3_standoff", "yard:standoff", [
		["", "Signal tower six. Twenty feet up, on the outside walkway, a man is holding a smaller figure against the railing in front of him.", "wide"],
		["HARLAN", "STAY DOWN THERE! I didn't hurt her! Tessa, tell them I didn't hurt you!"],
		["", "He is holding a box cutter. He doesn't seem to remember that it is in his hand.", "HARLAN"],
		["REYES", "(quietly) I can't shoot without hitting her. You have to talk him down."],
	], "c3_s1", func(s): s.f.calm = 0)

	choice("c3_s1", "You have three chances to calm him down. What do you say first?", 12, [
		opt("HIS NAME", "Wade. Look at me, not at her.", "c3_s2", func(s): _calm(s, 1)),
		opt("ORDER", "Drop the blade! Now!", "c3_s2", func(s): _calm(s, -1)),
		opt("TO TESSA", "Tessa, I'm Nadia. I've got you.", "c3_s2", func(s):
			_calm(s, 0)
			s.f.spoke = true),
	], {"next": "c3_s2", "do": func(s): _calm(s, -1)})

	choice("c3_s2", "HARLAN: \"She sees me now. She never saw me before. Nobody ever does.\"", 12, [
		opt("THE CARDS", "She kept every card you wrote her.", "c3_s3", func(s): _calm(s, 2), func(s): return s.has("notes"), "Requires: index cards"),
		opt("THE TRUTH", "She saw you. She was afraid of you.", "c3_s3", func(s): _calm(s, 1)),
		opt("PROMISE", "Come down and people will hear your side.", "c3_s3", func(s): _calm(s, 1)),
	], {"next": "c3_s3", "do": func(s): _calm(s, -1)})

	choice("c3_s3", "Police sirens in the distance. Harlan hears them and tightens his grip on her.", 12, [
		opt("STEP BACK", "Put your gun away. Show your hands.", "c3_s_gate", func(s): _calm(s, 1)),
		opt("CLIMB", "Go up the ladder while he is distracted.", "c3_s_gate", func(s): _calm(s, -2)),
		opt("TRADE", "Let her go, and you and I will talk.", "c3_s_gate", func(s): _calm(s, 1)),
	], {"next": "c3_s_gate", "do": func(s): _calm(s, -1)})

	branch("c3_s_gate", func(s): return "c3_surrender" if s.num("calm") >= 3 else "c3_lunge")

	scene("c3_surrender", "yard:standoff", [
		["", "His arm drops. The box cutter falls twenty feet into the gravel.", "HARLAN"],
		["", "Tessa walks to the ladder. Halfway there, she starts to run.", "wide"],
		["HARLAN", "I just wanted more time with her."],
		["REYES", "You're about to have plenty of time."],
	], "c3_after", func(s):
		s.f.caught = true
		s.f.tessa = "safe"
		s.mark("tessa_safe")
		s.add(12)
		s.say("ARREST — caught at the scene with the victim"))

	scene("c3_lunge", "yard:standoff", [["", "You haven't calmed him. He raises the blade.", "HARLAN"]], "c3_lunge_qte")

	N.c3_lunge_qte = {"type": "qte", "bg": "yard:standoff", "title": "THE WALKWAY", "track": "walkway",
		"steps": [
			mash("CLIMB", 9, "Up the ladder. Fast.", 3000),
			press("A", "DUCK THE BLADE", "He swings at you.", 1300),
			hold("PIN HIS WRIST", 1100, "You catch his arm."),
			press("D", "PULL HER CLEAR", "Tessa is at the edge.", 1300),
			press("W", "DRIVE HIM DOWN", "He comes at you again.", 1300),
		],
		"do": func(s, r):
			s.f.tessa = "safe" if r.fails <= 1 else "hurt"
			s.mark("tessa_" + s.f.tessa)
			if r.fails >= 3:
				s.f.harlanDead = true
				s.mark("harlan_dead")
			else:
				s.f.caught = true
				s.add(12),
		"next": "c3_after"}

	branch("c3_after", func(s): return "c3_after_safe" if s.f.get("tessa") == "safe" else "c3_after_hurt")

	scene("c3_after_safe", "yard:dawn", [
		["", "Tessa Brandt sits on the back step of an ambulance, wrapped in a foil blanket, holding a paper cup with both hands.", "TESSA"],
		["TESSA", "I reported it. To the campus. To you."],
		["TESSA", "I did everything you're supposed to do."],
	], "c3_bond")

	choice("c3_bond", "She is watching to see how you answer. What do you say to her?", 14, [
		opt("I KNOW", "You did everything right. We failed you.", "c3_wrap", func(s):
			s.f.bond = true
			s.say("TESSA — trusts you")),
		opt("STATEMENT", "I need your statement while it's fresh.", "c3_wrap", func(s):
			s.add(3)
			s.say("TESSA — went quiet")),
		opt("REST", "You don't have to talk tonight.", "c3_wrap", func(s):
			s.f.bond = true
			s.say("TESSA — trusts you")),
	], {"next": "c3_wrap"})

	scene("c3_after_hurt", "yard:dawn_hurt", [
		["", "Paramedics load Tessa Brandt into the ambulance on a stretcher, with an oxygen mask over her face. She looks at you for a second before the doors close.", "ambulance"],
		["", "She is alive. The paramedic will not promise anything more than that."],
	], "c3_wrap")

	scene("c3_wrap", "yard:dawn", func(s): return [
		["", "Across the yard, below the walkway, Wade Harlan's body lies under a tarp. He went over the railing in the struggle.", "tower"] if s.on("harlanDead") else null,
		["REYES", "They want to X-ray my ankle. I told them I walked in here and I can walk out."] if s.on("reyesHurt") else null,
		["REYES", "Hey. Good work tonight, partner."] if s.trust >= 2 else ["REYES", "We need to talk about how tonight went. Not now. But soon."],
		["", "The sun comes up over the rail yard.", "sunrise"],
	], "c3_end")

	# wrong-man route: nobody was looking for her
	N.c3w_card = {"type": "card", "chapter": 3, "bg": "yard:aftermath", "next": "c3w_scene",
		"lines": ["CALDER RAIL YARD", "SIGNAL TOWER 6", "WEDNESDAY, OCTOBER 15 — 6:20 AM"]}

	scene("c3w_scene", "yard:aftermath", [
		["", "At 5:52 AM a rail yard crew reports a fire in an old signal tower. By the time you arrive, firefighters have broken the door down.", "wide"],
		["", "Two of them carry a young woman out of the smoke. She is wearing one white sneaker. There are zip-tie marks on both wrists.", "ambulance"],
		["REYES", "That's Tessa. She was in there all night, while we had —"],
		["", "He can't finish the sentence. A paramedic lifts her oxygen mask for a moment, and Tessa Brandt says one word."],
		["TESSA", "Wade.", "ambulance"],
	], "c3w_after", func(s):
		s.f.tessa = "hurt"
		s.mark("tessa_hurt"))

	scene("c3w_after", "yard:aftermath", [
		["", "You arrested the wrong man. Evan Kessler is released at 7:15 AM, and his family hires a lawyer by noon.", "sunrise"],
		["REYES", "Wade Harlan. Library maintenance. Kessler told us about the van."],
		["REYES", "We didn't check."],
		["", "Harlan's van is found empty at the library. His apartment has been cleared out. His photo goes to every police station, toll booth and bus terminal in the state."],
	], "c3w_term_card")

	N.c3w_term_card = {"type": "card", "bg": "terminal:gate", "next": "c3w_term",
		"lines": ["PORT CALDER BUS TERMINAL", "GATE 14", "SATURDAY, OCTOBER 18 — 5:44 AM"]}

	scene("c3w_term", "terminal:gate", [
		["", "Three days later, a ticket clerk recognizes the photo. A man in a gray shirt with a duffel bag, holding a one-way ticket north. He is fourth in line at Gate 14.", "wide"],
		["REYES", "That's him. No van to hide in this time."],
		["", "Harlan looks up from his ticket and sees you.", "HARLAN"],
	], "c3w_qte")

	N.c3w_qte = {"type": "qte", "bg": "terminal:gate", "title": "GATE 14", "track": "gate",
		"steps": [
			press("A", "DODGE", "He swings the duffel bag at you.", 1400),
			mash("THROUGH THE CROWD", 10, "He shoves through the line."),
			press("W", "JUMP THE BENCHES", "A row of seats is in your way.", 1400),
			press("S", "SLIDE UNDER", "A luggage cart rolls at you.", 1400),
			hold("TAKE HIM DOWN", 1100, "He is on the bus steps."),
		],
		"do": func(s, r):
			if r.fails <= 1:
				s.f.caught = true
				s.f.warrant = true
			else:
				s.f.fugitive = true,
		"next": func(s, r): return "c3w_caught" if r.fails <= 1 else "c3w_gone"}

	scene("c3w_caught", "terminal:gate", [
		["", "You pull him off the bottom step of the bus and put him on the floor.", "wide"],
		["HARLAN", "She was fine. I left the heater on for her."],
		["REYES", "That heater burned the place down, Wade. She's been on oxygen for three days."],
	], "c3_end")

	scene("c3w_gone", "terminal:gate", [
		["", "The bus doors close before you reach them. It pulls out with Wade Harlan at the back window, watching you.", "bus"],
		["", "State police stop the bus forty miles north. He is no longer on it."],
	], "c3_end")

	N.c3_end = {"type": "chapterEnd", "chapter": 3, "next": "c3_out"}
	branch("c3_out", func(s): return "end_dead" if s.on("harlanDead") else ("end_fugitive" if s.on("fugitive") else "c4_card"))

# ───────────── CHAPTER 4 — THE PEOPLE ─────────────

func _chapter4() -> void:
	N.c4_card = {"type": "card", "chapter": 4, "bg": "courthouse:office", "next": "c4_office",
		"lines": ["CALDER COUNTY COURTHOUSE", "OFFICE OF THE DISTRICT ATTORNEY", "THREE MONTHS LATER", "— YOU NOW PLAY PROSECUTOR IMANI COLE —"]}

	scene("c4_office", "courthouse:office", func(s): return [
		["", "You are Assistant District Attorney Imani Cole. The Harlan file covers your desk in three stacks: what you can use, what you might lose, and what you wish weren't true. Detective Okonkwo is in the chair across from you.", "wide"],
		["COLE", "I've read it twice. Want to hear it the way Dana Pruitt will read it? Stop me when I'm unfair."],
		["COLE", "You booked Evan Kessler first. Pruitt will put his booking photo in front of the jury and say: \"The police were certain once before.\""] if s.on("wrong") else null,
		["COLE", "The van was searched three days late, with a warrant, after he had cleaned it out. What I have is her word, the tower, and the key."] if s.on("wrong") else (
			["COLE", "You waited for the warrant. Thirty minutes, with a girl missing. I know what that cost. It means everything in that van is mine to use."] if s.on("warrant")
			else ["COLE", "You opened the van without a warrant, with a judge half an hour away. Pruitt has already filed to throw out everything you found in it."]),
		["COLE", "And the locker came with it. The camera. The memory cards. Two months of her window."] if s.has("locker") else null,
		["COLE", "He confessed. On video, after his rights, in his own words. Best thing in this file."] if s.on("confession") else null,
		["COLE", "You told him the van's GPS had already led you to her. It hadn't."] if s.on("confession") and s.on("bluffed") else null,
		["OKONKWO", "No. It hadn't."] if s.on("confession") and s.on("bluffed") else null,
		["COLE", "You can lie to him about what you know. You can't threaten him, and you can't promise him anything. Pruitt will say you did both. I watched the tape. You didn't."] if s.on("confession") and s.on("bluffed") else null,
		["COLE", "He asked for a lawyer. You asked if he meant it. He did, and you stopped. Then he kept talking. I wish every file read like that."] if s.on("clarified") else null,
		["COLE", "And then he asks for a lawyer, on video, and you keep going. Nadia."] if s.on("pushed") else null,
		["OKONKWO", "I would do it again."] if s.on("pushed") else null,
		["COLE", "I know. Now I get to explain it to a judge."] if s.on("pushed") else null,
	], "c4_charges")

	choice("c4_charges", "The grand jury sits tomorrow. What do you ask them to indict Wade Harlan for?", 18, [
		opt("EVERYTHING", "Kidnapping, stalking and unlawful surveillance.", "c4_ch_all"),
		opt("WHAT YOU CAN PROVE", "Kidnapping and stalking. Nothing you'd have to stretch for.", "c4_ch_core"),
	], {"next": "c4_ch_core"})

	scene("c4_ch_all", "courthouse:office", func(s): return [
		["COLE", "Kidnapping in the first degree. Stalking. Unlawful surveillance."],
		["OKONKWO", "The surveillance count. That's the camera?"],
	] + ([
		["COLE", "And I can put the camera in his locker, with her window on the memory cards." if s.has("locker") else "And you found where it was mounted. Cut zip ties, a clean patch in the rust, aimed at her bed."],
		["COLE", "So the jury meets him two months before the van. He watched her sleep. He doesn't get to say he only wanted to talk."],
	] if (s.has("locker") or s.has("window")) else [
		["COLE", "Which nobody found. No camera. No mount. I'm charging it on her word that she felt watched."],
		["", "It is the count Pruitt will spend the most time on. If they guessed about this, she'll say, what else did they guess about?"],
	]), "c4_gate1", func(s):
		s.f.chargedAll = true
		if s.has("locker") or s.has("window"):
			s.add(5)
			s.say("INDICTMENT — three counts, all supported")
		else:
			s.add(-4)
			s.say("INDICTMENT — the surveillance count is thin"))

	scene("c4_ch_core", "courthouse:office", [
		["COLE", "Kidnapping one. Stalking. Unlawful imprisonment if the jury won't go all the way."],
		["COLE", "Short indictment. Every count, I can prove twice."],
	], "c4_gate1", func(s):
		s.add(2)
		s.say("INDICTMENT — two counts, both solid"))

	branch("c4_gate1", func(s): return "c4_supp_warrant" if not s.on("warrant") else "c4_gate2")

	scene("c4_supp_warrant", "courthouse:hearing", [
		["JUDGE", "On the record. People against Harlan. Defense motion to suppress.", "bench"],
		["JUDGE", "Ms. Pruitt."],
		["PRUITT", "Your Honor, a warrant was thirty minutes away. Their own captain told them to wait."],
		["PRUITT", "Detective Okonkwo said \"bad signal\" and opened my client's van."],
		["PRUITT", "The Fourth Amendment is not a suggestion. The sneaker, the tape, the blanket. All of it goes."],
		["JUDGE", "Ms. Cole. Your burden. Why was that search lawful?"],
	], "c4_supp_warrant_c")

	choice("c4_supp_warrant_c", "The van was searched without a warrant. Which exception do you argue?", 20, [
		opt("EMERGENCY", "A life was in danger. Works only if the detectives had solid facts before the doors opened.", "c4_exig"),
		opt("VEHICLE", "A van can drive away. Works only if something tied her to that van or that door.", "c4_auto"),
		opt("INEVITABLE", "The warrant was already coming. Safe, but it admits the search was wrong.", "c4_inev"),
	], {"next": "c4_supp_lost"})

	branch("c4_exig", func(s): return "c4_exig_win" if s.pre_van() >= 3 else "c4_supp_lost")
	scene("c4_exig_win", "courthouse:hearing", [
		["COLE", "They weren't guessing, Your Honor. They had her messages, her schedule, and the last place anyone saw her."],
		["COLE", "They believed she was in that van and running out of air."],
		["PRUITT", "And she wasn't in it."],
		["COLE", "The question is what they believed at the door. Not what was behind it."],
		["JUDGE", "It is. A missing young woman, and the vehicle she was last seen near.", "bench"],
		["JUDGE", "That's an emergency. The law doesn't make officers wait outside one. Denied."],
	], "c4_gate2", func(s):
		s.mark("supp_won")
		s.say("RULING — the van evidence stays in"))

	branch("c4_auto", func(s): return "c4_auto_win" if (s.has("receipt") or s.has("witness")) else "c4_supp_lost")
	scene("c4_auto_win", "courthouse:hearing", func(s): return [
		["COLE", "It's a vehicle, Your Honor. At a loading dock, keys somewhere in the building."],
		["COLE", "A witness watched Tessa Brandt get into that van." if s.has("witness") else "She called a ride to that door. It was cancelled two minutes later. The only vehicle there was his."],
		["COLE", "That's probable cause. For a vehicle, the law hasn't asked for a warrant in a hundred years."],
		["JUDGE", "A vehicle that can drive away, and probable cause tied to it.", "bench"],
		["JUDGE", "Ms. Pruitt, a van is not a bedroom. Denied."],
	], "c4_gate2", func(s):
		s.mark("supp_won")
		s.say("RULING — the van evidence stays in"))

	scene("c4_inev", "courthouse:hearing", [
		["COLE", "The warrant was already in front of Judge Feld. It was granted."],
		["COLE", "Thirty minutes later they open that van lawfully and find exactly the same things."],
		["PRUITT", "\"We would have done it right.\" Everybody says that after doing it wrong."],
		["JUDGE", "They do. But the application was real, it was pending, and it was signed.", "bench"],
		["JUDGE", "I'll allow it. Barely."],
		["JUDGE", "Ms. Cole. Tell your detectives \"bad signal\" is not a doctrine."],
	], "c4_gate2", func(s):
		s.add(-5)
		s.say("RULING — evidence stays in, but the judge is unhappy"))

	scene("c4_supp_lost", "courthouse:hearing", [
		["JUDGE", "A hunch is not an emergency, Ms. Cole. It isn't probable cause either.", "bench"],
		["JUDGE", "They knew she worked in that building. Nothing pointed at that van."],
		["JUDGE", "Granted. The sneaker, the tape and the blanket are out."],
	], "c4_gate2", func(s):
		s.add(-15)
		s.f.suppVan = true
		s.say("RULING — the van evidence is thrown out"))

	branch("c4_gate2", func(s): return "c4_supp_stmt" if s.on("pushed") else ("c4_vol" if s.on("confession") and s.on("bluffed") else ("c4_clar" if s.on("clarified") else "c4_plea")))

	scene("c4_vol", "courthouse:hearing", [
		["PRUITT", "She lied to him, Your Honor. She said a GPS had already found the girl. The confession came out of that lie."],
		["COLE", "A lie about the evidence isn't coercion. No threat. No promise. Rights read, rights waived, all of it on tape."],
		["JUDGE", "Police may lie about what they know. They may not break a man's will.", "bench"],
		["JUDGE", "I watched the tape twice. Nobody broke Mr. Harlan. Denied."],
	], "c4_plea", func(s): s.say("RULING — the confession stays in"))

	scene("c4_clar", "courthouse:hearing", [
		["PRUITT", "My client asked for a lawyer. Everything after that goes. Including the tank."],
		["COLE", "Everything they asked after that, yes. They asked nothing. He said it to the table."],
		["JUDGE", "He asked for a lawyer. The questions stopped.", "bench"],
		["JUDGE", "The rule protects him from the police. Not from himself. Denied."],
	], "c4_plea", func(s): s.say("RULING — the volunteered remark stays in"))

	scene("c4_supp_stmt", "courthouse:hearing", [
		["JUDGE", "That leaves the statement. He asked for a lawyer, on camera. The detective kept going.", "bench"],
		["PRUITT", "\"Forget the lawyer,\" Your Honor. Her words. I have nothing to add."],
	], "c4_supp_stmt_c")

	choice("c4_supp_stmt_c", "He asked for a lawyer and was questioned anyway. How do you handle it?", 18, [
		opt("RESCUE", "Argue it: one narrow question, asked to save a life. The judge will weigh how these detectives behaved all night.", "c4_stmt_ps"),
		opt("GIVE IT UP", "Withdraw the statement yourself and keep the court's trust.", "c4_stmt_con"),
	], {"next": "c4_stmt_ps"})

	branch("c4_stmt_ps", func(s): return "c4_stmt_win" if s.on("warrant") else "c4_stmt_lost")

	scene("c4_stmt_win", "courthouse:hearing", [
		["COLE", "She wasn't building a case in that room, Your Honor. She asked one question."],
		["COLE", "Where is she. Not why. Not how."],
		["COLE", "A girl was tied up somewhere, and it was getting colder."],
		["COLE", "These detectives stood outside a van for thirty minutes waiting on a signature. They don't cut corners."],
		["JUDGE", "No, they don't. That's the only reason I'm listening.", "bench"],
		["JUDGE", "With a life at stake, an officer may ask the question that saves it. One question."],
		["JUDGE", "The answer comes in."],
		["JUDGE", "Don't make it a habit."],
	], "c4_plea", func(s):
		s.mark("stmt_won")
		s.add(4)
		s.say("RULING — rescue exception; the statement stays in"))

	scene("c4_stmt_lost", "courthouse:hearing", func(s): return [
		["COLE", "She wasn't building a case, Your Honor. She was trying to find a girl in time."],
		["JUDGE", "She nearly didn't. But this detective hung up on a warrant an hour earlier. It can't be an emergency every time the rules get in her way." if s.f.get("tessa") == "hurt"
			else "This is the same detective who hung up on a warrant an hour earlier. I cannot call it an emergency every time the rules are inconvenient to her.", "bench"],
		["JUDGE", "The statement is out."],
		["JUDGE", "What they found at the tower stays in. You lose the statement, Ms. Cole. Not the girl."],
	], "c4_plea", func(s): s.add(-10))

	scene("c4_stmt_con", "courthouse:hearing", [
		["COLE", "The People withdraw the statement, Your Honor. I won't defend how we got it."],
		["JUDGE", "Thank you, Ms. Cole. I don't hear that often enough. The evidence from the tower stands.", "bench"],
	], "c4_plea", func(s):
		s.add(-8)
		s.f.candor = true
		s.say("CANDOR — the court will remember this at trial"))

	scene("c4_plea", "courthouse:plea", func(s): return [
		["", "Dana Pruitt comes to your office instead of calling. She doesn't sit down.", "PRUITT"],
		["PRUITT", "Fifteen years. Kidnapping two. You drop the rest."],
		["PRUITT", "And Tessa Brandt never sees the inside of a courtroom."],
		["", "Your case is strong. You would probably win at trial, and Pruitt knows it." if s.strength >= 55
			else ("Your case could go either way at trial." if s.strength >= 35 else "Your case is weak. A trial would be a real risk.")],
		["", "You call Tessa before you answer. The statute says the victim is consulted. You would have called anyway.", "desk"] if s.f.get("tessa") == "safe" else
			["", "You call the Brandts before you answer. Tessa's mother picks up. \"She isn't ready to talk about him. Whatever you do, don't make her sit in a room with that man.\"", "desk"],
		(["TESSA", "(on the phone) Do I get a say? ...Then I want him to have to hear it. All of it. But I'll understand if you take the deal."] if s.on("bond")
			else ["TESSA", "(on the phone) I just want it to be over. Whatever makes it be over."]) if s.f.get("tessa") == "safe" else null,
	], "c4_plea_c")

	choice("c4_plea_c", "Fifteen years is on the table. Pruitt is waiting.", 18, [
		opt("TAKE THE DEAL", "Fifteen years, guaranteed.", "end_plea"),
		opt("COUNTER", "Twenty, and he pleads to the stalking. She'll only say yes if your case scares her.", "c4_counter"),
		opt("GO TO TRIAL", "Risk it for the full sentence.", "c4_trial"),
	], {"next": "end_plea"})

	branch("c4_counter", func(s): return "c4_counter_yes" if s.strength >= 55 else "c4_counter_no")
	scene("c4_counter_yes", "courthouse:plea", [
		["COLE", "Twenty. Kidnapping and stalking, and he says what he did out loud, in open court."],
		["PRUITT", "...I've read your file too. Twenty. He signs tonight."],
	], "end_plea20")
	scene("c4_counter_no", "courthouse:plea", [
		["COLE", "Twenty. Kidnapping and stalking, and he says what he did out loud, in open court."],
		["PRUITT", "With this file? I'll take twelve strangers. Offer's withdrawn. See you at trial."],
	], "c4_trial", func(s): s.say("OFFER WITHDRAWN — the case goes to trial"))

	scene("c4_trial", "courthouse:trial", [
		["", "People against Harlan, Part 31. Dana Pruitt's opening statement is eleven minutes long and uses the word \"lonely\" nine times.", "wide"],
		["", "After two days, the jury sees Wade Harlan as a tired, harmless-looking man in a borrowed jacket.", "HARLAN"],
	], "c4_front_gate")

	branch("c4_front_gate", func(s): return "c4_front" if s.bad_facts() > 0 else "c4_clean")

	choice("c4_front", "Okonkwo testifies tomorrow, and there are things in her night that the jury won't like. Do you bring them out yourself?", 16, [
		opt("DRAW THE STING", "Ask her about them on direct, in her own words.", "c4_front_yes"),
		opt("LEAVE IT", "Don't hand Pruitt her cross. Maybe she won't go there.", "c4_front_no"),
	], {"next": "c4_front_no"})

	scene("c4_front_yes", "courthouse:trial", func(s): return [
		["COLE", "Detective, did you arrest someone else for this crime first?" if s.on("wrong") else ("Detective, did you have a warrant when you opened that van?" if not s.on("warrant") else "Detective, did Mr. Harlan ask for a lawyer before he told you where she was?")],
		["OKONKWO", "Yes. Evan Kessler. He ran, and I was sure. I was wrong. She spent the night in that tower because of it." if s.on("wrong")
			else ("No. I had a judge thirty minutes away and a girl I couldn't find. I made the call. I'd want the jury to hear that from me." if not s.on("warrant")
			else "Yes. And I asked him anyway. One question. I'd ask it again."), "OKONKWO"],
		["", "By the time Pruitt stands up, there is nothing left for her to reveal.", "jury"],
	], "c4_witness", func(s):
		s.f.fronted = true
		s.add(5)
		s.say("JURY — heard the bad news from you first"))

	scene("c4_front_no", "courthouse:trial", func(s): return [
		["PRUITT", "Detective. Before my client, you arrested Evan Kessler for this. You were certain then, too?" if s.on("wrong")
			else ("\"Bad signal,\" Detective. Was that true?" if not s.on("warrant") else "He said the word \"lawyer,\" Detective. What did you say next?")],
		["OKONKWO", "...Yes." if s.on("wrong") else ("No." if not s.on("warrant") else "\"Forget the lawyer.\""), "OKONKWO"],
		["", "Twelve jurors write the same thing down, and then look at you to see why you didn't tell them.", "jury"],
	], "c4_witness", func(s):
		s.add(-6)
		s.say("JURY — heard it from the defense"))

	scene("c4_clean", "courthouse:trial", [
		["", "Okonkwo's direct testimony takes two hours. Pruitt's cross takes fifteen minutes. There is very little in that night for her to hold on to.", "OKONKWO"],
	], "c4_witness", func(s): s.add(3))

	choice("c4_witness", "Tessa is on your witness list. Her testimony could win the case, but it would force her to relive it ten feet from him.", 16, [
		opt("CALL TESSA", "Ask her to testify.", "c4_call"),
		opt("PROTECT HER", "Try to win without her.", "c4_protect"),
	], {"next": "c4_protect"})

	scene("c4_call", "courthouse:tessa", func(s): return [
		["TESSA", "A detective told me I did everything right."],
		["TESSA", "So I'm going to do this right, too."],
		["", "She testifies for fifty minutes and looks at Harlan exactly once. After that, the jury no longer sees a harmless man.", "jury"],
	] if s.on("bond") else [
		["", "She gets through her testimony, but only just. She has no reason to trust the people who are asking her to do this.", "TESSA"],
		["", "You are not sure you should have asked her."],
	], "c4_obj1t", func(s):
		s.f.called = true
		s.add(15 if s.on("bond") else 7))

	scene("c4_protect", "courthouse:trial", [
		["", "You build the case from documents, timestamps and a brass key. It is solid, but the jury never hears from the victim herself. Priya Nair takes the stand in her place.", "wide"],
	], "c4_obj1p")

	# cross-examination: object, and on the right ground
	scene("c4_obj1t", "courthouse:tessa", [
		["PRUITT", "You kept his cards, Ms. Brandt. Every one. With dried flowers on top. You liked the attention, didn't you?"],
	], "c4_obj1t_c")
	choice("c4_obj1t_c", "Tessa is looking at you. Object? On what ground?", 9, [
		opt("LEADING", "She's putting words in the witness's mouth.", "c4_obj_bad_lead"),
		opt("ARGUMENTATIVE", "That isn't a question. It's an accusation.", "c4_obj_good1"),
		opt("HEARSAY", "The cards are out-of-court statements.", "c4_obj_bad1"),
	], {"next": "c4_obj_none1"})

	scene("c4_obj1p", "courthouse:trial", [
		["PRUITT", "Ms. Nair, your roommate kept his cards. Every one. With dried flowers on top. She liked the attention, didn't she?"],
	], "c4_obj1p_c")
	choice("c4_obj1p_c", "Priya is looking at you. Object? On what ground?", 9, [
		opt("LEADING", "She's putting words in the witness's mouth.", "c4_obj_bad_lead"),
		opt("SPECULATION", "Priya can't testify to what Tessa felt.", "c4_obj_good1"),
		opt("HEARSAY", "The cards are out-of-court statements.", "c4_obj_bad1"),
	], {"next": "c4_obj_none1"})

	scene("c4_obj_good1", "courthouse:trial", [
		["JUDGE", "Sustained. Ask a question or sit down, Ms. Pruitt. The jury will disregard.", "bench"],
	], "c4_obj2", func(s):
		s.add(4)
		s.say("SUSTAINED"))
	scene("c4_obj_bad_lead", "courthouse:trial", [
		["JUDGE", "Overruled. It's cross, Ms. Cole. She can lead.", "bench"],
		["", "The witness has to answer. It takes her a long time."],
	], "c4_obj2", func(s):
		s.add(-2)
		s.say("OVERRULED"))
	scene("c4_obj_bad1", "courthouse:trial", [
		["JUDGE", "Overruled. The cards are your own exhibit, Ms. Cole.", "bench"],
		["", "The witness has to answer. It takes her a long time."],
	], "c4_obj2", func(s):
		s.add(-2)
		s.say("OVERRULED"))
	scene("c4_obj_none1", "courthouse:trial", [
		["", "You stay in your chair. The question hangs in the room until the witness, alone, finds an answer to it.", "jury"],
	], "c4_obj2", func(s): s.add(-3))

	scene("c4_obj2", "courthouse:okonkwo", [
		["", "Okonkwo is recalled. Pruitt doesn't use her notes.", "OKONKWO"],
		["PRUITT", "Detective, your own report. The roommate said Tessa \"thought it would go away if she ignored him.\" So she wasn't afraid of him. Was she?"],
	], "c4_obj2_c")
	choice("c4_obj2_c", "Pruitt is reading someone else's words to a third person. Object?", 9, [
		opt("RELEVANCE", "What Tessa thought doesn't matter.", "c4_obj2_bad"),
		opt("HEARSAY", "The detective can't testify to what Priya said Tessa thought.", "c4_obj2_good"),
		opt("BADGERING", "She's harassing the witness.", "c4_obj2_bad"),
	], {"next": "c4_obj2_none"})
	scene("c4_obj2_good", "courthouse:okonkwo", [
		["JUDGE", "Sustained. That's hearsay twice over, Ms. Pruitt.", "bench"],
	], "c4_obj3", func(s):
		s.add(4)
		s.say("SUSTAINED"))
	scene("c4_obj2_bad", "courthouse:okonkwo", [
		["JUDGE", "Overruled. Her state of mind is the issue, and counsel has been civil.", "bench"],
		["OKONKWO", "That is what the roommate said, yes."],
	], "c4_obj3", func(s):
		s.add(-2)
		s.say("OVERRULED"))
	scene("c4_obj2_none", "courthouse:okonkwo", [
		["OKONKWO", "That is what the roommate said, yes."],
		["", "Pruitt lets the answer sit, and nods as if it settles something.", "PRUITT"],
	], "c4_obj3", func(s): s.add(-3))

	scene("c4_obj3", "courthouse:okonkwo", [
		["PRUITT", "Three weeks before this, a frightened girl sat at your desk, and you sent her home. You're not here for the truth, Detective. You're here because you feel guilty. Isn't that so?"],
	], "c4_obj3_c")
	choice("c4_obj3_c", "Okonkwo hasn't looked away from Pruitt. She isn't asking you for help.", 9, [
		opt("OBJECT", "Argumentative. Get her out from under it.", "c4_obj3_obj"),
		opt("LET HER ANSWER", "Stay seated. Trust your witness.", "c4_obj3_let"),
		opt("RELEVANCE", "Her feelings aren't evidence.", "c4_obj3_bad"),
	], {"next": "c4_obj3_let"})
	scene("c4_obj3_obj", "courthouse:okonkwo", [
		["JUDGE", "Sustained. Rephrase.", "bench"],
		["", "Pruitt rephrases. The jury watched you step in front of your own detective, and they noticed.", "jury"],
	], "c4_closing", func(s): s.add(1))
	scene("c4_obj3_let", "courthouse:okonkwo", [
		["OKONKWO", "Yes. I feel guilty. I told her there was nothing we could do, and I was wrong."],
		["OKONKWO", "That's why I counted every card. Guilt didn't put her shoe in his van. He did."],
		["", "Pruitt has no further questions.", "PRUITT"],
	], "c4_closing", func(s):
		s.add(6)
		s.say("JURY — believed her"))
	scene("c4_obj3_bad", "courthouse:okonkwo", [
		["JUDGE", "Overruled. Bias is always relevant. The detective will answer.", "bench"],
		["OKONKWO", "...Yes. I feel guilty."],
		["", "Because you objected first, it sounds like something you were trying to hide.", "jury"],
	], "c4_closing", func(s):
		s.add(-2)
		s.say("OVERRULED"))

	choice("c4_closing", "Closing argument. You get one image to leave with the jury.", 16, [
		opt("HIS OWN WORDS", "The index cards, in his handwriting.", "c4_close_q", func(s): s.add(5), func(s): return s.has("notes"), "Requires: index cards"),
		opt("THE CLOCK", "9:14, 9:16, and every minute after.", "c4_close_q", func(s): s.add(4 if (s.has("receipt") or s.has("timecard")) else 1)),
		opt("THE HEATER", "\"I left the heater on for her.\"", "c4_close_q", func(s): s.add(4 if (s.on("confession") or s.on("clarified") or s.seen.has("stmt_won")) else 1)),
	], {"next": "c4_close_q"})

	N.c4_close_q = {"type": "qte", "bg": "courthouse:closing", "title": "CLOSING ARGUMENT", "track": "closing",
		"steps": [
			press("SPACE", "STAND", "\"Ms. Cole, your closing.\"", 1800),
			hold("LET THE SILENCE SIT", 1300, "Look at each of them before you speak."),
			press("SPACE", "SAY HER NAME", "\"Her name is Tessa Brandt.\"", 1600),
		],
		"do": func(s, r): s.add((3 - r.fails) * 3 + (5 if s.on("candor") else 0)),
		"next": "c4_verdict"}

	scene("c4_verdict", "courthouse:closing", func(s): return [
		["", "The jury is out for " + ("ninety minutes." if s.strength >= 70 else ("a day and a half." if s.strength >= 45 else "four days.")), "jury"],
		["JUDGE", "Madam Foreperson, has the jury reached a verdict?", "bench"],
	], func(s): return "end_guilty" if s.strength >= 70 else ("end_lesser" if s.strength >= 45 else "end_acquit"))

# ───────────── ENDINGS ─────────────

func _tessa_line(s: CaseState) -> String:
	if s.f.get("tessa") == "safe":
		return "Tessa Brandt transfers to a university four hundred miles away. In March, a postcard arrives at the 9th Precinct with one word on it: \"Leaving.\""
	return "Tessa Brandt spends eleven days in the hospital and the spring semester at home. She has not decided whether she will go back in the fall."

func _evan_line(s: CaseState) -> String:
	return " Evan Kessler sues the city for wrongful arrest. The city settles." if s.on("wrong") else ""

func _endings() -> void:
	N.end_plea = {"type": "ending", "bg": "courthouse:hearing", "title": "PLEA DEAL — FIFTEEN YEARS",
		"text": func(s): return "Wade Harlan stands, pleads guilty to kidnapping in the second degree, and is led out through a side door. The hearing takes nine minutes. " + _tessa_line(s) + _evan_line(s)}
	N.end_plea20 = {"type": "ending", "bg": "courthouse:hearing", "title": "PLEA DEAL — TWENTY YEARS",
		"text": func(s): return "The judge makes Wade Harlan say it himself: where he took her, how long he had watched her, and why. It takes him four minutes. Then he is led out through a side door. " + _tessa_line(s) + _evan_line(s)}
	N.end_guilty = {"type": "ending", "bg": "courthouse:closing", "title": "GUILTY — ALL COUNTS",
		"text": func(s): return "The jury finds Wade Harlan guilty on every count of the indictment. At sentencing, the judge reads Tessa's statement into the record herself, and gives him twenty-five years to life. " + _tessa_line(s) + _evan_line(s)}
	N.end_lesser = {"type": "ending", "bg": "courthouse:closing", "title": "GUILTY — LESSER CHARGE ONLY",
		"text": func(s): return "The jury is not convinced of kidnapping, and convicts only on unlawful imprisonment. Harlan is sentenced to four years and will be out in three. " + _tessa_line(s) + _evan_line(s)}
	N.end_acquit = {"type": "ending", "bg": "courthouse:closing", "title": "NOT GUILTY",
		"text": func(s): return "Too much of the evidence was thrown out or never found, and the jury has reasonable doubt. Wade Harlan walks out of the courtroom a free man. Okonkwo watches him go. " + _tessa_line(s) + _evan_line(s)}
	N.end_dead = {"type": "ending", "bg": "yard:dawn", "title": "CASE CLOSED — SUSPECT DECEASED",
		"text": func(s): return "There is no trial. A review board examines Harlan's death and clears you in a two-page report. Nobody will ever have to prove in court what he did. " + _tessa_line(s)}
	N.end_fugitive = {"type": "ending", "bg": "terminal:gate", "title": "OPEN CASE — SUSPECT AT LARGE",
		"text": func(s): return "Wade Harlan is never found. His photo stays on the wall of the 9th Precinct, and every few months a tip comes in from another college town. The night you spent on the wrong man was the night you could have caught the right one. " + _tessa_line(s) + _evan_line(s)}

# ───────────── FLOWCHARTS ─────────────

func _flow() -> void:
	FLOW = {
		1: {"title": "CHAPTER 1 — THE EMPTY APARTMENT", "rows": [
			[["clue_tablet", "The tablet"], ["clue_notes", "The index cards"], ["clue_receipt", "The receipt"], ["clue_window", "The fire escape"], ["clue_report", "The corkboard"], ["clue_ex", "The torn photo"]],
			[["c1_priya_soft", "Reassure Priya"], ["c1_priya_cards", "Show her the cards"], ["c1_priya_hard", "Press her"], ["c1_priya_silent", "Say nothing"]],
			[["c1_lead_good", "Follow the library"], ["c1_lead_ex", "Follow the ex"], ["c1_lead_slow", "No lead — an hour lost"]],
		]},
		2: {"title": "CHAPTER 2 — THE SERVICE ENTRANCE", "rows": [
			[["c2e_door", "Evan Kessler's door"], ["c2_call", "The loading dock"]],
			[["c2e_hand", "Test his handwriting"], ["c2e_believe", "Believe Kessler"], ["c2e_book", "Book the wrong man"]],
			[["c2_wait", "Wait for the warrant"], ["c2_go", "\"Bad signal\""]],
			[["clue_phone", "The dumpster"], ["clue_timecard", "The time clock"], ["clue_camera", "The dock camera"], ["clue_locker", "Locker 14"]],
			[["c2_caught", "Harlan in handcuffs"], ["c2_fled", "Harlan escapes"], ["reyes_hurt", "Reyes is injured"]],
			[["c2_confess", "Harlan confesses"], ["c2_stop", "Respect his rights"], ["c2_clarify", "Ask if he means it"], ["c2_push", "Keep pushing"]],
		]},
		3: {"title": "CHAPTER 3 — TOWER SIX", "rows": [
			[["c3_fire", "The tower is burning"], ["c3_standoff", "The walkway standoff"], ["c3w_scene", "Found by firefighters"]],
			[["c3_surrender", "Talked down"], ["c3_lunge", "He attacks"], ["c3w_caught", "Caught at Gate 14"], ["c3w_gone", "The bus leaves"]],
			[["tessa_safe", "Tessa walks out"], ["tessa_hurt", "Tessa hospitalized"], ["harlan_dead", "Harlan falls"]],
		]},
		4: {"title": "CHAPTER 4 — THE PEOPLE", "rows": [
			[["c4_ch_all", "Indict on everything"], ["c4_ch_core", "Indict on what you can prove"]],
			[["supp_won", "Van search upheld"], ["c4_inev", "Inevitable discovery"], ["c4_supp_lost", "Van evidence thrown out"]],
			[["c4_stmt_win", "Rescue exception"], ["c4_stmt_lost", "Statement suppressed"], ["c4_stmt_con", "Give up the statement"]],
			[["end_plea", "Take fifteen"], ["c4_counter_yes", "Counter: twenty"], ["c4_counter_no", "Offer withdrawn"], ["c4_trial", "Go to trial"]],
			[["c4_front_yes", "Draw the sting"], ["c4_front_no", "Leave it for cross"], ["c4_call", "Tessa testifies"], ["c4_protect", "Protect her"]],
			[["c4_obj_good1", "First objection sustained"], ["c4_obj2_good", "Hearsay sustained"], ["c4_obj3_let", "Let her answer"]],
			[["end_guilty", "Guilty, all counts"], ["end_lesser", "Lesser charge"], ["end_acquit", "Not guilty"], ["end_dead", "No trial"], ["end_fugitive", "Suspect at large"]],
		]},
	}
