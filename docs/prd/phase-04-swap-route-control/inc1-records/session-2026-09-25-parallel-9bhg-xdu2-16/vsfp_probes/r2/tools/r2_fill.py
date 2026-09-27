#!/usr/bin/env python3
"""Fill the @@...@@ placeholders of r2_track_section.md from fill/*.md and a dict,
then append the section to TRACK_VSFP.md (once)."""
import pathlib
import sys

V = pathlib.Path(__file__).parent
T = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/TRACK_VSFP.md')
s = (V / 'r2_track_section.md').read_text()
vals = {}
for f in sorted((V / 'fill').glob('*.md')):
    vals[f.stem] = f.read_text().rstrip('\n')
for line in (V / 'fill/scalars.txt').read_text().splitlines():
    if '=' in line:
        k, v = line.split('=', 1)
        vals[k.strip()] = v.strip()
for k, v in vals.items():
    s = s.replace('@@' + k + '@@', v)
left = [x for x in s.split('@@')[1::2]]
if left:
    raise SystemExit('unfilled: ' + ', '.join(sorted(set(left))))
t = T.read_text()
if '# ROUND 2 (2026-09-26)' in t:
    raise SystemExit('already appended')
T.write_text(t.rstrip('\n') + '\n' + s)
print('appended', len(s))
