/* DEAD SIGNAL — engine: stills, dialogue, timed choices, investigation, QTEs, flowcharts.
   Debug helpers: index.html?gallery shows every still; index.html?at=<nodeId> starts at that node. */
(() => {
  const { nodes: N, flow: FLOW, start, newState } = window.STORY;
  const ART = window.ART;
  const $ = id => document.getElementById(id);
  const el = (tag, cls, html) => { const e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; };
  const sleep = ms => new Promise(r => setTimeout(r, ms));
  const QKEYS = ['W', 'A', 'S', 'D', 'E', 'SPACE'];
  const params = new URLSearchParams(location.search);

  if (params.has('gallery')) {
    document.body.innerHTML = '<div class="gallery">' + Object.keys(ART).map(k => `<figure>${ART[k]}<figcaption>${k}</figcaption></figure>`).join('') + '</div>';
    return;
  }

  let s, keyDown = null, keyUp = null, actx = null, curBg = null;

  /* ── audio ── */
  function tone(freq, dur = 0.12, type = 'sine', vol = 0.06) {
    if (!actx) return;
    const o = actx.createOscillator(), g = actx.createGain(), t = actx.currentTime;
    o.type = type; o.frequency.value = freq;
    g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
    o.connect(g).connect(actx.destination); o.start(t); o.stop(t + dur);
  }

  /* ── input: handlers get (key, isAutoRepeat) ── */
  const norm = e => e.code === 'Space' ? 'SPACE' : e.key.toUpperCase();
  document.addEventListener('keydown', e => {
    const k = norm(e);
    if (k === 'SPACE' && keyDown) e.preventDefault();
    if (keyDown) keyDown(k, e.repeat);
  });
  document.addEventListener('keyup', e => { if (keyUp) keyUp(norm(e)); });

  /* ── stage: an illustrated still per location; img/<name>.jpg overrides it if present ── */
  function setBg(bg) {
    if (bg === curBg) return;
    curBg = bg;
    const st = $('stage');
    st.innerHTML = ART[bg] || '';
    const im = new Image();
    im.onload = () => { if (curBg === bg) st.append(im); };
    im.src = 'img/' + bg + '.jpg';
    st.classList.remove('in'); void st.offsetWidth; st.classList.add('in');
  }

  /* ── HUD ── */
  function notify(msg) {
    const t = el('div', 'toast', msg);
    $('toasts').append(t);
    tone(660, 0.08, 'triangle', 0.04);
    setTimeout(() => t.classList.add('out'), 3600);
    setTimeout(() => t.remove(), 4200);
  }
  function updateHud() {
    $('hudChapter').textContent = FLOW[s.chapter].title;
    $('hudStrength').textContent = s.strength + '%';
    $('hudBar').style.width = s.strength + '%';
    $('hudClues').textContent = Object.keys(s.clues).length;
  }
  const hideAll = () => ['dialog', 'choices', 'timer', 'inv', 'qte', 'card', 'flow'].forEach(i => { $(i).hidden = true; });

  /* ── dialogue ── */
  function say(who, text) {
    return new Promise(res => {
      const box = $('dialog'), t = $('text');
      box.hidden = false; box.classList.toggle('narr', !who);
      $('who').textContent = who; $('who').dataset.who = who;
      t.textContent = '';
      let i = 0, done = false;
      const iv = setInterval(() => {
        i += 2; t.textContent = text.slice(0, i);
        if (i >= text.length) { clearInterval(iv); done = true; }
      }, 16);
      const adv = () => {
        if (!done) { clearInterval(iv); t.textContent = text; done = true; return; }
        keyDown = null; box.onclick = null; $('stage').onclick = null; res();
      };
      keyDown = (k, rep) => { if (!rep && (k === 'SPACE' || k === 'ENTER')) adv(); };
      box.onclick = adv; $('stage').onclick = adv;
    });
  }

  function waitAdvance(ms) {
    return new Promise(res => {
      const done = () => { clearTimeout(to); keyDown = null; $('card').onclick = null; res(); };
      const to = setTimeout(done, ms);
      keyDown = (k, rep) => { if (!rep && (k === 'SPACE' || k === 'ENTER')) done(); };
      $('card').onclick = done;
    });
  }

  /* ── timed choice: the clock only starts after you have had time to read ── */
  function choose(n) {
    return new Promise(res => {
      const wrap = $('choices'), box = $('dialog'), bar = $('timerFill');
      box.hidden = false; box.classList.add('narr');
      $('who').textContent = ''; $('text').textContent = n.prompt || '';
      wrap.innerHTML = ''; wrap.hidden = false;
      let to = null;
      const finish = pick => { clearTimeout(to); keyDown = null; wrap.hidden = true; $('timer').hidden = true; res(pick); };
      const opts = n.options.map(o => ({ o, ok: !o.req || !!o.req(s) }));
      let chars = (n.prompt || '').length;
      opts.forEach(({ o, ok }, i) => {
        const b = el('button', 'opt' + (ok ? '' : ' locked'));
        const sub = ok ? (o.sub || '') : (o.lock || 'Locked');
        chars += o.label.length + sub.length;
        b.append(el('kbd', '', String(i + 1)), el('b', '', (ok ? '' : '🔒 ') + o.label), el('span', '', sub));
        if (ok) b.onclick = () => finish(o);
        wrap.append(b);
      });
      keyDown = (k, rep) => { const p = opts[+k - 1]; if (!rep && p && p.ok) finish(p.o); };
      if (n.timer) {
        $('timer').hidden = false;
        bar.style.animation = 'none';
        to = setTimeout(() => {
          void bar.offsetWidth;
          bar.style.animation = `shrink ${n.timer}s linear forwards`;
          to = setTimeout(() => { tone(120, 0.3, 'sawtooth'); finish(n.timeout); }, n.timer * 1000);
        }, Math.min(9000, 2000 + chars * 45));
      }
    });
  }

  /* ── investigation ── */
  const PLANS = {
    apartment: `<svg viewBox="0 0 100 60" preserveAspectRatio="none">
      <rect x="1" y="1" width="98" height="58" class="wall"/>
      <rect x="6" y="6" width="26" height="9" class="furn"/><text x="19" y="19.5">DESK</text>
      <circle cx="37" cy="13" r="2.4" class="furn"/><text x="37" y="24.5">BIN</text>
      <rect x="62" y="8" width="30" height="20" class="furn"/><rect x="64" y="10" width="9" height="6" class="furn2"/><text x="77" y="33">BED</text>
      <rect x="4" y="24" width="7" height="22" class="furn"/><text x="16" y="46">SHELF</text>
      <rect x="38" y="1" width="20" height="2.4" class="furn2"/>
      <rect x="30" y="36" width="24" height="12" class="rug"/>
      <line x1="99" y1="34" x2="99" y2="46" class="win"/><text x="89" y="48">FIRE ESCAPE</text>
      <line x1="44" y1="59" x2="54" y2="59" class="door"/><path d="M44 59 A10 10 0 0 1 54 49" class="swing"/><text x="61" y="57">DOOR</text>
    </svg>`,
  };
  function investigate(n) {
    return new Promise(res => {
      hideAll(); $('inv').hidden = false;
      $('invTitle').textContent = n.title;
      const map = $('invMap'), info = $('invInfo'), leave = $('invLeave');
      map.innerHTML = PLANS[n.plan];
      info.textContent = n.intro;
      leave.textContent = 'LEAVE THE ROOM';
      let left = n.budget;
      const pips = () => { $('invBudget').textContent = '●'.repeat(left) + '○'.repeat(n.budget - left); };
      pips();
      n.hotspots.forEach(h => {
        const b = el('button', 'spot'); b.append(el('span', '', h.name));
        b.style.left = h.x + '%'; b.style.top = h.y + '%';
        b.onclick = () => {
          if (b.classList.contains('used') || left <= 0) return;
          b.classList.add('used'); left--; pips();
          info.innerHTML = ''; info.append(el('b', '', h.name), document.createTextNode(h.text));
          tone(520, 0.08, 'triangle');
          if (h.do) h.do(s);
          updateHud();
          if (left === 0) { map.classList.add('spent'); leave.textContent = n.outro; leave.classList.add('pulse'); }
        };
        map.append(b);
      });
      leave.onclick = () => { map.classList.remove('spent'); leave.classList.remove('pulse'); $('inv').hidden = true; res(); };
    });
  }

  /* ── QTE ──
     press: hit the key once.  mash: tap it n times.  hold: keep it down until the bar fills.
     A hold tolerates brief key-up blips (some keyboards/compositors emit them during auto-repeat);
     letting go for real just resets the bar, and you can press again while time remains. */
  function qteStep(st, scale) {
    return new Promise(res => {
      const p = $('qtePrompt'), ring = $('qteRing'), fill = $('qteFill');
      const key = st.key, ms = st.ms * scale;
      $('qteKey').textContent = key;
      $('qteKey').classList.toggle('wide', key === 'SPACE');
      $('qteAct').textContent = st.act;
      $('qteHow').textContent = st.type === 'mash' ? 'TAP REPEATEDLY' : st.type === 'hold' ? 'HOLD THE KEY DOWN' : 'PRESS ONCE';
      fill.style.width = '0%'; $('qteBar').hidden = st.type === 'press';
      p.hidden = false;
      const total = ms + (st.type === 'hold' ? st.hold : 0);
      ring.style.animation = 'none'; void ring.offsetWidth;
      ring.style.animation = `drain ${total}ms linear forwards`;
      let count = 0, holdT = null, relT = null, raf = 0;
      const end = ok => {
        clearTimeout(to); clearTimeout(holdT); clearTimeout(relT); cancelAnimationFrame(raf);
        keyDown = keyUp = null; p.onpointerdown = p.onpointerup = p.onpointerleave = null;
        res(ok);
      };
      const to = setTimeout(() => end(false), total);
      const down = (k, rep) => {
        if (st.type !== 'hold' && rep) return;
        if (k !== key) { if (st.type === 'press' && QKEYS.includes(k)) end(false); return; }
        if (st.type === 'press') end(true);
        else if (st.type === 'mash') {
          count++; fill.style.width = (count / st.n * 100) + '%';
          tone(280 + count * 25, 0.04, 'square', 0.025);
          if (count >= st.n) end(true);
        } else {
          clearTimeout(relT); relT = null;
          if (holdT) return;
          const t0 = performance.now();
          const tick = () => { fill.style.width = Math.min(100, (performance.now() - t0) / st.hold * 100) + '%'; raf = requestAnimationFrame(tick); };
          tick();
          holdT = setTimeout(() => end(true), st.hold);
        }
      };
      const up = k => {
        if (k !== key || st.type !== 'hold' || !holdT) return;
        clearTimeout(relT);
        relT = setTimeout(() => { clearTimeout(holdT); holdT = null; cancelAnimationFrame(raf); fill.style.width = '0%'; }, 180);
      };
      keyDown = down; keyUp = up;
      p.onpointerdown = e => { e.preventDefault(); down(key, false); };
      p.onpointerup = p.onpointerleave = () => up(key);
    });
  }
  async function qte(n) {
    hideAll();
    const v = $('qte'); v.hidden = false;
    $('qteTitle').textContent = n.title;
    const scale = n.scale ? n.scale(s) : 1;
    let fails = 0;
    for (const st of n.steps) {
      v.className = ''; $('qtePrompt').hidden = true;
      $('qteText').textContent = st.text;
      await sleep(1500 + st.text.length * 45);
      const ok = await qteStep(st, scale);
      if (!ok) fails++;
      v.className = ok ? 'ok' : 'bad';
      $('qteMarks').append(el('i', ok ? 'ok' : 'bad'));
      tone(ok ? 880 : 130, 0.18, ok ? 'sine' : 'sawtooth');
      $('qtePrompt').hidden = true;
      await sleep(600);
    }
    await sleep(300);
    v.hidden = true; v.className = ''; $('qteMarks').innerHTML = '';
    return { fails };
  }

  /* ── flowchart ── */
  function flowHTML(ch) {
    const f = FLOW[ch];
    let got = 0, total = 0;
    const rows = f.rows.map(r => '<div class="frow">' + r.map(([id, label]) => {
      total++;
      if (s.seen[id]) { got++; return `<div class="fnode on">${label}</div>`; }
      return '<div class="fnode">🔒 ? ? ?</div>';
    }).join('') + '</div>').join('<div class="flink"></div>');
    return `<section><h3>${f.title} <small>${got} / ${total} discovered</small></h3>${rows}</section>`;
  }
  function chapterEnd(n) {
    return new Promise(res => {
      hideAll();
      const f = $('flow'); f.hidden = false;
      f.innerHTML = '<h2>CHAPTER COMPLETE</h2>' + flowHTML(n.chapter) +
        '<p class="hint">Locked boxes are things that did not happen in this playthrough.</p>';
      const b = el('button', 'big', 'CONTINUE');
      b.onclick = () => { keyDown = null; f.hidden = true; res(); };
      keyDown = (k, rep) => { if (!rep && k === 'ENTER') b.onclick(); };
      f.append(b); f.scrollTop = 0;
    });
  }

  /* ── node handlers ── */
  const resolve = (next, r) => typeof next === 'function' ? next(s, r) : next;
  const H = {
    async card(n) {
      hideAll();
      const c = $('card'); c.innerHTML = ''; c.hidden = false;
      tone(62, 0.7, 'sine', 0.3); setTimeout(() => tone(46, 0.9, 'sine', 0.3), 180);
      for (const l of resolve(n.lines)) {
        const d = el('div'); c.append(d);
        for (const ch of l) { d.textContent += ch; await sleep(20); }
        await sleep(220);
      }
      await waitAdvance(3000);
      c.hidden = true;
      return n.next;
    },
    async scene(n) {
      hideAll();
      if (n.do) n.do(s);
      updateHud();
      for (const [who, text] of resolve(n.beats)) await say(who, text);
      return resolve(n.next);
    },
    async choice(n) {
      const pick = await choose(n);
      tone(440, 0.08, 'triangle');
      if (pick.do) pick.do(s);
      return pick.next;
    },
    async investigate(n) { await investigate(n); return n.next; },
    async qte(n) {
      const r = await qte(n);
      if (n.do) n.do(s, r);
      return resolve(n.next, r);
    },
    async branch(n) { return n.next(s); },
    async chapterEnd(n) { await chapterEnd(n); return n.next; },
    async ending(n) {
      hideAll();
      const f = $('flow'); f.hidden = false;
      const stat = (k, v) => `<div><span>${k}</span><b>${v}</b></div>`;
      f.innerHTML = `<h2 class="verdict">${n.title}</h2><p class="endtext">${n.text(s)}</p>
        <div class="stats">
          ${stat('TESSA BRANDT', s.f.tessa === 'safe' ? 'Safe' : 'Hospitalized')}
          ${stat('WADE HARLAN', s.f.harlanDead ? 'Deceased' : s.f.fugitive ? 'At large' : 'In custody')}
          ${s.f.wentEx ? stat('EVAN KESSLER', s.f.wrong ? 'Wrongly charged' : 'Cleared') : ''}
          ${stat('DET. REYES', (s.f.reyesHurt ? 'Injured · ' : '') + (s.trust >= 2 ? 'Trusts you' : s.trust < 0 ? 'Has doubts' : 'Still your partner'))}
          ${stat('CASE STRENGTH', s.strength + '%')}
          ${stat('EVIDENCE', Object.keys(s.clues).length + ' / 8')}
        </div>` + [1, 2, 3, 4].map(flowHTML).join('');
      const b = el('button', 'big', 'NEW CASE FILE — PLAY AGAIN');
      b.onclick = () => { location.href = location.pathname; };
      f.append(b); f.scrollTop = 0;
      return null;
    },
  };

  async function run(id) {
    while (id) {
      const n = N[id];
      if (!n) throw new Error('Missing story node: ' + id);
      s.seen[id] = 1;
      if (n.chapter) s.chapter = n.chapter;
      if (n.bg) setBg(n.bg);
      updateHud();
      id = await H[n.type](n);
    }
  }

  function begin(id) {
    try { actx = new (window.AudioContext || window.webkitAudioContext)(); } catch (e) { actx = null; }
    s = newState(notify);
    $('title').hidden = true; $('hud').hidden = false;
    run(id).catch(err => { console.error(err); $('text').textContent = 'Engine error: ' + err.message; $('dialog').hidden = false; });
  }

  setBg('title');
  $('startBtn').onclick = () => begin(start);
  if (params.get('at')) begin(params.get('at'));
})();
