# session-3qlq4 — bd `test_C_libtooling-3qlq.4`, Increment 1b: the bare `_Bool` condition (2026-09-10)

Session `01NHxGVinGBKbb499HFCuwhT`, branch `3qlq-inc1b-rail-cond`. The owner's instruction that
opened it: "we do NOT want the workaround. we want to work with bool and all the other data
types" — the `int b0` spelling of `example/grover/grover_oracle_uncompute.c` compiled, the
`bool b0` one declined `branch phase on a bare i1 condition`.

## What is here

| path | what |
|---|---|
| `probes/` | the 39 plain-C `bool` probe programs (`p*`, `q*`, `r*`) the increment was scoped and measured on, with a verdict table (`probes/README.md`) |
| `review_1b_r1.md` | the independent Rule-13 round-1 report — **BLOCK** on F-1b-1, a CONFIRMED plain-C silent miscompile (a sibling in-place Ry on a template parent; pre-existing for the compare path) — plus F-1b-2..5 |
| `review_1b_r1_probes/` | that round's 83 C programs and 25 hand-IR modules (`h/hdr.ll` is prepended by `hrun.sh`), and its `corpus.py` main-vs-branch diff harness |
| `review_1b_r2.md` | the round-2 report on the fix (the walker widening) |

## Where the design and the record live

* PRD `docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` — **§13** (the increment:
  the rail leaf, the diagonal-only polarity form, the classifier ladder, the decline partition,
  the measurements, §13.6 the round-1 findings and the walker fix) and **§0 E14**.
* `CLAUDE.md` — the CORRECTNESS-RISK paragraph "INCREMENT 1b — THE BARE `_Bool` CONDITION",
  the Build & Test counts, the Where-Things-Live rows for `CondTreeEmit`/`SwapRouteEmit`.
* `docs/frontend.md` — the `bool`-as-a-condition note under the type table.
* `docs/labreport/sessions/002-2026-09-10-bool-condition.tex` — the owner-facing entry.
* Follow-ons: bd `r9e5` (1b-B: data select / value arm / 6.5 on a rail), `l4x4` (1b-C: in-place
  Ry / state prep / Ry angle select on a rail), `boi6` (1b-D: loop-carried and merge-phi rails),
  `r903` (negated nest level, NOT-carrying rail leaves, derived-`i1`, and the two parity gaps
  the round-1 review recorded: `thetaOnPathTo`'s null-taint ancestry, the compare path's
  weaker measured-before fence).

## The two things the increment does NOT buy (owner questions, not bugs)

* A `bool` STATE PREP under control (`if (c) b = cq_theta(false, θ)`) still declines at fence
  F2 — an `i1` seed always collides with the branch's own compare, pinned to `true`/`false` on
  its edges (`HANDOFF_controlled_cascade_2026-09-10.md` Q6).
* A `bool` produced by a preceding controlled-Ry region reaches the next region as that
  region's MERGE PHI, not as a `cq_theta_i1` result — 1b-D's sibling (bd `boi6`).
