# probes — provenance, so no file here is read as this agent's own measurement when it is not

**From the Rule-13 reviewer** (`review_r13_loop/probes/`, copied verbatim, re-measured here on the
merged binaries): `n1_nested_marked_inner`, `n2_nested_unmarked_inner`, `n3_nested_iic_inner` and
their `_un` twins; `t5a_nobreak{,_un}`, `t5b_break_split`; `x1_iic_bodyrail_interfered{,_un}`,
`x8_iic_preheader_chain{,_un}`, `x9_iic_preheader_chain_interfered{,_un}`.

**From Track T** (`trackT/probes/adv/`, copied for the fixture that needed it): `a9_nested_loop.c`.
`r1_break_loop{,_un}.c` was used from its own directory and is not duplicated here.

**Written by this agent:**

* `c1_cmp_rail_data{,_un}.c`, `c2_inloop_rotation{,_un}.c` — the two programs whose shipped DECLINE
  fixtures the merge silently retired (FIX.md §1a). Each is the fixture's own quoted source, plus a
  hand-unrolled twin, so the conversion is a re-derivation and not a re-baseline.
* `r1_triple_nest_mid_rail{,_un}.c` — Rule-13 re-attack at depth 3. **Became a fixture**: it is a
  fourth F-1 customer whose rolled and unrolled TRACE LINE COUNTS AGREE (72 = 72) while the gate
  MULTISET does not.
* `r2_outer_marked_inner_rail{,_un}.c` — the opposite nesting (ancestor marked, inner rail).
* `r3_nested_cmp_rail_outer{,_un}.c` — this fix × Track S′'s conjunct-(3) `icmp`-as-data widening.
* `r4_nested_inbody_interference{,_un}.c` — this fix × Track S′'s dropped `L->contains` skip.
  Unreachable: declines earlier at a taint-escape fence on both binaries.
* `r5_sibling_loops_one_marked{,_un}.c` — sibling (non-nested) loops, the containment control.

**Harnesses**

* `lv.sh` — ORACLE vs the `CQ_LOOPFIX` build, one stage-1 module per program, linked against each
  build's own runtime archives. Self-guarded: a 0-byte or quantum-free `.c` reports
  `VACUOUS-NO-QUANTUM`, never ACCEPT (bd memory `empty-module-accepts-vacuity-trap`); `A:LINKFAIL`
  and `BROKEN-EMPTY-OUTPUT` are their own tags. ⚠ Kept in a PRIVATE scratch subdirectory while
  running — the reviewer records another agent's same-named script overwriting theirs on a shared
  path and nearly producing a fabricated table.
* `sweep.sh` — one binary over every `ir-pass/test/*.ll`, verdict + diagnostic string. ⚠ **Its first
  spelling reported "0 movers" while every row was exit 127.** It now REFUSES to emit a file unless
  the binary and plugin exist at the path given, no row is 127, and both verdicts actually occur —
  and the refusal is self-attacked. Read FIX.md §4 before trusting any sweep in this tree.
* `sweep_{oracle,prefix,fixed}.txt` — the three committed sweep results (2051 rows each) the mover
  tables in FIX.md §2 and GATES.md G8 are computed from.
