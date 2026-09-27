#!/usr/bin/env python3
"""Copy round 4's tools, own probes and results into the committed record (vsfp_probes/r4/)."""
import pathlib
import shutil

V = pathlib.Path(__file__).parent
D = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/vsfp_probes/r4')
for sub in ('tools', 'src', 'results'):
    (D / sub).mkdir(parents=True, exist_ok=True)
n = 0
TOOLS = ['h.py', 'r4pairs.py', 'r4bat.py', 'r3bat.py', 'mkfix4.py', 'mkfix4_body.py', 'mkfix4_tail.py', 'mkfix3_head.py',
         'mutants4.py', 'mutmatrix.sh', 'redgreen4.sh', 'stale_control.sh', 'uafpin.sh', 'ab.py', 'movcat.py',
         'otrace.py', 'buildcorp4.py', 'litmov3.py', 'classify4.py', 'stage_r4.py', 'mkgold4.py', 'mk_mkgold4.py',
         'r4_fill.py', 'export_r4.py', 'post_notes4.py', 'r4edit_reader.py', 'r4edit_sqjq.py', 'r4edit_ruling.py',
         'r4edit_claims.py', 'r4edit_doc.py', 'r4edit_helper.py', 'r4edit_cmake.py']
for t in TOOLS:
    if (V / t).exists():
        shutil.copy(V / t, D / 'tools' / t); n += 1
    else:
        print('MISSING tool', t)
for f in ['r4b/u1T.ll', 'r4b/u2T.ll', 'r4b/u3T.c', 'r4b/u4T.c', 'r4b/u5T.c', 'r4b/u6.c', 'r4b/u6T.c',
          'r4c/sect.c', 'r4c/sectT.c', 'r4c/nosect.c', 'r4c/abs.ll', 'r4c/n6_nested_arg.ll']:
    shutil.copy(V / f, D / 'src' / f.replace('/', '__')); n += 1
for r in ['r4bat_r4f.txt', 'r4bat_r4a.txt', 'r4bat_r3a.txt', 'r4bat_main.txt', 'mutmatrix_r4.txt', 'mutmatrix_r4f.txt',
          'mutants4r_build.log', 'mutants4f_build.log', 'ab7_null.txt', 'ab7_final.txt', 'ab7_delta.txt',
          'rg4_main.log', 'rg4_v5.log', 'rg4_r2g.log', 'rg4_r3a.log', 'rg4_r4f.log', 'ctest_r4.txt', 'corp4_all.txt',
          'stale_debugalloc.txt']:
    if (V / r).exists():
        shutil.copy(V / r, D / 'results' / r); n += 1
    else:
        print('MISSING result', r)
(D / 'README.md').write_text(
    "# bd vsfp round 4 — tools, own probes, results\n\n"
    "Copied from the session scratchpad; the tools carry that scratchpad's absolute paths. The reviewers'\n"
    "probes are in `../../review_r3A_vsfp/probes/src/` and `../../review_r3B_vsfp/probes/src/` (the\n"
    "battery reads copies in `r4a/` and `r4b/`); `src/` holds round 4's own twins and probes (`u1T`/`u2T`\n"
    "twins of r3B's IR repros, `u3T`–`u5T`, `u6`/`u6T` — the WeakVH separator — the section / absolute-symbol\n"
    "probes and `n6_nested_arg`). Binary tags: `main` ORACLE, `v5` round 1, `r2g` round 2, `r3a` round 3,\n"
    "`r4a` an intermediate round-4 build, `r4f` the SUBJECT. `uafpin.sh`'s output is in TRACK §R4.2.\n"
    "See TRACK_VSFP.md §R4.\n")
print('copied', n)
