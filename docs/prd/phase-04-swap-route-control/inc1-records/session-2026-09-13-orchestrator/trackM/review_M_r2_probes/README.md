# Track M — Rule-13 review round 2, probes

Runner `./run.sh` (per-probe pipeline: stages 1, 2, 2b, 3, 4; SUBJECT then ORACLE; it refuses to run if
either binary's sha256 has moved). SUBJECT `0d3105d0…` (`GATES.md`, round-1-FIX rows), ORACLE `fbbe0820…`
(`PROTOCOL.md`). Scratch:
`/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/…/scratchpad/trackM_review2/`.

| probe | question | SUBJECT | ORACLE |
|---|---|---|---|
| `r03_order_third_region.c` (copy of the r1 probe) | F-M1's own customer, re-measured | ACCEPT 33, 2b 3/3 verified | DECLINE `control flow` |
| `q01_kickback_before_prep.c` | item 1(b): a bare-`i1` kickback BEFORE the prep | DECLINE `branch phase on a bare i1 condition` | identical |
| `q02_two_selects_one_phi.c` | item 1(c): two selects on ONE prep φ | ACCEPT 45, 2b 4/4 verified | DECLINE `control flow` |
| `q03_select_phi_is_kickback_pred.c` | item 1(c): the prep with TWO outgoing edges of two kinds | ACCEPT 34, 2b 3/3 verified | DECLINE `control flow` |
| `q04_region_before_prep.c` | item 1(b), take 2: a COMPARE kickback before the prep | DECLINE `control flow` | identical |
| `q05_two_preps_two_selects.c` | two prep+select pairs chained | DECLINE `state prep seed is proven equal to the condition register` | identical |
| `q06_rail_kickback_before_prep.c` | item 1(b), take 3: a RAIL kickback before the prep | DECLINE `control flow` | identical |
| `q07_round2_third_region.c` (+ `_lib.c`) | item 1(d): the round-2 `%out` window with a THIRD region | DECLINE `control flow`, exactly ONE `error:` | identical |

Two instruments, both written for this round:

* `negcoverage.py` — item 3. Derives the USER REGISTERS and the ANCILLAS **from the lowered IR** (no hand
  list) and asks of each `NOX-NOT`/`NOFREE-NOT` whether it is undefined, points at an ancilla, or leaves a
  user register uncovered. Run: `python3 negcoverage.py`.
* `rz_mutation.sh` — F2-1. Applies four mutations to the branch phase's `cqrt_rz_i1` (target → `%h`,
  `%h4`, `%out3`; angle 0.3 → 0.9) in the lowered output of
  `control_swap_accept_select_mergephi_rail_then_kickback.ll` and runs **every** prefix the fixture
  declares against each mutant. It prints the unmutated file first as a control (which must read MISSED —
  that is the baseline all-green). All four mutants: **MISSED by all 11 prefixes.**
