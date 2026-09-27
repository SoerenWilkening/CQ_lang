#!/usr/bin/env python3
"""Fill r4_track_section.md and append it to TRACK_VSFP.md once."""
import pathlib

V = pathlib.Path(__file__).parent
T = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/TRACK_VSFP.md')
s = (V / 'r4_track_section.md').read_text()
vals = {'SUBJ': '829769d92e05c4e4', 'LIB': 'efe38e3f619250b9', 'DBG': '03ba76c1b2a3a37d', 'NLIT': '2398',
        'NNEW': '20', 'NMOD': '2',
        'REDGREEN': 'ORACLE 5/22 PASS, ROUND 1 5/22, ROUND 2 4/22, ROUND 3 2/22, SUBJECT 22/22 — every one '
                    'of the 20 new files RED on ROUND 3 (with round 3\'s own debugalloc for the `nofree` '
                    'lines) and GREEN on the SUBJECT; details §R4.10.'}
for f in (V / 'fill4').glob('*.md'):
    vals[f.stem] = f.read_text().rstrip('\n')
for k, v in vals.items():
    s = s.replace('@@' + k + '@@', v)
left = s.split('@@')[1::2]
if left:
    raise SystemExit('unfilled: ' + ', '.join(sorted(set(left))))
t = T.read_text()
if '# ROUND 4 (2026-09-27)' in t:
    raise SystemExit('already appended')
T.write_text(t.rstrip('\n') + '\n' + s)
print('appended', len(s))
