# bd vsfp round 2 — probes, tools, results

Copied from the session scratchpad; the tools carry that scratchpad's absolute paths and say so.
`src/battery/` is the r1A + r1B probe set (with r1B's v27-v30, absent from its committed probes
dir) and the r2A twins the battery pairs against; `src/fx/` the round-2 fixture sources
(`tools/gen2.py` builds them, `tools/mkfix2.py` writes the fixtures); `src/ll/` the hand-written
modules; `src/r3/` the fenv-emptied-arm probes. Binary tags in the results: `main` = ORACLE
`aee8f4f8`, `v5` = round 1 `5e56060b`, `r2`/`r2f`/`r2g` = round-2 increments (`r2g` = SUBJECT),
`comp2`/`comp3` = composed with bd 9bhg. See TRACK_VSFP.md §R2.
