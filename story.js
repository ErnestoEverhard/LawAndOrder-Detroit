/* DEAD SIGNAL — story data. Original characters and case.
   Pure data + small state functions so tools/validate.js can walk it without a browser. */
(function (root) {
  const N = {};
  const PRE_VAN = ['tablet', 'notes', 'receipt', 'window', 'report', 'name', 'witness'];

  const newState = notify => ({ clues: {}, f: {}, seen: {}, strength: 0, trust: 0, late: 0, chapter: 1, notify: notify || (() => {}) });
  const add = (s, n) => { s.strength = Math.max(0, Math.min(100, s.strength + n)); };
  const clue = (s, id, label, pts = 5) => {
    if (s.clues[id]) return;
    s.clues[id] = label; s.seen['clue_' + id] = 1; add(s, pts);
    s.notify('EVIDENCE LOGGED — ' + label);
  };
  const trust = (s, d, msg) => { s.trust += d; s.notify((d > 0 ? '▲ REYES — ' : '▼ REYES — ') + msg); };
  const preVan = s => PRE_VAN.filter(k => s.clues[k]).length;
  const lost = (s, n, why) => { s.late += n; s.notify('TIME LOST — ' + why); };
  /* every delay pushes the night's clock back 40 minutes */
  const clock = (s, h, m) => { const t = h * 60 + m + s.late * 40; return (Math.floor(t / 60) % 12 || 12) + ':' + String(t % 60).padStart(2, '0') + ' AM'; };
  const canLib = s => !!(s.clues.name || s.clues.notes || s.clues.receipt || s.clues.report);
  const canEx = s => !!(s.clues.tablet || s.clues.ex || s.f.evanName);

  const scene = (id, bg, beats, next, fx) => { N[id] = { type: 'scene', bg, beats, next, do: fx }; };
  const choice = (id, prompt, timer, options, timeout) => { N[id] = { type: 'choice', prompt, timer, options, timeout }; };

  /* ───────────── CHAPTER 1 — THE EMPTY APARTMENT ───────────── */
  N.c1_card = { type: 'card', chapter: 1, bg: 'apartment', next: 'c1_arrive',
    lines: ['APARTMENT OF TESSA BRANDT', '418 MERCER STREET, APT 3C', 'TUESDAY, OCTOBER 14 — 11:42 PM', '— YOU PLAY DETECTIVE NADIA OKONKWO —'] };

  scene('c1_arrive', 'apartment', [
    ['', 'You are Detective Nadia Okonkwo of the Special Victims Division, 9th Precinct. Your partner, Detective Sam Reyes, is waiting for you outside apartment 3C.'],
    ['REYES', 'The roommate called 911 around ten. Tessa Brandt, nineteen, a sophomore at Hollis University. She never came home from work and she isn\'t answering her phone.'],
    ['REYES', 'Normally a missing adult waits until morning. But the patrol officer ran her name and it came back flagged: an open stalking complaint. That\'s why they called us.'],
    ['OKONKWO', 'I know. I took that complaint myself. Three weeks ago she showed me dozens of texts from a number she didn\'t recognize.'],
    ['OKONKWO', 'There were no threats and no name. I told her there was nothing we could do yet, and to keep a record of everything.'],
    ['', 'The apartment door is open a few inches. No sign of forced entry. A lamp is still on inside.'],
    ['REYES', 'Crime scene unit is a few minutes out. Once they tape this room off, we\'re reading their reports instead of looking for ourselves.'],
    ['OKONKWO', 'Then we look now.'],
  ], 'c1_inv');

  N.c1_inv = { type: 'investigate', bg: 'apartment', plan: 'apartment', budget: 4, next: 'c1_priya',
    title: 'SEARCH THE APARTMENT',
    intro: 'Six things in this room are worth your attention. You have time to examine four before the crime scene unit seals it. Click a marker to examine it. Each piece of evidence you log raises Case Strength — how well this case will hold up in court.',
    outro: 'CRIME SCENE UNIT IS HERE — STEP OUT',
    hotspots: [
      { name: 'Tablet', x: 19, y: 17,
        text: 'Her tablet, showing her text messages. 73 unread, all from the unknown number in her complaint. It was a few dozen when she came to you. The most recent, 8:51 PM: "You looked tired today. I can help with that."',
        do: s => clue(s, 'tablet', '73 messages from an unsaved number') },
      { name: 'Bookshelf', x: 9, y: 58,
        text: 'A coffee can of dried flowers. Under it, a stack of index cards in careful block capitals. "I SAW YOU ON THE THIRD FLOOR." "SIT BY THE WINDOW AGAIN." She kept every one — the way you keep things you might need as proof.',
        do: s => clue(s, 'notes', 'Index cards — "sit by the window again"') },
      { name: 'Laptop', x: 77, y: 30,
        text: 'Open to a rideshare receipt. She ordered a ride home at 9:14 PM from the Hollis University Library service entrance. The ride was cancelled at 9:16, two minutes later. She never got home.',
        do: s => clue(s, 'receipt', 'Ride cancelled at library service entrance, 9:16 PM') },
      { name: 'Window', x: 96, y: 67,
        text: 'The fire-escape window. The latch is intact. Outside, behind a dead plant on the fire escape, two cut zip ties hang from the railing around a clean patch in the rust. Something small was strapped there, low and out of sight from inside, aimed at her window.',
        do: s => clue(s, 'window', 'Cut zip ties on the fire escape — a hidden camera was mounted there') },
      { name: 'Corkboard', x: 48, y: 5,
        text: 'Her class schedule and her work calendar. She works the closing shift at the library circulation desk on Tuesdays and Thursdays. Tonight is Tuesday. A sticky note in her handwriting: "ask Campus Safety AGAIN about my report."',
        do: s => clue(s, 'report', 'Worked closing shifts at the library; had filed a report') },
      { name: 'Wastebasket', x: 37, y: 30,
        text: 'A photo-booth strip, torn in half. Tessa\'s half is here; whoever sat beside her has been ripped away. On the back, in pen: "E + T" — with the E scratched out hard enough to tear the paper.',
        do: s => clue(s, 'ex', 'Torn photo strip — an ex, initial "E"') },
    ] };

  scene('c1_priya', 'hallway', [
    ['', 'The roommate, Priya Nair, is sitting on the hallway stairs with her knees pulled up, holding her phone in both hands in case it rings.'],
    ['PRIYA', 'She texts me when she leaves work. Every time. Just one word: "Leaving." Tonight there was nothing.'],
    ['REYES', 'Has anyone been bothering her? An ex, someone from class?'],
    ['PRIYA', 'I... no. I don\'t know. She would have told me.'],
  ], 'c1_priya_choice');

  choice('c1_priya_choice', 'Priya is staring at the floor. She knows something, and she thinks it isn\'t hers to tell.', 12, [
    { label: 'REASSURE', sub: 'You\'re not betraying her.', next: 'c1_priya_soft' },
    { label: 'THE CARDS', sub: 'Show her what Tessa kept.', req: s => s.clues.notes, lock: 'Requires: index cards', next: 'c1_priya_cards' },
    { label: 'PRESS', sub: 'Every minute matters. Talk.', next: 'c1_priya_hard' },
  ], { next: 'c1_priya_silent' });

  scene('c1_priya_soft', 'hallway', [
    ['OKONKWO', 'Priya. Whatever she asked you to keep quiet, she asked before tonight. She would want you to tell me now.'],
    ['PRIYA', 'Everyone thinks it\'s Evan — her ex. He texts her constantly. But Evan is just pathetic. He\'s not the one she was scared of.'],
    ['PRIYA', 'There\'s a maintenance man at the library. He shows up to fix things that aren\'t broken whenever she\'s on shift. She reported him in September, and Campus Safety said he hadn\'t actually done anything.'],
    ['PRIYA', 'Wade. His name is Wade.'],
  ], 'c1_lead', s => { s.f.evanName = true; clue(s, 'name', 'Roommate statement — "Wade", library maintenance'); trust(s, 1, 'liked how you handled her'); });

  scene('c1_priya_cards', 'hallway', [
    ['', 'You lay the index cards on the stair beside her, one at a time.'],
    ['PRIYA', 'Oh my god. She told me he\'d stopped.'],
    ['PRIYA', 'Wade. He does maintenance at the library, nights. She thought if she ignored him it would go away. She made me promise not to make a big deal of it.'],
  ], 'c1_lead', s => clue(s, 'name', 'Roommate statement — "Wade", library maintenance'));

  scene('c1_priya_hard', 'hallway', [
    ['OKONKWO', 'Every minute you spend protecting her privacy is a minute she is out there alone. Give me a name.'],
    ['PRIYA', 'Evan! Okay? Her ex-boyfriend, Evan Kessler. She blocked him in August and he just got a new number. Is that what you want?'],
    ['', 'She is crying now. Reyes steps between the two of you without making it obvious.'],
    ['REYES', 'That helps. Thank you, Priya.'],
  ], 'c1_lead', s => { s.f.evanName = true; s.notify('LEAD — Evan Kessler, ex-boyfriend'); trust(s, -1, 'thinks you pushed a witness too hard'); });

  scene('c1_priya_silent', 'hallway', [
    ['', 'You say nothing and wait for her to fill the silence. She doesn\'t.'],
    ['PRIYA', '...Can I go back inside? I want to be there if she calls.'],
  ], 'c1_lead');

  N.c1_lead = { type: 'branch', next: s => (canLib(s) || canEx(s)) ? 'c1_lead_talk' : 'c1_lead_slow' };

  scene('c1_lead_talk', 'hallway', s => [
    canEx(s) && ['REYES', 'An ex who won\'t let go. Nine times out of ten, Nadia, it\'s the boyfriend.'],
    canLib(s) && ['OKONKWO', 'Her whole night runs through that library. That\'s the last place anyone can put her.'],
    ['REYES', 'We can only be in one place. Your call.'],
  ].filter(Boolean), 'c1_lead_choice');

  choice('c1_lead_choice', 'Two possible leads, one car. Whichever you choose, the other waits.', 14, [
    { label: 'THE LIBRARY', sub: 'Where she was last seen, and who was there.', req: canLib, lock: 'Requires: evidence pointing to the library', next: 'c1_lead_good' },
    { label: 'THE EX', sub: 'Whoever sent her 73 messages.', req: canEx, lock: 'Requires: evidence pointing to an ex', next: 'c1_lead_ex' },
  ], { next: 'c1_lead_timeout' });
  N.c1_lead_timeout = { type: 'branch', next: s => canEx(s) ? 'c1_lead_ex' : 'c1_lead_good' };

  scene('c1_lead_good', 'hallway', [
    ['REYES', 'Library it is. The night staff roster has three names on it.'],
    ['REYES', 'One of them has an old trespassing charge that was dropped. Wade Harlan, thirty-four. Maintenance.'],
  ], 'c1_end');

  scene('c1_lead_ex', 'hallway', [
    ['REYES', 'The number that sent those texts is a prepaid phone, but the account email starts with "ekessler."'],
    ['REYES', 'Evan Kessler, twenty-one. The ex-boyfriend. He rents a house off campus on Delancey Court.'],
    ['OKONKWO', 'Let\'s go wake him up.'],
  ], 'c1_end', s => { s.f.wentEx = true; });

  scene('c1_lead_slow', 'hallway', [
    ['REYES', 'We\'ve got nothing that points anywhere.'],
    ['', 'It takes most of an hour on the phone before a tired Campus Safety dispatcher mentions a harassment report Tessa filed in September. That is an hour Tessa Brandt does not have.'],
    ['REYES', 'The report names Wade Harlan. Maintenance, night shift, Hollis library. Let\'s move.'],
  ], 'c1_end', s => lost(s, 1, 'no lead from the apartment'));

  N.c1_end = { type: 'chapterEnd', chapter: 1, next: 'c1_out' };
  N.c1_out = { type: 'branch', next: s => s.f.wentEx ? 'c2e_card' : 'c2_card' };

  /* ───────────── CHAPTER 2 (detour) — THE EX ───────────── */
  N.c2e_card = { type: 'card', chapter: 2, bg: 'house', next: 'c2e_door',
    lines: ['RESIDENCE OF EVAN KESSLER', '88 DELANCEY COURT', 'WEDNESDAY, OCTOBER 15 — 12:51 AM'] };

  scene('c2e_door', 'house', [
    ['', 'A rental house with a couch on the porch and one light on upstairs. Reyes knocks hard.'],
    ['', 'The door opens. A young man with his phone still in his hand sees two badges, and the color drains out of his face.'],
    ['EVAN', 'Is this about Tessa? I didn\'t — I only —'],
    ['', 'He slams the door. You hear him running for the back of the house.'],
    ['REYES', 'Innocent people don\'t run. Go!'],
  ], 'c2e_chase');

  N.c2e_chase = { type: 'qte', bg: 'alley', title: 'BACK YARDS',
    steps: [
      { type: 'press', key: 'D', act: 'CUT HIM OFF', ms: 1500, text: 'He comes out the kitchen door.' },
      { type: 'press', key: 'W', act: 'OVER THE FENCE', ms: 1500, text: 'A six-foot wooden fence.' },
      { type: 'mash', key: 'SPACE', act: 'RUN', n: 9, ms: 3200, text: 'Three back yards in a row.' },
      { type: 'press', key: 'A', act: 'SIDESTEP', ms: 1400, text: 'He kicks a trash can at you.' },
      { type: 'hold', key: 'E', act: 'PIN HIM', hold: 1000, ms: 2200, text: 'He trips and goes down.' },
    ],
    do: (s, r) => { s.f.evanFails = r.fails; if (r.fails >= 2) lost(s, 1, 'Kessler got away from you'); },
    next: 'c2e_caught' };

  scene('c2e_caught', 'alley', s => [
    s.f.evanFails >= 2
      ? ['', 'You lose him. Twenty minutes later a patrol car finds him hiding behind a dumpster two streets away.']
      : ['', 'You get a knee on his back. He doesn\'t fight. He just keeps saying her name.'],
    ['EVAN', 'I didn\'t do anything! I just text her! That\'s all I do, I just text her!'],
    ['REYES', 'Seventy-three times. Let\'s go, Romeo.'],
  ], 'c2e_int_card');

  N.c2e_int_card = { type: 'card', bg: 'interview', next: 'c2e_int',
    lines: s => ['9TH PRECINCT, SPECIAL VICTIMS DIVISION', 'INTERVIEW ROOM 2', 'WEDNESDAY, OCTOBER 15 — ' + clock(s, 1, 40)] };

  scene('c2e_int', 'interview', [
    ['', 'Evan Kessler, twenty-one. Since the arrest he has cried twice and asked for his mother once.'],
    ['EVAN', 'She blocked my number, so I got a new one. I know how that sounds. I just wanted her to answer me one time.'],
    ['OKONKWO', '"You looked tired today." You were watching her tonight.'],
    ['EVAN', 'I went to the library to talk to her after her shift. Around nine she came out the service door, and a maintenance guy in gray coveralls was carrying her bag. She got into his van.'],
    ['EVAN', 'I thought she was with him. So I went home.'],
    ['REYES', '(to you, quietly) Convenient. Our stalker says he saw a different stalker.'],
  ], 'c2e_decide');

  choice('c2e_decide', 'He ran from police, he lied to get around being blocked, and he admits he was there. Reyes wants to charge him.', 14, [
    { label: 'HANDWRITING', sub: 'Make him copy out the index cards.', req: s => s.clues.notes, lock: 'Requires: index cards', next: 'c2e_hand' },
    { label: 'BELIEVE HIM', sub: 'Check his story about the van. It will cost time.', next: 'c2e_believe' },
    { label: 'CHARGE HIM', sub: 'It\'s always the boyfriend.', next: 'c2e_book' },
  ], { next: 'c2e_book' });

  scene('c2e_hand', 'interview', [
    ['', 'You hand him a pen and read the index cards aloud. He writes them out in a cramped, slanted script that looks nothing like the block capitals on the cards.'],
    ['REYES', '...Okay. He didn\'t write those. It\'s not him.'],
    ['OKONKWO', 'Gray coveralls and a van at the library. Who works maintenance there at night?'],
    ['REYES', 'Wade Harlan, thirty-four. Let\'s go.'],
  ], 'c2_card', s => { s.f.cleared = true; s.seen.evan_cleared = 1; clue(s, 'witness', 'Kessler saw Tessa get into a maintenance van', 6); lost(s, 1, 'an hour spent on the wrong man'); });

  scene('c2e_believe', 'interview', [
    ['', 'It takes Reyes over an hour to get the library\'s outdoor camera footage. At 9:16 PM, Tessa Brandt climbs into a white maintenance van. Evan Kessler is at the edge of the frame, watching, then walking away.'],
    ['REYES', 'The kid was telling the truth. The van belongs to Wade Harlan, night maintenance.'],
    ['REYES', 'We just lost two hours on the wrong guy.'],
  ], 'c2_card', s => { s.f.cleared = true; s.seen.evan_cleared = 1; clue(s, 'witness', 'Camera: Tessa enters maintenance van, 9:16 PM', 8); lost(s, 2, 'two hours spent on the wrong man'); });

  scene('c2e_book', 'interview', [
    ['OKONKWO', 'Evan Kessler, you are under arrest for the kidnapping of Tessa Brandt.'],
    ['EVAN', 'What? No — the van! Check the van! Please!'],
    ['DIAZ', 'A stalker ex with no alibi who ran from police. Good work, both of you. Go home. He\'ll tell us where she is in the morning.'],
    ['REYES', 'He ran. He lied. Seventy-three texts. So why don\'t I feel good about this?'],
    ['', 'Nobody checks the van.'],
  ], 'c2_end', s => { s.f.wrong = true; add(s, -15); s.notify('ARREST — Evan Kessler charged with kidnapping'); });

  /* ───────────── CHAPTER 2 — THE SERVICE ENTRANCE ───────────── */
  N.c2_card = { type: 'card', chapter: 2, bg: 'dock', next: 'c2_call',
    lines: s => ['HOLLIS UNIVERSITY LIBRARY', 'SERVICE ENTRANCE', 'WEDNESDAY, OCTOBER 15 — ' + clock(s, 1, 7)] };

  scene('c2_call', 'dock', [
    ['', 'A white maintenance van is parked at the loading dock with its rear doors shut. There is a light on behind the service door.'],
    ['DIAZ', '(on the phone) Okonkwo. I woke up Judge Feld. I can get you a search warrant for the van and his locker in thirty minutes. Do not go in there without it.'],
    ['REYES', '(quietly) Thirty minutes. If she is in that van, that is thirty more minutes.'],
  ], 'c2_warrant');

  choice('c2_warrant', 'Captain Diaz is still on the line, waiting for your answer.', 14, [
    { label: 'WAIT', sub: 'Get the warrant. Thirty minutes.', next: 'c2_wait' },
    { label: 'GO NOW', sub: 'Search without it. Her life is at risk.', next: 'c2_go' },
  ], { next: 'c2_wait' });

  scene('c2_wait', 'dock', [
    ['', 'You watch the van for thirty-one minutes. Nothing moves. Then the warrant arrives on your phone with a one-word text from Diaz: "Now."'],
    ['REYES', 'For the record, I hated every second of that.'],
  ], 'c2_van', s => { s.f.warrant = true; s.late++; add(s, 8); s.notify('WARRANT SECURED — this search will hold up in court'); });

  scene('c2_go', 'dock', [
    ['OKONKWO', 'Captain, you\'re breaking up. Bad signal.'],
    ['DIAZ', 'Nadia, don\'t you d—'],
    ['', 'You hang up.'],
    ['REYES', '"Bad signal." That\'s what we\'re going with?'],
  ], 'c2_van', s => { s.f.warrant = false; trust(s, 1, 'respects the call'); });

  scene('c2_van', 'dock', [
    ['', 'Reyes opens the van\'s rear doors. Nobody inside. But there is a moving blanket, a roll of duct tape, and one white sneaker — a woman\'s, size seven.'],
    ['', 'The service door opens. A man in gray coveralls stands in the doorway. He looks at the open van, then at you.'],
    ['HARLAN', 'That\'s university property. You can\'t be in there.'],
  ], 'c2_harlan', s => clue(s, 'sneaker', 'Tessa\'s sneaker in the maintenance van', 8));

  choice('c2_harlan', 'Wade Harlan, twelve feet away. He is already leaning toward the door behind him.', 8, [
    { label: 'CALM', sub: 'We just want to talk, Wade.', next: 'c2_h_calm' },
    { label: 'THE CARDS', sub: 'Quote his own notes back to him.', req: s => s.clues.notes, lock: 'Requires: index cards', next: 'c2_h_cards' },
    { label: 'RUSH', sub: 'Grab him before he runs.', next: 'c2_h_rush' },
  ], { next: 'c2_h_rush' });

  scene('c2_h_calm', 'dock', [
    ['OKONKWO', 'Wade. Nobody is in trouble yet. We just want to talk.'],
    ['', 'He hesitates. It buys you half a second.'],
  ], 'c2_chase', s => { s.f.edge = true; s.notify('HEAD START — the chase will be easier'); });
  scene('c2_h_cards', 'dock', [
    ['OKONKWO', '"Sit by the window again."'],
    ['HARLAN', 'She... kept those?'],
    ['', 'For one full second he forgets to run.'],
  ], 'c2_chase', s => { s.f.edge = true; s.notify('HEAD START — the chase will be easier'); });
  scene('c2_h_rush', 'dock', [
    ['', 'You lunge. He is faster — he turns and bolts back through the service door.'],
  ], 'c2_chase');

  N.c2_chase = { type: 'qte', bg: 'chase', title: 'PURSUIT',
    scale: s => s.f.edge ? 1.3 : 1,
    steps: [
      { type: 'press', key: 'A', act: 'DODGE', ms: 1500, text: 'He throws a wrench at your head.' },
      { type: 'press', key: 'W', act: 'VAULT', ms: 1500, text: 'A book cart rolls into your path.' },
      { type: 'mash', key: 'SPACE', act: 'PUSH THROUGH', n: 8, ms: 3200, text: 'He pulls shelves down behind him.' },
      { type: 'press', key: 'S', act: 'SLIDE THE RAIL', ms: 1400, text: 'He takes the stairs down.' },
      { type: 'press', key: 'D', act: 'SHOULDER IT', ms: 1400, text: 'A fire door is swinging shut.' },
      { type: 'mash', key: 'SPACE', act: 'SPRINT', n: 10, ms: 3200, text: 'Outside. He runs for the rail yard fence.' },
      { type: 'hold', key: 'E', act: 'GRAB HIS BELT', hold: 1000, ms: 2200, text: 'He is halfway up the fence.' },
    ],
    do: (s, r) => { s.f.chaseFails = r.fails; },
    next: (s, r) => r.fails <= 1 ? 'c2_caught' : 'c2_fled' };

  scene('c2_caught', 'dock', [
    ['', 'You drag him off the fence and the two of you hit the gravel. He is stronger than he looks, but Reyes is there with the handcuffs.'],
    ['REYES', 'Wade Harlan, you are under arrest. You have the right to remain silent —'],
    ['', 'Harlan says nothing. He keeps looking over your shoulder, toward the rail yard.'],
  ], 'c2_int_card', s => { s.f.caught = true; });

  scene('c2_fled', 'dock', s => [
    ['', 'He drops down the far side of the fence and disappears between the freight cars.'],
    s.f.chaseFails >= 4 && ['', 'Reyes climbs over after him and lands badly. You hear him hit the ground.'],
    s.f.chaseFails >= 4 && ['REYES', 'It\'s my ankle. I can still walk. Keep going.'],
    ['', 'Something is caught on the top of the fence: a belt loop torn from his coveralls, with a single old brass key clipped to it. The key is stamped "C.R."'],
    ['REYES', 'C.R. — Calder Rail. That key opens one of the old signal towers in the yard. He wasn\'t running away from us, Nadia. He was running to her.'],
  ].filter(Boolean), 'c2_end', s => {
    s.f.fled = true; s.late++;
    if (s.f.chaseFails >= 4) { s.f.reyesHurt = true; s.seen.reyes_hurt = 1; }
    clue(s, 'key', 'Calder Rail key torn from Harlan\'s belt', 4);
  });

  N.c2_int_card = { type: 'card', bg: 'booking', next: 'c2_booking',
    lines: s => ['9TH PRECINCT, SPECIAL VICTIMS DIVISION', 'BOOKING DESK', 'WEDNESDAY, OCTOBER 15 — ' + clock(s, 2, 15)] };

  scene('c2_booking', 'booking', [
    ['', 'Booking. Reyes empties Harlan\'s pockets into a property tray and names each item for the desk sergeant.'],
    ['REYES', 'Wallet. University ID. A phone with the SIM card taken out. His work keys, on a ring.'],
    ['REYES', 'And one more key, loose in his other pocket. Old brass, with a paper tag. The tag says "C.R."'],
    ['HARLAN', 'That\'s nothing. It\'s for a shed.'],
    ['', 'It is the first thing he has said since the arrest. You take the key with you.'],
  ], 'c2_int', s => clue(s, 'key', 'Brass key tagged "C.R." from Harlan\'s pocket', 4));

  scene('c2_int', 'interview', [
    ['', 'Interview Room 2. Harlan sits very still with both hands flat on the table.'],
    ['HARLAN', 'I maintain the building. I see everybody who comes and goes. That\'s not a crime.'],
    ['REYES', 'Where is Tessa Brandt, Wade?'],
    ['HARLAN', 'At home, I\'d think. It\'s late.'],
  ], 'c2_int1', s => { s.f.pts = 0; });

  choice('c2_int1', 'He is calm and in no hurry. You need to shake that. How do you start?', 14, [
    { label: 'EMPATHY', sub: 'Nobody notices the man who fixes things.', next: 'c2_int1_emp' },
    { label: 'EVIDENCE', sub: 'Show him everything you have.', req: s => preVan(s) >= 3, lock: 'Requires: 3 pieces of evidence found before the van', next: 'c2_int1_ev' },
    { label: 'THREATEN', sub: 'Kidnapping is twenty-five to life.', next: 'c2_int1_thr' },
  ], { next: 'c2_int1_none' });

  scene('c2_int1_emp', 'interview', [
    ['OKONKWO', 'Eleven years in that building. You keep everything running, and nobody even learns your name.'],
    ['HARLAN', '...Do you know how many people in that library know my name? Two. And one of them does the payroll.'],
  ], 'c2_int2', s => { s.f.pts += 1; s.f.emp = true; s.notify('HARLAN — opening up'); });
  scene('c2_int1_ev', 'interview', [
    ['', 'You lay the evidence on the table one piece at a time, slowly. By the third piece, Harlan has stopped smiling.'],
    ['HARLAN', 'You\'re making it sound like something it wasn\'t.'],
  ], 'c2_int2', s => { s.f.pts += 2; s.notify('HARLAN — rattled'); });
  scene('c2_int1_thr', 'interview', [
    ['OKONKWO', 'Kidnapping is twenty-five years to life, Wade. Think about how old you\'ll be.'],
    ['HARLAN', 'Then I had better not say anything at all.'],
  ], 'c2_int2', s => { s.f.hostile = true; s.notify('HARLAN — shut down'); });
  scene('c2_int1_none', 'interview', [
    ['', 'You wait too long. Reyes steps in with questions Harlan has clearly prepared for.'],
  ], 'c2_int2');

  choice('c2_int2', 'One more try before he stops talking altogether.', 14, [
    { label: 'HER SHOE', sub: 'The sneaker in your van.', next: 'c2_int2_shoe' },
    { label: 'HIS SIDE', sub: 'Ask him to tell it his way.', next: 'c2_int2_ver' },
    { label: 'BLUFF', sub: 'Claim the van\'s GPS already led you to her.', next: 'c2_int2_lie' },
  ], { next: 'c2_int_gate' });

  scene('c2_int2_shoe', 'interview', [
    ['OKONKWO', 'A white sneaker, size seven, in the back of your van. Where is the other one, Wade?'],
    ['HARLAN', 'She was cold. I gave her a blanket. Is that what a monster does?'],
    ['', 'Reyes writes that down word for word. He has just admitted she was in the van.'],
  ], 'c2_int_gate', s => { s.f.pts += 1; add(s, 4); s.notify('ADMISSION — "I gave her a blanket"'); });
  scene('c2_int2_ver', 'interview', s => [
    ['OKONKWO', 'Forget how it looks. Tell me what happened, your way.'],
    s.f.emp
      ? ['HARLAN', 'She was going to quit the library. I heard her say so at the desk. If she quit, I would never see her again. I just needed more time with her. That\'s all it was.']
      : ['HARLAN', 'I would tell it to somebody who actually wanted to hear it. That isn\'t you.'],
  ], 'c2_int_gate', s => { s.f.pts += s.f.emp ? 2 : 1; });
  scene('c2_int2_lie', 'interview', s => [
    ['OKONKWO', 'University vans have GPS, Wade. We already know where you took her. I\'m giving you the chance to be the one who tells us.'],
    s.f.hostile
      ? ['HARLAN', 'If you knew where she was, you wouldn\'t be sitting here with me.']
      : ['HARLAN', '...Then you know she\'s warm. You know I left the heater on for her.'],
  ], 'c2_int_gate', s => { if (!s.f.hostile) s.f.pts += 2; });

  N.c2_int_gate = { type: 'branch', next: s => s.f.pts >= 3 ? 'c2_confess' : 'c2_lawyer' };

  scene('c2_confess', 'interview', [
    ['HARLAN', 'The old signal tower in the rail yard. Number six. She\'s fine. She\'s warm. I left the heater on for her.'],
    ['', 'A voluntary confession, on tape, after he was read his rights. Reyes is already out the door.'],
  ], 'c2_end', s => { s.f.confession = true; add(s, 15); s.notify('CONFESSION — voluntary and on tape'); });

  scene('c2_lawyer', 'interview', [
    ['HARLAN', 'I think... I think I would like a lawyer now.'],
    ['', 'The room goes quiet. The law is clear: once he asks for a lawyer, you must stop questioning him. Tessa is still out there somewhere.'],
  ], 'c2_lawyer_choice');

  choice('c2_lawyer_choice', 'He has asked for a lawyer. Anything he says after this can be thrown out by a judge.', 12, [
    { label: 'STOP', sub: 'Follow the law. Find her another way.', next: 'c2_stop' },
    { label: 'KEEP PUSHING', sub: 'Break the rule. "Where is she, Wade?"', next: 'c2_push' },
  ], { next: 'c2_stop' });

  scene('c2_stop', 'interview', [
    ['', 'You pick up the file and walk out, leaving him alone with the camera.'],
    ['REYES', 'That brass key from booking. "C.R." is Calder Rail — the yard office says it fits the old signal towers. There are nine of them.'],
    ['', 'You start at tower one. It takes forty minutes to search the first five.'],
  ], 'c2_end', s => { lost(s, 1, 'searching the towers one by one'); trust(s, 1, 'knows what that cost you'); });

  scene('c2_push', 'interview', [
    ['OKONKWO', 'Forget the lawyer. Forget the case. A nineteen-year-old girl is alone somewhere tonight. Where is she?'],
    ['HARLAN', '...The signal tower in the rail yard. Number six. The heater is on. She\'s fine.'],
    ['REYES', '(in the hallway, quietly) The prosecutor is going to pay for that in court.'],
    ['OKONKWO', 'I know.'],
  ], 'c2_end', s => { s.f.pushed = true; s.notify('RIGHTS VIOLATION — this statement will be challenged in court'); });

  N.c2_end = { type: 'chapterEnd', chapter: 2, next: 'c2_out' };
  N.c2_out = { type: 'branch', next: s => s.f.wrong ? 'c3w_card' : 'c3_card' };

  /* ───────────── CHAPTER 3 — TOWER SIX ───────────── */
  N.c3_card = { type: 'card', chapter: 3, bg: 'yard', next: 'c3_split',
    lines: s => ['CALDER RAIL YARD', 'SIGNAL TOWER 6', 'WEDNESDAY, OCTOBER 15 — ' + clock(s, 3, 2)] };
  N.c3_split = { type: 'branch', next: s => s.f.fled ? 'c3_standoff' : 'c3_fire' };

  scene('c3_fire', 'fire', s => [
    ['', 'Signal tower six is a two-story brick building with boarded-up windows. There is light behind the boards, and it is flickering.'],
    ['REYES', 'That\'s not a lamp. That\'s a fire.'],
    ['', s.late >= 2 ? 'Thick smoke is pouring out from under the door. You are very late.' : 'A thin line of smoke is coming out from under the door.'],
  ], 'c3_fire_qte');

  N.c3_fire_qte = { type: 'qte', bg: 'fire', title: 'TOWER SIX',
    scale: s => s.late >= 2 ? 0.85 : 1,
    steps: [
      { type: 'hold', key: 'E', act: 'TURN THE KEY', hold: 900, ms: 2200, text: 'A padlocked steel door. Use the brass key.' },
      { type: 'press', key: 'S', act: 'GET LOW', ms: 1500, text: 'Heat and smoke roll out at you.' },
      { type: 'mash', key: 'SPACE', act: 'UP THE STAIRS', n: 10, ms: 3200, text: 'Someone is coughing upstairs.' },
      { type: 'press', key: 'A', act: 'DODGE', ms: 1400, text: 'A ceiling beam falls.' },
      { type: 'hold', key: 'E', act: 'CUT THE TIES', hold: 1200, ms: 2200, text: 'Tessa. Zip-tied to a pipe.' },
      { type: 'mash', key: 'SPACE', act: 'KICK OUT THE BOARDS', n: 12, ms: 3400, text: 'The stairs are burning. Use the window.' },
      { type: 'press', key: 'W', act: 'LOWER HER DOWN', ms: 1500, text: 'Reyes is below, arms out.' },
      { type: 'press', key: 'D', act: 'JUMP', ms: 1400, text: 'Now you.' },
    ],
    do: (s, r) => {
      s.f.tessa = r.fails <= 1 ? 'safe' : 'hurt';
      s.seen['tessa_' + s.f.tessa] = 1;
    },
    next: 'c3_after' };

  scene('c3_standoff', 'yard', [
    ['', 'Signal tower six. Twenty feet up, on the outside walkway, a man is holding a smaller figure against the railing in front of him.'],
    ['HARLAN', 'STAY DOWN THERE! I didn\'t hurt her! Tessa, tell them I didn\'t hurt you!'],
    ['', 'He is holding a box cutter. He doesn\'t seem to remember that it is in his hand.'],
    ['REYES', '(quietly) I can\'t shoot without hitting her. You have to talk him down.'],
  ], 'c3_s1', s => { s.f.calm = 0; });

  const calm = (s, n) => { s.f.calm += n; s.notify(n > 0 ? 'HARLAN — calmer' : n < 0 ? 'HARLAN — more agitated' : 'HARLAN — no change'); };

  choice('c3_s1', 'You have three chances to calm him down. What do you say first?', 12, [
    { label: 'HIS NAME', sub: 'Wade. Look at me, not at her.', next: 'c3_s2', do: s => calm(s, 1) },
    { label: 'ORDER', sub: 'Drop the blade! Now!', next: 'c3_s2', do: s => calm(s, -1) },
    { label: 'TO TESSA', sub: 'Tessa, I\'m Nadia. I\'ve got you.', next: 'c3_s2', do: s => { calm(s, 0); s.f.spoke = true; } },
  ], { next: 'c3_s2', do: s => calm(s, -1) });

  choice('c3_s2', 'HARLAN: "She sees me now. She never saw me before. Nobody ever does."', 12, [
    { label: 'THE CARDS', sub: 'She kept every card you wrote her.', req: s => s.clues.notes, lock: 'Requires: index cards', next: 'c3_s3', do: s => calm(s, 2) },
    { label: 'THE TRUTH', sub: 'She saw you. She was afraid of you.', next: 'c3_s3', do: s => calm(s, 1) },
    { label: 'PROMISE', sub: 'Come down and people will hear your side.', next: 'c3_s3', do: s => calm(s, 1) },
  ], { next: 'c3_s3', do: s => calm(s, -1) });

  choice('c3_s3', 'Police sirens in the distance. Harlan hears them and tightens his grip on her.', 12, [
    { label: 'STEP BACK', sub: 'Put your gun away. Show your hands.', next: 'c3_s_gate', do: s => calm(s, 1) },
    { label: 'CLIMB', sub: 'Go up the ladder while he is distracted.', next: 'c3_s_gate', do: s => calm(s, -2) },
    { label: 'TRADE', sub: 'Let her go, and you and I will talk.', next: 'c3_s_gate', do: s => calm(s, 1) },
  ], { next: 'c3_s_gate', do: s => calm(s, -1) });

  N.c3_s_gate = { type: 'branch', next: s => s.f.calm >= 3 ? 'c3_surrender' : 'c3_lunge' };

  scene('c3_surrender', 'yard', [
    ['', 'His arm drops. The box cutter falls twenty feet into the gravel.'],
    ['', 'Tessa walks to the ladder. Halfway there, she starts to run.'],
    ['HARLAN', 'I just wanted more time with her.'],
    ['REYES', 'You\'re about to have plenty of time.'],
  ], 'c3_after', s => { s.f.caught = true; s.f.tessa = 'safe'; s.seen.tessa_safe = 1; add(s, 12); s.notify('ARREST — caught at the scene with the victim'); });

  scene('c3_lunge', 'yard', [['', 'You haven\'t calmed him. He raises the blade.']], 'c3_lunge_qte');

  N.c3_lunge_qte = { type: 'qte', bg: 'yard', title: 'THE WALKWAY',
    steps: [
      { type: 'mash', key: 'SPACE', act: 'CLIMB', n: 9, ms: 3000, text: 'Up the ladder. Fast.' },
      { type: 'press', key: 'A', act: 'DUCK THE BLADE', ms: 1300, text: 'He swings at you.' },
      { type: 'hold', key: 'E', act: 'PIN HIS WRIST', hold: 1100, ms: 2200, text: 'You catch his arm.' },
      { type: 'press', key: 'D', act: 'PULL HER CLEAR', ms: 1300, text: 'Tessa is at the edge.' },
      { type: 'press', key: 'W', act: 'DRIVE HIM DOWN', ms: 1300, text: 'He comes at you again.' },
    ],
    do: (s, r) => {
      s.f.tessa = r.fails <= 1 ? 'safe' : 'hurt';
      s.seen['tessa_' + s.f.tessa] = 1;
      if (r.fails >= 3) { s.f.harlanDead = true; s.seen.harlan_dead = 1; }
      else { s.f.caught = true; add(s, 12); }
    },
    next: 'c3_after' };

  N.c3_after = { type: 'branch', next: s => s.f.tessa === 'safe' ? 'c3_after_safe' : 'c3_after_hurt' };

  scene('c3_after_safe', 'dawn', [
    ['', 'Tessa Brandt sits on the back step of an ambulance, wrapped in a foil blanket, holding a paper cup with both hands.'],
    ['TESSA', 'I reported it. To the campus in September, and to you three weeks ago. I did everything you\'re supposed to do.'],
  ], 'c3_bond');

  choice('c3_bond', 'She is watching to see how you answer. What do you say to her?', 14, [
    { label: 'I KNOW', sub: 'You did everything right. We failed you.', next: 'c3_wrap', do: s => { s.f.bond = true; s.notify('TESSA — trusts you'); } },
    { label: 'STATEMENT', sub: 'I need your statement while it\'s fresh.', next: 'c3_wrap', do: s => { add(s, 3); s.notify('TESSA — went quiet'); } },
    { label: 'REST', sub: 'You don\'t have to talk tonight.', next: 'c3_wrap', do: s => { s.f.bond = true; s.notify('TESSA — trusts you'); } },
  ], { next: 'c3_wrap' });

  scene('c3_after_hurt', 'dawn', [
    ['', 'Paramedics load Tessa Brandt into the ambulance on a stretcher, with an oxygen mask over her face. She looks at you for a second before the doors close.'],
    ['', 'She is alive. The paramedic will not promise anything more than that.'],
  ], 'c3_wrap');

  scene('c3_wrap', 'dawn', s => [
    s.f.harlanDead && ['', 'Across the yard, below the walkway, Wade Harlan\'s body lies under a tarp. He went over the railing in the struggle.'],
    s.f.reyesHurt && ['REYES', 'They want to X-ray my ankle. I told them I walked in here and I can walk out.'],
    s.trust >= 2 ? ['REYES', 'Hey. Good work tonight, partner.'] : ['REYES', 'We need to talk about how tonight went. Not now. But soon.'],
    ['', 'The sun comes up over the rail yard.'],
  ].filter(Boolean), 'c3_end');

  /* wrong-man route: nobody was looking for her */
  N.c3w_card = { type: 'card', chapter: 3, bg: 'fire', next: 'c3w_scene',
    lines: ['CALDER RAIL YARD', 'SIGNAL TOWER 6', 'WEDNESDAY, OCTOBER 15 — 6:20 AM'] };

  scene('c3w_scene', 'fire', [
    ['', 'At 5:52 AM a rail yard crew reports a fire in an old signal tower. By the time you arrive, firefighters have broken the door down.'],
    ['', 'Two of them carry a young woman out of the smoke. She is wearing one white sneaker. There are zip-tie marks on both wrists.'],
    ['REYES', 'That\'s Tessa. She was in there all night, while we had —'],
    ['', 'He can\'t finish the sentence. A paramedic lifts her oxygen mask for a moment, and Tessa Brandt says one word.'],
    ['TESSA', 'Wade.'],
  ], 'c3w_after', s => { s.f.tessa = 'hurt'; s.seen.tessa_hurt = 1; });

  scene('c3w_after', 'dawn', [
    ['', 'You arrested the wrong man. Evan Kessler is released at 7:15 AM, and his family hires a lawyer by noon.'],
    ['REYES', 'Wade Harlan. Library maintenance. Kessler told us about the van, and we didn\'t check.'],
    ['', 'Harlan\'s van is found empty at the library. His apartment has been cleared out. His photo goes to every police station, toll booth and bus terminal in the state.'],
  ], 'c3w_term_card');

  N.c3w_term_card = { type: 'card', bg: 'terminal', next: 'c3w_term',
    lines: ['PORT CALDER BUS TERMINAL', 'GATE 14', 'SATURDAY, OCTOBER 18 — 5:44 AM'] };

  scene('c3w_term', 'terminal', [
    ['', 'Three days later, a ticket clerk recognizes the photo. A man in a baseball cap with a gray duffel bag, holding a one-way ticket north. He is fourth in line at Gate 14.'],
    ['REYES', 'That\'s him. No van to hide in this time.'],
    ['', 'Harlan looks up from his ticket and sees you.'],
  ], 'c3w_qte');

  N.c3w_qte = { type: 'qte', bg: 'terminal', title: 'GATE 14',
    steps: [
      { type: 'press', key: 'A', act: 'DODGE', ms: 1400, text: 'He swings the duffel bag at you.' },
      { type: 'mash', key: 'SPACE', act: 'THROUGH THE CROWD', n: 10, ms: 3200, text: 'He shoves through the line.' },
      { type: 'press', key: 'W', act: 'JUMP THE BENCHES', ms: 1400, text: 'A row of seats is in your way.' },
      { type: 'press', key: 'S', act: 'SLIDE UNDER', ms: 1400, text: 'A luggage cart rolls at you.' },
      { type: 'hold', key: 'E', act: 'TAKE HIM DOWN', hold: 1100, ms: 2200, text: 'He is on the bus steps.' },
    ],
    do: (s, r) => {
      if (r.fails <= 1) { s.f.caught = true; s.f.warrant = true; }
      else { s.f.fugitive = true; }
    },
    next: (s, r) => r.fails <= 1 ? 'c3w_caught' : 'c3w_gone' };

  scene('c3w_caught', 'terminal', [
    ['', 'You pull him off the bottom step of the bus and put him on the floor.'],
    ['HARLAN', 'She was fine. I left the heater on for her.'],
    ['REYES', 'That heater set the building on fire, Wade. She has been on oxygen for three days.'],
  ], 'c3_end');

  scene('c3w_gone', 'terminal', [
    ['', 'The bus doors close before you reach them. It pulls out with Wade Harlan at the back window, watching you.'],
    ['', 'State police stop the bus forty miles north. He is no longer on it.'],
  ], 'c3_end');

  N.c3_end = { type: 'chapterEnd', chapter: 3, next: 'c3_out' };
  N.c3_out = { type: 'branch', next: s => s.f.harlanDead ? 'end_dead' : s.f.fugitive ? 'end_fugitive' : 'c4_card' };

  /* ───────────── CHAPTER 4 — THE PEOPLE ───────────── */
  N.c4_card = { type: 'card', chapter: 4, bg: 'court', next: 'c4_office',
    lines: ['CALDER COUNTY COURTHOUSE', 'OFFICE OF THE DISTRICT ATTORNEY', 'THREE MONTHS LATER', '— YOU NOW PLAY PROSECUTOR IMANI COLE —'] };

  scene('c4_office', 'court', s => [
    ['', 'You are Imani Cole, the prosecutor on the Harlan case. Detective Okonkwo stands in your office doorway while you go through her file.'],
    s.f.wrong && ['COLE', 'You charged Evan Kessler first. The defense will put his booking photo in front of the jury and say: "The police were certain once before."'],
    s.f.warrant
      ? ['COLE', 'The search of the van was done with a warrant. That evidence is safe.']
      : ['COLE', 'You searched the van without a warrant. The defense will ask the judge to throw out everything you found in it.'],
    s.f.confession && ['COLE', 'And he confessed voluntarily, on tape, after hearing his rights. That is the best evidence we have.'],
    s.f.pushed && ['COLE', 'And then he asks for a lawyer, on tape, and you keep questioning him. Nadia.'],
    s.f.pushed && ['OKONKWO', 'I would do it again.'],
    s.f.pushed && ['COLE', 'I know. That is what I now have to explain to a judge.'],
  ].filter(Boolean), 'c4_gate1');

  N.c4_gate1 = { type: 'branch', next: s => !s.f.warrant ? 'c4_supp_warrant' : s.f.pushed ? 'c4_supp_stmt' : 'c4_plea' };

  scene('c4_supp_warrant', 'court', [
    ['JUDGE', 'The defense lawyer, Mr. Pruitt, asks me to throw out the search of the van and everything found in it. Ms. Cole, your response?'],
  ], 'c4_supp_warrant_c');
  choice('c4_supp_warrant_c', 'The van was searched without a warrant. Which legal argument do you make to keep the evidence?', 16, [
    { label: 'EMERGENCY', sub: 'A life was in danger. Works only if the detectives had solid evidence first.', next: 'c4_exig' },
    { label: 'INEVITABLE', sub: 'The warrant was 30 minutes away anyway. Safer, but weaker.', next: 'c4_inev' },
  ], { next: 'c4_supp_lost' });

  N.c4_exig = { type: 'branch', next: s => preVan(s) >= 3 ? 'c4_exig_win' : 'c4_supp_lost' };
  scene('c4_exig_win', 'court', [
    ['COLE', 'The detectives were not guessing, Your Honor. They had her messages, her work schedule and her last known location. They had every reason to believe her life was in danger.'],
    ['JUDGE', 'I agree. They had specific facts and a real emergency. The evidence stays in.'],
  ], 'c4_gate2', s => s.notify('RULING — the van evidence stays in'));
  scene('c4_inev', 'court', [
    ['COLE', 'A warrant request was already in front of Judge Feld. The police would have legally searched that van thirty minutes later, no matter what.'],
    ['JUDGE', 'I will allow the evidence. Barely. And tell your detectives that "bad signal" is not a legal argument.'],
  ], 'c4_gate2', s => { add(s, -5); s.notify('RULING — evidence stays in, but the judge is unhappy'); });
  scene('c4_supp_lost', 'court', [
    ['JUDGE', 'A hunch is not an emergency, Ms. Cole. Your detectives had almost nothing when they opened that van. The sneaker cannot be used at trial.'],
  ], 'c4_gate2', s => { add(s, -15); s.f.suppVan = true; s.notify('RULING — the van evidence is thrown out'); });

  N.c4_gate2 = { type: 'branch', next: s => s.f.pushed ? 'c4_supp_stmt' : 'c4_plea' };

  scene('c4_supp_stmt', 'court', [
    ['JUDGE', 'And what about the statement the detective took after Mr. Harlan asked for a lawyer?'],
  ], 'c4_supp_stmt_c');
  choice('c4_supp_stmt_c', 'That statement will be thrown out either way. You can only choose how you lose it.', 16, [
    { label: 'DEFEND IT', sub: 'She asked in order to save a life.', next: 'c4_stmt_ps' },
    { label: 'GIVE IT UP', sub: 'Withdraw it yourself and earn the judge\'s respect.', next: 'c4_stmt_con' },
  ], { next: 'c4_stmt_ps' });
  scene('c4_stmt_ps', 'court', s => [
    ['COLE', 'Detective Okonkwo was not building a case in that room, Your Honor. She was trying to find a girl before it was too late.'],
    ['JUDGE', s.f.tessa === 'hurt'
      ? 'And she nearly was too late. The rescue was lawful, and so is what was found at the tower. But the statement itself cannot be used.'
      : 'The rescue was lawful. The statement cannot be used. And I am not happy with how it was obtained, Ms. Cole.'],
  ], 'c4_plea', s => add(s, s.f.tessa === 'hurt' ? -4 : -10));
  scene('c4_stmt_con', 'court', [
    ['COLE', 'We withdraw the statement, Your Honor. I will not defend the way it was obtained.'],
    ['JUDGE', 'Thank you, Ms. Cole. That kind of honesty is rarer than it should be.'],
  ], 'c4_plea', s => { add(s, -8); s.f.candor = true; s.notify('HONESTY — the court will remember this at trial'); });

  scene('c4_plea', 'court', s => [
    ['PRUITT', 'My client will plead guilty to kidnapping and take fifteen years. No trial, and Tessa Brandt never has to testify.'],
    ['', s.strength >= 50 ? 'Your case is strong. You would probably win at trial, and Pruitt knows it.'
      : s.strength >= 30 ? 'Your case could go either way at trial.'
        : 'Your case is weak. A trial would be a real risk.'],
  ], 'c4_plea_c');
  choice('c4_plea_c', 'Accept a guaranteed fifteen years, or risk a trial for a longer sentence?', 18, [
    { label: 'TAKE THE DEAL', sub: 'Fifteen years, guaranteed.', next: 'end_plea' },
    { label: 'GO TO TRIAL', sub: 'Risk it for the full sentence.', next: 'c4_trial' },
  ], { next: 'end_plea' });

  scene('c4_trial', 'court', [
    ['', 'The trial begins. After two days, the jury sees Wade Harlan as a tired, harmless-looking man in a borrowed suit.'],
    ['', 'Tessa Brandt could change that. She is on your witness list, but you have not yet asked her to testify.'],
  ], 'c4_witness');
  choice('c4_witness', 'Her testimony could win the case, but it would force her to relive it in front of him.', 16, [
    { label: 'CALL TESSA', sub: 'Ask her to testify.', next: 'c4_call' },
    { label: 'PROTECT HER', sub: 'Try to win without her.', next: 'c4_protect' },
  ], { next: 'c4_protect' });

  scene('c4_call', 'court', s => s.f.bond ? [
    ['TESSA', 'A detective told me that night that I did everything right. So I am going to do this right, too.'],
    ['', 'She testifies for fifty minutes and looks at Harlan exactly once. After that, the jury no longer sees a harmless man.'],
  ] : [
    ['', 'She gets through her testimony, but only just. She has no reason to trust the people who are asking her to do this.'],
    ['', 'You are not sure you should have asked her.'],
  ], 'c4_cross', s => add(s, s.f.bond ? 15 : 7));
  scene('c4_protect', 'court', [
    ['', 'You build the case from documents, timestamps and a brass key. It is solid, but the jury never hears from the victim herself.'],
  ], 'c4_cross');

  N.c4_cross = { type: 'qte', bg: 'court', title: 'IN THE COURTROOM',
    steps: [
      { type: 'press', key: 'SPACE', act: 'OBJECT', ms: 1800, text: 'Pruitt implies Tessa liked the notes.' },
      { type: 'press', key: 'SPACE', act: 'OBJECT', ms: 1600, text: 'Pruitt attacks Okonkwo\'s record.' },
      { type: 'hold', key: 'E', act: 'PAUSE FOR EFFECT', hold: 1300, ms: 2200, text: 'Your closing argument. Take your time.' },
    ],
    do: (s, r) => add(s, (3 - r.fails) * 4 + (s.f.candor ? 5 : 0)),
    next: s => s.strength >= 60 ? 'end_guilty' : s.strength >= 40 ? 'end_lesser' : 'end_acquit' };

  const tessaLine = s => s.f.tessa === 'safe'
    ? 'Tessa Brandt transfers to a university four hundred miles away. In March, a postcard arrives at the 9th Precinct with one word on it: "Leaving."'
    : 'Tessa Brandt spends eleven days in the hospital and the spring semester at home. She has not decided whether she will go back in the fall.';
  const evanLine = s => s.f.wrong ? ' Evan Kessler sues the city for wrongful arrest. The city settles.' : '';

  N.end_plea = { type: 'ending', bg: 'court', title: 'PLEA DEAL — FIFTEEN YEARS',
    text: s => 'Wade Harlan stands, pleads guilty, and is led out through a side door. The hearing takes nine minutes. ' + tessaLine(s) + evanLine(s) };
  N.end_guilty = { type: 'ending', bg: 'court', title: 'GUILTY — ALL COUNTS',
    text: s => 'The jury finds Wade Harlan guilty of kidnapping, stalking and unlawful surveillance. He is sentenced to twenty-five years to life. ' + tessaLine(s) + evanLine(s) };
  N.end_lesser = { type: 'ending', bg: 'court', title: 'GUILTY — LESSER CHARGE ONLY',
    text: s => 'The jury is not convinced of kidnapping, and convicts only on unlawful imprisonment. Harlan is sentenced to four years and will be out in three. ' + tessaLine(s) + evanLine(s) };
  N.end_acquit = { type: 'ending', bg: 'court', title: 'NOT GUILTY',
    text: s => 'Too much of the evidence was thrown out or never found, and the jury has reasonable doubt. Wade Harlan walks out of the courtroom a free man. Okonkwo watches him go. ' + tessaLine(s) + evanLine(s) };
  N.end_dead = { type: 'ending', bg: 'dawn', title: 'CASE CLOSED — SUSPECT DECEASED',
    text: s => 'There is no trial. A review board examines Harlan\'s death and clears you in a two-page report. Nobody will ever have to prove in court what he did. ' + tessaLine(s) };
  N.end_fugitive = { type: 'ending', bg: 'terminal', title: 'OPEN CASE — SUSPECT AT LARGE',
    text: s => 'Wade Harlan is never found. His photo stays on the wall of the 9th Precinct, and every few months a tip comes in from another college town. The night you spent on the wrong man was the night you could have caught the right one. ' + tessaLine(s) + evanLine(s) };

  /* ───────────── FLOWCHARTS ───────────── */
  const FLOW = {
    1: { title: 'CHAPTER 1 — THE EMPTY APARTMENT', rows: [
      [['clue_tablet', 'The tablet'], ['clue_notes', 'The index cards'], ['clue_receipt', 'The receipt'], ['clue_window', 'The fire escape'], ['clue_report', 'The corkboard'], ['clue_ex', 'The torn photo']],
      [['c1_priya_soft', 'Reassure Priya'], ['c1_priya_cards', 'Show her the cards'], ['c1_priya_hard', 'Press her'], ['c1_priya_silent', 'Say nothing']],
      [['c1_lead_good', 'Follow the library'], ['c1_lead_ex', 'Follow the ex'], ['c1_lead_slow', 'No lead — an hour lost']],
    ] },
    2: { title: 'CHAPTER 2 — THE SERVICE ENTRANCE', rows: [
      [['c2e_door', 'Evan Kessler\'s door'], ['c2_call', 'The loading dock']],
      [['c2e_hand', 'Test his handwriting'], ['c2e_believe', 'Believe Kessler'], ['c2e_book', 'Charge the wrong man']],
      [['c2_wait', 'Wait for the warrant'], ['c2_go', '"Bad signal"']],
      [['c2_caught', 'Harlan in handcuffs'], ['c2_fled', 'Harlan escapes'], ['reyes_hurt', 'Reyes is injured']],
      [['c2_confess', 'Harlan confesses'], ['c2_stop', 'Respect his rights'], ['c2_push', 'Keep pushing']],
    ] },
    3: { title: 'CHAPTER 3 — TOWER SIX', rows: [
      [['c3_fire', 'The tower is burning'], ['c3_standoff', 'The walkway standoff'], ['c3w_scene', 'Found by firefighters']],
      [['c3_surrender', 'Talked down'], ['c3_lunge', 'He attacks'], ['c3w_caught', 'Caught at Gate 14'], ['c3w_gone', 'The bus leaves']],
      [['tessa_safe', 'Tessa walks out'], ['tessa_hurt', 'Tessa hospitalized'], ['harlan_dead', 'Harlan falls']],
    ] },
    4: { title: 'CHAPTER 4 — THE PEOPLE', rows: [
      [['c4_exig_win', 'Emergency argument wins'], ['c4_inev', 'Inevitable discovery'], ['c4_supp_lost', 'Evidence thrown out'], ['c4_stmt_ps', 'Defend the statement'], ['c4_stmt_con', 'Give up the statement']],
      [['end_plea', 'Take the deal'], ['c4_trial', 'Go to trial']],
      [['c4_call', 'Tessa testifies'], ['c4_protect', 'Protect her']],
      [['end_guilty', 'Guilty, all counts'], ['end_lesser', 'Lesser charge'], ['end_acquit', 'Not guilty'], ['end_dead', 'No trial'], ['end_fugitive', 'Suspect at large']],
    ] },
  };

  const STORY = { nodes: N, flow: FLOW, start: 'c1_card', newState };
  root.STORY = STORY;
  if (typeof module !== 'undefined') module.exports = STORY;
})(typeof window !== 'undefined' ? window : globalThis);
