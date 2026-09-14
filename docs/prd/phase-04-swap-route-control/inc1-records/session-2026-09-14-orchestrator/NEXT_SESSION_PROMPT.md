# Next session — starting point after 2026-09-14

`main` at `620a3982`, pushed. `build/` holds `cq-opt 5c6f7490a81c7505…` /
`libCQPass.so 5276f7ab7416b36b…` — the gated binary. Full suite **442/442**, equivalence **1993/0**,
lit **1994**, goldens **383**, twin cells **338**. ⚠ **Hash `build/ir-pass/cq-opt` before believing any
decline** — this session's last confusion was a stale build, and from outside that is indistinguishable
from a regression (memory `stale-build-looks-exactly-like-a-regression`).

## The owner's program: where it now stands

`example/grover/grover_oracle_uncompute.c` — three bools — **compiles**: exit 0, stderr 0 B, 35 trace
lines, STRICT 2b `9 rail mint(s) of which 7 left allocated, 3 cqrt_free site(s): 3 verified, 0
violation(s), 0 unproven`, byte-identical to `tests/e2e/slice_control_cascade_three_bools.expected.log`.
A rolled bool-controlled Ry arm / state prep also lowers now (bd `wx8g`), where `CLAUDE.md` had recorded
that it compiled in **no** spelling on **any** binary.

**The loop cascade still needs two more walls removed, in this order:** bd `xdu2` (the bounded rail
array, ~700–1100 lines / 4 rounds — its own bead's estimate was low ~4×) then bd `ej5w` (the in-loop
value arm, both X1 sites, `LoopLowering.cpp:2106-2110` **and** the round-2 twin at `:2548-2553`, or
round 2 re-declines what round 1 accepted).

## Waiting on the owner — ask these first

1. **bd `z9t1`, two dispositions, recorded together as "one question asked twice".** (a) the
   LiteralIntegrity GUARD 1 count drop at CQ type `double`, where the seed and the angle share the LLVM
   type — five measurements point AWAY from restoring the decline, and a sixth outcome is a pre-existing
   abort on 2 of 1922 mutants, not reachable from C. (b) the φ clause disarming ruling clause 4 UPSTREAM
   of the sink — 4 of 710 rows, all byte-identical to their written-zero twins, the DIRECT spelling still
   declining. Recommendation on (b): accept and re-state clause 4 as covering the direct spelling.
2. **bd `yiid` (P1) — `cq_measure` is not modelled as a wire event at all.** The owner has already ruled
   the *capability* half ("it just requires a `c_alloc` again"); what is unruled is whether a measurement
   is a BARRIER (every earlier name stales) or a RELABEL. Track D's §14 carries the implementable design
   for the recommended reading — **taint stops at `cq_measure`, position-aware** — costed at 0 shipped
   accepts moved and 2 of 367 goldens getting SHORTER, no new symbol, and it retires part of `3d8q`'s
   remaining population by construction.

## Owed, and it is a trigger that FIRED rather than a wish

**The X5 re-derivation.** Track F's φ-descendant narrowing names bd `wx8g` BY NAME as the only reason its
back-edge shape is unreachable — and `wx8g` landed in the same merge. Measured at the gate: three probes
go from `control flow inside a loop body` on the oracle to F1-decline / ACCEPT / ACCEPT on the merged
binary. **Nothing over-accepts and both fixtures held**, but trigger (3a)'s premise is now FALSE. Probes
are committed in `merge_gate_probes/`. Do this before widening anything near F2.

## The P1 correctness queue

* **bd `a3z7`** — re-raised P3 → P1 and RECLASSIFIED. It recorded the divergence as an efficiency matter
  ("the better circuit"); it is not — whenever the rail φ carries the OPERAND, the rolled form is a
  **different program's** circuit. Mechanism named: `tryCaseA`'s in-place-user tally
  (`LoopLowering.cpp:2217-2236` + the round-2 twin at `:2663`) enumerates only `CallInst` and
  `BinaryOperator` users, and **a `PHINode` user is counted by neither**. Neither disposition of the
  `oa1`/`oa1t` pair is pinned — deliberately, because a green fixture asserting today's accept would
  cement a silent miscompile. Pin the pair WITH the fix.
* **The region-independent in-loop leak** — six lines of C with **no tainted control flow at all** leak
  entangled which-path rails (16 vs a twin's 20). Root: a `markIfRailLocal` clause that REFUSES SILENTLY
  instead of declining. Pre-existing; nominated by Track W's round-2 reviewer as the next round's subject.

## Two instrument gaps that explain past near-misses — fix before trusting a green suite on their classes

* **Every corpus in this tree is effectively ONE FUNCTION PER MODULE.** A dangling `Loop *` survived 1937
  fixtures, 15 e2e entries, a complete corpus sweep, a 0-MISSED matrix and 328 twin cells for that reason
  alone. Where a fixture does carry two `define`s, both copies want the SAME verdict — the missing axis is
  **a module whose two loops want different ones**.
* **No hand-written `.ll` fixture can pin a diagnostic's LOCATION.** Four known sites still report
  `<unknown>:0:0` or `file.c:0:0` (bd `p25o`, `br4a`, the row-W site, the loop layer's `kMsgCrossIter`).
  The repair pattern now exists and is measured: `anchorIsLocated` testing `DL && DL.getLine() != 0` —
  a null test fixes only HALF the class, because `-O1` stamps `!DILocation(line: 0)` on merge φs. Doing
  all four together with one full-stderr comparison over `-g` C probes is cheap.
* `tools/inplace_twin_matrix.py` and `tools/angle_select_twin_matrix.py` have the same regenerated-header
  shape as the instrument that silently ate 54 lines of ruling prose. **Unaudited.** One `git log -p` each.

## Process, measured

PROTOCOL §S1's one-group rule delivered **ONE full suite for SIX landings** (target 1–2; the previous
session spent 4 on 3), and the group gate **earned itself** — it caught three interactions no per-track
gate can see by construction. §S2's citation held: the closing rebuild reproduced the gated binary exactly.
⚠ §S1's "disjoint anchors" sentence about `tests/e2e/CMakeLists.txt` was **measured FALSE** and is
corrected in place — three tracks append at one tail anchor, and it conflicted twice in one merge.
⚠ **At most ONE corpus sweep in flight per session** (new rule, memory
`one-corpus-sweep-at-a-time-load-ceiling`): the box reached load 330–574 with six agents and TWO tracks'
sweeps failed to finish, which silently removes the only gate that sees a diagnostic-location change.
