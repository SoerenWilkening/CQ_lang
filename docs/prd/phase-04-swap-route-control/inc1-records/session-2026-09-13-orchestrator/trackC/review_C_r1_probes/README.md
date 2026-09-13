# Track C review r1 probes (2026-09-13, independent reviewer)

36 `.c` probes, run on BOTH binaries by `run_r1.sh` (ORACLE
`/Users/sorenwilkening/Desktop/CQ_lang/build`, `cq-opt fbbe0820…`; SUBJECT
`/Users/sorenwilkening/Desktop/CQ_21mg/build`, `cq-opt c662bd0c…`, both hashes
verified on disk). Output: `results_r1_c662bd0ca0e7d8a4.txt` — one row per
`(probe, binary)`: `exit=N` + the first `error:` line, or on accept the gate
census `M=<cqrt_measure_> A=<cqrt_alloc_> R=<cqrt_ry_> Z=<cqrt_rz_>` plus the
lowered-IR md5.

Usage: `./run_r1.sh r*.c`  (also accepts `.ll`).

**25 of 36 rows are BYTE-IDENTICAL between the binaries. 11 are movers, every one
DECLINE→ACCEPT on `cq_measure_<sfx> operand not recognized; expected a tainted
i32 handle` with a genuinely CLASSICAL operand.** Groups:

* `r01`–`r08`, `r30` — item 1: a quantum register measured through each RAUW in
  the window (6.5 `%out` and a value derived from it, the 4.4 select merge, the
  value-arm merge, the 4.5 switch merge, M-β in-place Ry, M-β state prep, an
  in-loop collapsed rail, a depth-2 nest merge). All identical.
* `r13`–`r16` — the region CONDITION measured (the `scrubTaint` worry). `r13`/
  `r14`/`r15` identical (the compare lowers to a flag handle and is measured
  through it); `r16` declines `condition used outside the branch` on both.
* `r23`–`r25` — quantum through memory: a local array at a classical index, a
  tainted-index QRAM read, a guarded shadow store. All identical.
* `r17`, `r19`, `r21`, `r31`–`r36` — declines, identical on both binaries:
  specialization lift, switch case, select operand, break loop, and the four
  in-arm classical-measure shapes (item 4 / verdict (c) neighbourhood).
* `r09`–`r12`, `r18`, `r20`, `r22`, `r26`–`r29` — the movers: measure-of-measure,
  a theta seed, a classical `double` angle, an undef φ (`-O1` folds it), a
  classical measure in a noinline callee, in a loop body, a `float`/`long double`,
  a classical array element, an external-linkage argument, a volatile local, a
  global. Verified classical one by one; `r11`/`r22` additionally verified to mint
  NO fp rail.

Findings written up in `../review_C_r1.md`.
