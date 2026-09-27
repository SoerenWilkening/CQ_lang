import pathlib
import shutil

V = pathlib.Path(__file__).parent
R = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16')
T = R / 'TRACK_VSFP.md'
t = T.read_text()
assert '# ROUND 6 (2026-09-27)' not in t
old = '''- ⚠ **And on round 4: ROUND 5 follows §R4 (§R5)** — narrow: bd 91k9 (the rewrite keeps pointer/byval
  slots) and bd qce6 (the implicit section; the address space). Read §R2 → §R3 → §R4 → §R5.'''
new = old + '''
- ⚠ **And on round 5: ROUND 6 follows §R5 (§R6)** — narrow: bd w7nm (the slot question is NULL-SOUNDNESS,
  `nullSafeSlot`, never the drop's `musttail` policy) and one slot question for every consumer.'''
assert t.count(old) == 1
t = t.replace(old, new)
t = t.rstrip('\n') + '\n' + (V / 'r6_track_section.md').read_text()
T.write_text(t)

D = R / 'vsfp_probes/r6'
for sub in ('tools', 'results', 'src'):
    (D / sub).mkdir(parents=True, exist_ok=True)
n = 0
for f in ['r6edit.py', 'r6edit_cmake.py', 'r6edit_hdr.py', 'mkgold6.py', 'mkfix6_body.py', 'mkfix6_tail.py',
          'mkfix6.py', 'mutants6.py', 'redgreen6.sh', 'r6_rerun_reviews.sh', 'buildcorp6.py', 'r4pairs.py',
          'ab.py', 'movcat.py', 'mutmatrix.sh', 'h.py', 'r6_track_append.py']:
    shutil.copy(V / f, D / 'tools' / f); n += 1
shutil.copy(V / 'r6/w2probe.ll', D / 'src/w2probe.ll'); n += 1
for f in ['r6_r5rev_results.txt', 'r6_r4A_results.txt', 'ab9_null.txt', 'ab9_delta.txt', 'ab9_run.log',
          'mutmatrix_r6.txt', 'mutants6_build.log', 'w2_r6.ll', 'w2_w2.ll']:
    shutil.copy(V / f, D / 'results' / f); n += 1
print('ok', n)
