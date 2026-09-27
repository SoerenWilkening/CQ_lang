#!/usr/bin/env python3
"""Fill r3_track_section.md from fill3/*.md + scalars and append it to TRACK_VSFP.md once."""
import pathlib

V = pathlib.Path(__file__).parent
T = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/TRACK_VSFP.md')
s = (V / 'r3_track_section.md').read_text()
vals = {'SUBJ': '3cb890ef25187b4b', 'LIB': '2764c64abcc871bc', 'DBG': 'ce5fbf89cd8f5f82', 'NLIT': '2378'}
for f in (V / 'fill3').glob('*.md'):
    vals[f.stem] = f.read_text().rstrip('\n')
for k, v in vals.items():
    s = s.replace('@@' + k + '@@', v)
left = s.split('@@')[1::2]
if left:
    raise SystemExit('unfilled: ' + ', '.join(sorted(set(left))))
t = T.read_text()
if '# ROUND 3 (2026-09-26)' in t:
    raise SystemExit('already appended')
T.write_text(t.rstrip('\n') + '\n' + s)
print('appended', len(s))
