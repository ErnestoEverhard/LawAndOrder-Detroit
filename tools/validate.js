#!/usr/bin/env node
/* Walks the story graph headlessly: checks every static link resolves, then plays
   thousands of random runs to confirm no dead ends and that every ending is reachable. */
const { nodes: N, flow, start, newState } = require('../story.js');
const rnd = n => Math.floor(Math.random() * n);
const res = (v, ...a) => typeof v === 'function' ? v(...a) : v;
let errors = 0;
const err = m => { errors++; console.error('ERROR: ' + m); };

for (const [id, n] of Object.entries(N)) {
  const targets = [];
  if (typeof n.next === 'string') targets.push(n.next);
  if (n.options) n.options.forEach(o => targets.push(o.next));
  if (n.timeout) targets.push(n.timeout.next);
  targets.forEach(t => { if (!N[t]) err(`${id} -> missing node "${t}"`); });
  if (n.type !== 'ending' && n.next == null && !n.options) err(`${id} has no exit`);
}

const endings = {}, seenAll = {};
const RUNS = 20000;
for (let i = 0; i < RUNS && !errors; i++) {
  const s = newState();
  const skill = Math.random(); // how good this simulated player is at QTEs
  let id = start, steps = 0;
  try {
    while (id) {
      const n = N[id];
      if (!n) { err(`run reached missing node "${id}"`); break; }
      if (++steps > 500) { err('loop detected at ' + id); break; }
      s.seen[id] = 1;
      if (n.chapter) s.chapter = n.chapter;
      if (n.type === 'ending') { n.text(s); endings[id] = (endings[id] || 0) + 1; break; }
      if (n.type === 'card') { res(n.lines, s); id = n.next; }
      else if (n.type === 'scene') { if (n.do) n.do(s); res(n.beats, s).forEach(b => { if (!Array.isArray(b) || b.length !== 2) throw new Error('bad beat in ' + id); }); id = res(n.next, s); }
      else if (n.type === 'choice') {
        const ok = n.options.filter(o => !o.req || o.req(s));
        const pick = Math.random() < 0.1 ? n.timeout : ok[rnd(ok.length)];
        if (pick.do) pick.do(s);
        id = pick.next;
      } else if (n.type === 'investigate') {
        const pool = [...n.hotspots].sort(() => Math.random() - 0.5).slice(0, rnd(n.budget + 1));
        pool.forEach(h => h.do && h.do(s));
        id = n.next;
      } else if (n.type === 'qte') {
        if (n.scale) n.scale(s);
        const r = { fails: n.steps.filter(() => Math.random() > skill).length };
        if (n.do) n.do(s, r);
        id = res(n.next, s, r);
      } else if (n.type === 'branch') id = n.next(s);
      else if (n.type === 'chapterEnd') id = n.next;
      else { err(`unknown node type "${n.type}" at ${id}`); break; }
    }
  } catch (e) { err(`run crashed at ${id}: ${e.message}`); }
  Object.assign(seenAll, s.seen);
}

const allEndings = Object.keys(N).filter(k => N[k].type === 'ending');
allEndings.forEach(e => { if (!endings[e]) err(`ending "${e}" never reached`); });
Object.keys(N).forEach(k => { if (!seenAll[k]) err(`node "${k}" never reached`); });
Object.values(flow).forEach(f => f.rows.flat().forEach(([id]) => { if (!seenAll[id]) err(`flowchart id "${id}" never marked`); }));

console.log(`${Object.keys(N).length} nodes, ${RUNS} random runs`);
allEndings.forEach(e => console.log(`  ${e.padEnd(12)} ${((endings[e] || 0) / RUNS * 100).toFixed(1)}%`));
console.log(errors ? `FAILED with ${errors} error(s)` : 'OK');
process.exit(errors ? 1 : 0);
