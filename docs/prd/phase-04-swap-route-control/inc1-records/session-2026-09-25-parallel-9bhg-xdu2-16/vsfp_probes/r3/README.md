# bd vsfp round 3 — tools, own probes, results

Copied from the session scratchpad; the tools carry that scratchpad's absolute paths and say so.
The reviewers' probes are in `../../review_r2A_vsfp/probes/` and `../../review_r2B_vsfp/probes/src/`
(the battery reads a merged copy); `src/probes/` holds only round 3's own additions (`k11H`, a fully
inlined twin for r2B `k11`; `eqphi`/`eqphiT`, the S2 pin). `src/ll/*_branch.ll` are the IR-only
branch-read spellings (`tools/mkbranch.py`). Binary tags: `main` ORACLE, `v5` round 1, `r2g` round 2,
`r3a` SUBJECT (round 3). See TRACK_VSFP.md §R3.
