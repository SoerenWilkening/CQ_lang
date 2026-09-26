#!/usr/bin/env python3
"""Copy the round-2 probes, tools and results into the committed record
(vsfp_probes/r2/), so every number in TRACK_VSFP §R2 is reproducible."""
import pathlib
import shutil

V = pathlib.Path(__file__).parent
D = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/vsfp_probes/r2')
for sub in ('tools', 'src/fx', 'src/ll', 'src/battery', 'src/r3', 'results'):
    (D / sub).mkdir(parents=True, exist_ok=True)
n = 0
TOOLS = ['h.py', 'pp.sh', 'r2bat.sh', 'mkfix2.py', 'twin.py', 'census2.py', 'mutants2.py', 'mutmatrix.sh',
         'litmov.py', 'cmpll.py', 'tryll.py', 'compose2_respell.sh', 'respell2.py', 'respell2b.py',
         'respell_compose.py', 'ab.py', 'movers.py', 'movcat.py', 'otrace.py', 'buildcorp.py', 'cat_src.py',
         'sync_to_comp.py', 'export_r2.py', 'e2enew.sh', 'fxshow.py', 'redgreen.sh', 'stale_control.sh',
         'render_mut.py', 'r2_fill.py', 'showfn.py', 'dupscan.py']
for t in TOOLS:
    if (V / t).exists():
        shutil.copy(V / t, D / 'tools' / t); n += 1
shutil.copy(V / 'fx/gen2.py', D / 'tools/gen2.py'); n += 1
for pat, sub in (('fx/*.c', 'src/fx'), ('ll/*.ll', 'src/ll'), ('r2src/*.c', 'src/battery'), ('r3/*.c', 'src/r3')):
    for f in V.glob(pat):
        shutil.copy(f, D / sub / f.name); n += 1
RESULTS = ['r2bat_r2g.txt', 'r2bat_main.txt', 'r2bat_v5.txt', 'r2bat_comp3.txt',
           'ab4_null.txt', 'ab4_delta.txt', 'ab4_final.txt', 'ab2_r1r2.txt', 'ab3_delta.txt',
           'ab_comp3_null.txt', 'ab_comp2_comp3.txt', 'ab_9bhg_comp3.txt',
           'twin2_final.txt', 'twin2_final.log', 'twin_comp2.txt', 'twin_comp2.log', 'hand_list.txt',
           'census4_lit.txt', 'census4_e2e.txt', 'mutmatrix4.txt', 'mutmatrix5.txt', 'mutants4_build.log',
           'rg_main.log', 'rg_v5.log', 'rg_r2g.log', 'family_regex.txt', 'stale_debugalloc.txt',
           'equiv_full.txt', 'compose2_9bhg_fixture_respell.patch']
for r in RESULTS:
    if (V / r).exists():
        shutil.copy(V / r, D / 'results' / r); n += 1
    else:
        print('MISSING', r)
(D / 'README.md').write_text(
    "# bd vsfp round 2 — probes, tools, results\n\n"
    "Copied from the session scratchpad; the tools carry that scratchpad's absolute paths and say so.\n"
    "`src/battery/` is the r1A + r1B probe set (with r1B's v27-v30, absent from its committed probes\n"
    "dir) and the r2A twins the battery pairs against; `src/fx/` the round-2 fixture sources\n"
    "(`tools/gen2.py` builds them, `tools/mkfix2.py` writes the fixtures); `src/ll/` the hand-written\n"
    "modules; `src/r3/` the fenv-emptied-arm probes. Binary tags in the results: `main` = ORACLE\n"
    "`aee8f4f8`, `v5` = round 1 `5e56060b`, `r2`/`r2f`/`r2g` = round-2 increments (`r2g` = SUBJECT),\n"
    "`comp2`/`comp3` = composed with bd 9bhg. See TRACK_VSFP.md §R2.\n")
print('copied', n)
