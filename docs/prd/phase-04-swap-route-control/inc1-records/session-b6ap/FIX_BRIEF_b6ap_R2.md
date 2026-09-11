# Fix brief — bd `b6ap`, after round-2 Rule-13 review `review_b6ap_r2.md` (verdict CLEAR-WITH-ITEMS)

Worktree `/Users/sorenwilkening/Desktop/CQ_b6ap`, branch `merge-phi-peel` (checkpoint b7d646c). Read
`review_b6ap_r2.md` in full (F-B6R2-1/2, the M-D resolution, the 15-row stage table in its §1, the P10
note, the round-3 question), then `FIX_b6ap_R1.md`, `IMPL_b6ap.md`, and `review_b6ap_r2_probes/`
(`ab.sh`, `twin.sh`, `handpeel.py`, `sweep.sh`, README). You are the FIX agent (opus). Do NOT commit/push;
never write under `/Users/sorenwilkening/Desktop/CQ_lang/` or the other worktrees; ORACLE
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` + `libCQPass.so`. Report only what you ran.

## F-B6R2-1 — OVER-DECLINE: `foldIdentityBitcasts` is a FIFTH taint-consuming pre-peel stage

`foldIdentityBitcasts` (`CQLoweringPass.cpp:159`, `:787`) folds only an already-tainted same-width
int↔int `bitcast` and is the SOLE handler for that opcode; one the peel taints later is left standing and
dies `no template for opcode 'bitcast i32' in tainted context`, while the hand-peeled twin lowers at exit 0
on BOTH binaries (`BC1`). Add a fifth call to `adjudicateTaintDelta` (idempotent, monotone — say why in
the header), pin `BC1` as an accept (RED on b7d646c), and correct every place that says "four calls" (the
stage table in IMPL, the `adjudicateTaintDelta` header, FIX_R1). Then re-walk the reviewer's 15-row stage
table yourself and write it INTO `IMPL_b6ap.md` (§2 or a new §2c): row → runs before/after the peel →
consumes taint? → re-asked / closed-by-own-decline / accept-only / HOLE. It must have zero HOLE rows.

## M-D — the fourth call has a customer: pin it

`S02` (plain C: `r = cq_theta(m,.2); s = m + 1;` — the peel flips the theta SOURCE→CHAINED on the mux
rail, so `s` reads its pre-Ry record; SUBJECT declines `operand predates a non-diagonal gate`, the twin
gives the same string). Add it as a decline fixture with a header saying it is the ONLY customer of call
4 and that a mutant deleting call 4 turns it into a silent accept (measure the mutant, restore, `grep -c
MUTANT` → 0).

## F-B6R2-2 — DOC only

The peel is a new customer generator for bd `3d8q` (`S03`; `S04` reproduces on the oracle with no peel).
The orchestrator has appended that to the `3d8q` issue. Add one paragraph to IMPL §7 and put `S03`/`S04`
under `probes/` with the README line pointing at `3d8q`. NO code.

## P10 — DOC: the retirement trigger

Record in the P10 comment and IMPL that the narrow `StoreInst` spelling suffices because
`guardedShadowStoreShape` takes a `StoreInst *` and every `memset`/`memcpy`/writer-call arm declines
`control flow` at the arm classifier anyway — retirement trigger: if the 7.5 guarded-store recogniser ever
admits a non-`StoreInst` writer, P10 must widen with it.

## The round-3 question — build the probe family the reviewer read but did not run

The peel DELETES a φ and INSERTS two instructions (a compare clone + a select). Enumerate every consumer
of the DELETED φ's identity (`taint.Tainted`, `BirthOrder`, `InPlaceRailOps`/`InPlaceRailIdx`,
`ClaimedRailRoots`, `RailCondReads`/`CmpCondReads`, the PredMux/loop plans, `LoopPlan`'s
`railPhiRootMint`, `ControlRegion::Merge`, any `WeakTrackingVH`/`DenseMap<Value*,…>` keyed on it) — grep
every set/map in `ir-pass/include` that can hold a `PHINode*`/`Value*` — and for each say: cannot contain
the φ (why), or is updated/erased (where), or is a dangling key (the drbq Inc-1 stale-set class — then
construct the program and fix). Write the table into IMPL; pin any dangling key with a fixture.

## Gates, in order

`lit --filter` → `ctest -R ir-pass-lit` → `ctest -j6 -R '^e2e-'` + `git status --porcelain tests/` →
corpus diff over the 1776 (`0/0/0`, plus the new accept `BC1` as the only mover in hand IR) → both
reviewers' corpora + the implementer's re-run, every verdict listed → full `ctest -j6` ONCE (a pipeline
change; never relink under a measurement, never `pkill` by pattern) → `cq-opt-equivalence-full`. Write
`FIX_b6ap_R2.md`: per item → change (file:line) → fixtures → measurements; the stage table; the
φ-consumer table; open questions.

Final message ≤25 lines: per item one line, the two tables' bottom lines (0 HOLE / 0 dangling or what you
found), gate lines verbatim, movers, open questions.
