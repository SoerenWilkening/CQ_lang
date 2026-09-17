# probes — provenance, so no file here is read as this reviewer's own measurement when it is not

**Written by this reviewer** (session 2026-09-18 Rule-13 review), all measured on the ORACLE
`9bd01598d574b344` only:

* `a1`–`a5` + `_un` twins — one-operand attacks on the `c1_cmp_rail_data` conversion.
* `b1`–`b6` + `_un` twins — one-operand attacks on the `c2_inloop_rotation` conversion.
* `r1_triple_deeper.c` — the `emkg` conjunct-(1) shape at **depth 4**.
* `r3_outer_rail_inner_marked_nodeeper.c` — `r3` with the outer rail made interior by accumulation.
* `t5c_classical_break_taken.c` + `t5c_ref_{two,three}_trips.c` — **the break-path witness bd
  `tu9q.1` says does not exist**: the break predicate is classical (from `argc`) so the runtime
  takes it, and the reference is the straight-line program the loop denotes at that break point.
* `t5d`/`t5e` — `t5b`'s shapes with classical predicates (they still die at bd `3d8q`).
* `t5f`/`t5g` + `t5f_ref_lim2.c` — the same without the post-loop rotation, so `3d8q` cannot preempt.
  `t5f` is a genuine MULTI-EXIT loop in the lowered IR and is correct.
* `t5h_rail_straddles_break{,_rot}.c` + `t5h_ref_lim2.c`, `t5i_straddle_nobreak{,_un,_rot}.c`,
  `t5j_twoblock_noexit_rot.c`, `t5k_twoblock_unmarked_control.c` — **F-1 and its three isolating
  controls.** `t5j` is the witness, `t5i_rot` the one-block control that discharges, `t5k` the
  unmarked control that declines.

**Harnesses**

* `lv.sh` — one `.c` through the ORACLE per-probe pipeline. Self-attacked before use: a 0-byte and a
  quantum-free `.c` report `VACUOUS-*`, never ACCEPT (bd memory `empty-module-accepts-vacuity-trap`).
  ⚠ Its first spelling ran `free_pairing_check.py` on a RELATIVE path after `cd`-ing to the repo and
  printed `cannot read …` **while still scoring the row ACCEPT**; it now exits 2 on that
  (`INSTRUMENT-BROKEN-2B`). Kept in a private scratch directory while running — the 2026-09-15
  reviewer records another agent's same-named script on a shared path nearly producing a fabricated
  table.
* `argsweep.sh` — trip counts vs `argc` for `t5c`. ⚠ **`#!/bin/bash`, deliberately.** The zsh
  spelling used an unquoted `$args`, **zsh does not word-split an unquoted parameter**, every row
  passed ONE argument, and the table read `lim=4 → 3 trips` — indistinguishable from a dropped loop
  trip. See REVIEW.md F-4.

`traces/` holds the runtime trace of every accepting probe above, as measured. Sources and traces
only — no `.ll`, no binaries.
