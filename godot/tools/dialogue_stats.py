#!/usr/bin/env python3
"""Measure the spoken lines in story.gd against the targets in .claude/skills/svu-dialogue.
   python3 godot/tools/dialogue_stats.py [--long]   (--long lists every sentence over 15 words)"""
import re, sys, pathlib
src = (pathlib.Path(__file__).parent.parent / "story.gd").read_text()
lines = re.findall(r'\["([A-Z]+)",\s*"((?:[^"\\]|\\.)*)"', src)
sents = []
for who, text in lines:
    text = re.sub(r'^\([^)]*\)\s*', '', text.replace('\\"', '"'))
    for s in re.split(r'(?<=[.?!])["”]?\s+(?=["“A-Z])', text):
        if re.search('[a-z]', s, re.I):
            sents.append((who, s.strip()))
wc = lambda s: len(s.split())
n = len(sents); W = sorted(wc(s) for _, s in sents)
pct = lambda f: round(100 * sum(1 for _, s in sents if f(s)) / n, 1)
print(f"lines {len(lines)}  sentences {n}  words {sum(W)}")
print(f"words per sentence: mean {sum(W)/n:.1f} (show 6.4)  median {W[n//2]} (show 5)")
print(f"3 words or fewer: {pct(lambda s: wc(s) <= 3)}% (show 30)   over 15 words: {pct(lambda s: wc(s) > 15)}% (show 5)")
print(f"questions: {pct(lambda s: s.rstrip('\"').endswith('?'))}% (show 20)")
lw = sorted(sum(wc(s) for s in re.split(r'(?<=[.?!])\s+', t)) for _, t in lines)
print(f"words per line: median {lw[len(lw)//2]}  longest {lw[-1]}")
if "--long" in sys.argv:
    for who, s in sents:
        if wc(s) > 15: print(f"  {wc(s):2} {who}: {s}")
