#!/usr/bin/env python3
"""Copy round 3's probes, tools and results into the committed record (vsfp_probes/r3/)."""
import pathlib
import shutil

V = pathlib.Path(__file__).parent
D = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/vsfp_probes/r3')
for sub in ('tools', 'src/probes', 'src/ll', 'src/fx', 'results'):
    (D / sub).mkdir(parents=True, exist_ok=True)
n = 0
TOOLS = ['h.py', 'pp.sh', 'r2bat.sh', 'r3bat.py', 'mkfix3.py', 'mkfix3_head.py', 'mkfix3_body.py', 'mkfix3_tail.py',
         'mutants3.py', 'mutmatrix.sh', 'redgreen3.sh', 'stale_control.sh', 'ab.py', 'movcat.py', 'movers.py',
         'otrace.py', 'buildcorp3.py', 'litmov3.py', 'classify3.py', 'mkbranch.py', 'trll.py', 'tryll.py',
         'stage_r3.py', 'mkgold3.py', 'add_eqphi.py', 'r3_fill.py', 'export_r3.py', 'bead_g12.py',
         'r3edit_qram.py', 'r3edit_orch.py', 'r3edit_spec.py', 'r3edit_shim.py', 'r3edit_cmake.py',
         'r3fix_callchecks.py', 'r3_track_marks.py', 'r3_track_fix2.py']
for t in TOOLS:
    if (V / t).exists():
        shutil.copy(V / t, D / 'tools' / t); n += 1
    else:
        print('MISSING tool', t)
for f in (V / 'r3p').glob('*.c'):
    if f.name in ('k11H.c', 'eqphi.c', 'eqphiT.c'):
        shutil.copy(f, D / 'src/probes' / f.name); n += 1  # round 3's OWN probes; the rest are the reviewers'
for f in V.glob('ll/*_branch.ll'):
    shutil.copy(f, D / 'src/ll' / f.name); n += 1
for f in V.glob('fx/r3_*'):
    if f.suffix == '.c':
        shutil.copy(f, D / 'src/fx' / f.name); n += 1
for r in ['r3bat_r3a.txt', 'r3bat_r2g.txt', 'r3bat_v5.txt', 'r3bat_main.txt', 'mutmatrix_r3.txt', 'mutmatrix_r3b.txt',
          'mutants3r_build.log', 'ab5_null.txt', 'ab5_final.txt', 'ab5_delta.txt', 'classify3_out.txt',
          'rg3_main.log', 'rg3_v5.log', 'rg3_r2g.log', 'rg3_r3a.log', 'ctest_r3.txt', 'corp3_all.txt']:
    if (V / r).exists():
        shutil.copy(V / r, D / 'results' / r); n += 1
    else:
        print('MISSING result', r)
(D / 'README.md').write_text(
    "# bd vsfp round 3 — tools, own probes, results\n\n"
    "Copied from the session scratchpad; the tools carry that scratchpad's absolute paths and say so.\n"
    "The reviewers' probes are in `../../review_r2A_vsfp/probes/` and `../../review_r2B_vsfp/probes/src/`\n"
    "(the battery reads a merged copy); `src/probes/` holds only round 3's own additions (`k11H`, a fully\n"
    "inlined twin for r2B `k11`; `eqphi`/`eqphiT`, the S2 pin). `src/ll/*_branch.ll` are the IR-only\n"
    "branch-read spellings (`tools/mkbranch.py`). Binary tags: `main` ORACLE, `v5` round 1, `r2g` round 2,\n"
    "`r3a` SUBJECT (round 3). See TRACK_VSFP.md §R3.\n")
print('copied', n)
