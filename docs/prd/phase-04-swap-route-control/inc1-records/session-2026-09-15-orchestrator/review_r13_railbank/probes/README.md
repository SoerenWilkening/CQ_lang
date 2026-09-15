# Reviewer probes — Rule-13 review of Track B (rail-bank W1 second half)

`./run.sh <probe>.c`, run from **any** directory. It compiles stage 1 with
`clang -O1 -g`, then runs the SAME stage-1 module through **three** `cq-opt`
binaries and, on exit 0, through stage 2b + link + run:

| label | worktree | `cq-opt` sha256 |
|---|---|---|
| ORACLE | `/Users/sorenwilkening/Desktop/CQ_lang` (`main` `74eabd2c`) | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` |
| BASE_A | `/Users/sorenwilkening/Desktop/CQ_A` (`railbank-blockers` `9e11f524`) | `b65549356168354626a7f09c748e35e43f9fba186ae7ede8dab6a31fd3aae2bf` |
| SUBJ_B | `/Users/sorenwilkening/Desktop/CQ_B` (`railbank-accept` `3b982459`) | `784c14fa05c16c501662b3814434dafb8ffb1cc2ed98a8d17986dc12a372b6ff` |

**No binary was built and no suite was run by this review.** Re-hash before citing.

## The vacuity guard, and why it is in the driver rather than in the reader's head

`run.sh` refuses to report a verdict unless the stage-1 module has ≥1 `define`
and ≥1 `@cq_` call, and it prints the `unreachable` count on every run. Two
recorded traps this closes: a 0-byte `.ll` ACCEPTs through the passthrough
early-out (bd memory `empty-module-accepts-vacuity-trap`), and a probe whose C
body is UB collapses to a bare `unreachable` that also "accepts"
(`IMPL_B2.md` §11.0b measured exactly that). **A probe that prints
`VACUOUS-STAGE1` measured nothing.**

## The finding

`f01_bank_stale_reader.c` (**ACCEPT** on SUBJ_B, DECLINE on ORACLE and BASE_A)
against `f02_register_twin_of_f01.c` (**DECLINE on all three**, `cq opcode
lowering: rotation/measure operand predates a non-diagonal gate`). The green
half of the pair is `f06_bank_legit_order.c` / `f07_register_legit_order.c`,
whose traces are **byte-identical**. `i02_nonmain_stale.c` is `f01` outside
`main` in the house style; it accepts too. See `../REVIEW.md` §F-1.

## What these probes do NOT cover

Stated so the next round does not read absence as clearance:

* **A bank cell load consumed by `freeze` or by `cq_invert_*` was NOT probed.**
  A first attempt at the `cq_invert` probe failed to compile (wrong spelling of
  the `_Generic` family member) and was deleted rather than shipped broken.
  Both remain open items from the track's own round-2 list.
* **`g03_bank_plus_dead_terminal.c` measured nothing it was written for**: `-O1`
  folded `(d & 0)` and deleted the intended dead terminal, so the module has no
  spine free at all. It is kept because its ACCEPT is still a valid bank
  observation, not because it answered its question.
* `L9_array_phase_arm.c` and `H17_narrow_index.c` were run during the review but
  are **other tracks' probes** and live at their own paths; they are not copied
  here.
