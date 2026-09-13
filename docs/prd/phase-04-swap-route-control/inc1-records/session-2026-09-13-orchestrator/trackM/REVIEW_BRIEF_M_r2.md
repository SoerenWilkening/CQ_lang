# Rule-13 review brief, round 2 — Track M, on the round-1 FIX (`FIX_M_R1.md`)

Written 2026-09-13 by the orchestrator. Model: opus. Worktree `/Users/sorenwilkening/Desktop/CQ_mphi`, branch
`mphi-rail-leaf`, `build/` current (`cq-opt` sha256 `0d3105d0eb9d476a…` per `GATES.md`; confirm by
`shasum`). Protocol `../PROTOCOL.md`, row "review": NO build, NO suite; the fix agent's `GATES.md` lines and
corpus are your inputs (`ir-pass-lit` 1913/1912/1 XFAIL/0; injection 87/0 MISSED/1 N/A; corpus 2723 rows,
0 ACCEPT→DECLINE, 0 both-accept IR changes, exactly ONE mover vs round 1 = `G6_quantum_mux_values.c`
DECLINE→ACCEPT 26). ORACLE `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` (`fbbe0820…`).
Read in order: `review_M_r1.md` (your predecessor's findings + probes), `FIX_BRIEF_M_R1.md`,
`FIX_M_R1.md` (all; §GATES), the fix diff (`git diff -- ir-pass` — separate the round-1 hunks from the fix
hunks by reading `IMPL_M.md` §1 vs `FIX_M_R1.md`), `IMPL_M.md`, `SCOPE_M.md` §1 sites 17/18, `CLAUDE.md`
(Prime Directive; Rules 1, 6, 12, 13, 14; CORRECTNESS RISK §2 the `hcrg` sequential-region row, §3 L1/L6/L9).

## What the fix changed (Rule-13 CORE: `lowerControlRegions`' precedence graph)

`ControlPlan.h:507` `unsigned PrepRegionIdx` on the `SelectRegion`; `SelectClassify.cpp:551`
`preppedRailPhiRegionIdx` (rung 0 returns the admitting region's plan index; `:994` captures; `:1299` the
accept carries it); **`SwapRouteEmit.cpp:2598-2637`: ONE edge `Precedes[P].push_back(i); ++Pending[i]`**
— the prep region P before the select region i — by calling the record; the fix agent argues no cycle is
possible because a `SelectRegion` has no OUTGOING edge (this is the only way it gets one, and it points
INTO it); out-of-range index declines loudly. `SelectMergeEmit.cpp`'s two false claims rewritten; the H-1
backstop kept as the "a seventh emitter forgot the edge" tripwire (counterfactual with the edge disabled,
binary `253a80e6`: `r03` → `control flow`, `r17`/`r18` unaffected). F-M6: fixture (78 lines/19 gates at
K=3 and K=1000) + 8th injection mutation (a gate hoisted out of the loop body — caught) + slices
`..._select_in_loop_outside_prep{,_unrolled}.c`, 43 = 43 byte-identical. F-M3 pinned as a DECLINE with a
`3d8q` retirement trigger; F-M7 trigger added. **Vacuity**: 5 vacuous `NOX`/`NOFREE` negatives across 3
fixtures found by a name-existence check (`probes/impl/vacuity.py`) and fixed — 63 named negatives / 11
fixtures / 0 vacuous. New accept `..._quantum_arm_then_prep.ll` (= `G6`).

## Where to look

1. **The edge and Kahn.** Read the graph code end to end: with the select region now carrying an edge,
   (a) can the alias loop (`:2536-2557` at 81956a2 — re-grep) ever give a `SelectRegion` an OUTGOING edge
   (a `doomedBlocks(B)` that names… nothing, since a select region sets no block fields — confirm the
   `Kind == SelectRegion` early-out still holds for BOTH directions); (b) `reorderable()` still admits only
   `BranchRegion`/`PhaseKickback` — a prep region under a COMPARE condition whose merge φ feeds a select
   (the `i2_cmpladder` accept): the prep is a `BranchRegion` kind, fine; but a prep whose Pred is ANOTHER
   region's merge block (the owner's file: the fused diamond's pred is the entry block — construct a
   FOURTH region before it so the prep's `Pred` IS a previous region's merge): does Kahn now produce
   [region0, prep, select, kickback] and does emission stay source-order? (c) two selects on ONE prep φ
   both carry the same `PrepRegionIdx` — two edges into two selects, fine; a select whose φ's region is
   ALSO the region a following kickback's `Pred` names (F-M1's shape) — the fix's own customer; (d) an
   index captured in ROUND 1 that goes stale in ROUND 2 (`repropagateControlMerges`' second detection
   builds a NEW plan — is `PrepRegionIdx` an index into THAT plan, or into round 1's? If a round-2 select
   is admitted against a round-2 region the index is consistent; if a round-1 select survives into round
   2's plan… it cannot — it was emitted in round 1. Confirm by reading, and construct the 9pum two-TU
   window with a THIRD region after the select so the round-2 plan has ≥2 regions).
2. **The unitary of the new accepts**: `r03` (33 lines — line 27 mints the kickback's flag from `h8`, the
   select's out rail; re-derive that the kickback reads the POST-select `a`), `G6` (26 — a QUANTUM select
   arm then a prep: re-derive), the in-loop `r22` pair (43 = 43; re-derive the rolled form's per-trip
   gates: is the CNOT ancilla freed EVERY trip and re-allocated, or minted once? both are `|0⟩`-safe —
   say which and why the K-independence line count proves nothing about the ancilla's freshness).
3. **The vacuity fix**: was any previously-green accept fixture's NEGATIVE weakened by the rename (a `NOX`
   that now names a handle the module DOES define but that is an ancilla rather than the user register —
   i.e. a negative that is non-vacuous but asks the wrong question)? Read all 11.
4. **Round 1's thin spots**: item 7's `p20` (arm theta CHAINED → wire fence — the reviewer left it
   ungraded; decide from the state vector whether the CNOT copy after M-β would read the same basis the
   source reads); item 6's `3d8q` list.
5. **Anything the fix REGRESSED**: the corpus says 0 ACCEPT→DECLINE, 0 both-accept IR changes over 2723
   rows; spot-check ONE `hcrg` sequential-region fixture (`control_swap_accept_seq_*`) on the subject vs
   ORACLE by hand (the graph code changed and those are its customers).

## Method

As round 1. Report `review_M_r2.md`, probes `review_M_r2_probes/` + runner. Verdict BLOCK /
CLEAR-WITH-ITEMS / CLEAR. Final message ≤25 lines: verdict, findings with grade + reproducer, item 1(d)
answered explicitly.
