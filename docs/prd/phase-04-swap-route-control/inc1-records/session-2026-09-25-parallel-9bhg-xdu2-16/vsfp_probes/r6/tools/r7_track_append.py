import pathlib

V = pathlib.Path(__file__).parent
T = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/TRACK_VSFP.md')
t = T.read_text()
assert '# ROUND 7 (2026-09-27)' not in t
old = '''- ⚠ **And on round 5: ROUND 6 follows §R5 (§R6)** — narrow: bd w7nm (the slot question is NULL-SOUNDNESS,
  `nullSafeSlot`, never the drop's `musttail` policy) and one slot question for every consumer.'''
new = old + '''
- ✅ **Round 6 CLEARED (r6: CLEAR-WITH-ITEMS, 0 P1). §R7 is the LANDING summary** — rounds 1–6 in one table,
  the open follow-ups, and the owner rulings used. Read §R7 first; the §R sections are the history.'''
assert t.count(old) == 1
t = t.replace(old, new)
t = t.rstrip('\n') + '\n' + (V / 'r7_track_section.md').read_text()
T.write_text(t)
print('ok')
