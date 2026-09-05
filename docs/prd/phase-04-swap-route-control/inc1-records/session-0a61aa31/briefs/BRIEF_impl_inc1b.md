# BRIEF_impl_inc1b — bd test_C_libtooling-3qlq.2: Inc 1 (part B) — P3 compound condition, P4 genuine nest, P5 switch phase
Read `$SP/briefs/BRIEF_common.md` first, then `$SP/briefs/BRIEF_impl_inc1a.md` (part A's
brief — you build on its result), then `$SP/progress/impl_inc1a.md` (what part A shipped,
its diagnostic strings, its fixture names). Agent name: `impl_inc1b`. Model: opus.

## Where you work
Worktree `$SP/wt/inc1b`, branch `3qlq-inc1b`, created from part A's LAST commit on
`3qlq-inc1` (hash: fa96336). Configure + build it yourself in the background
(`cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm
-DCMAKE_BUILD_TYPE=Release && cmake --build build -j8`, ~5–7 min; poll the log). Part A's
branch is being REVIEWED in the main checkout while you work — do not touch it. You merge
back later via the orchestrator.

## Scope (PRD §6.2 rows P3, P4, P5 and their §6.3 declines)
The kickback gate and the void `cq_phi` recognition exist (part A). Your job is the FLAG:
- **P3 compound condition tree** — the `br` condition is `select i1 %a, i1 %b, i1 false`
  (AND), `select i1 %a, i1 true, i1 %b` (OR), `and i1`/`or i1`/`xor i1` over tainted compare
  leaves (the spellings `SelectClassify::collectCondTree` (SelectClassify.cpp:374) already
  accepts for the 4.4 select merge, incl. the bd 3c6m.67 two-operand xor). Today a `br` on
  such a condition DECLINES in `ControlDetect` (find the string; it is likely the Q+Q /
  compound-condition decline). Accept it for a kickback arm ONLY: leaf flags via the existing
  compare mint; nodes via the SAME network `SelectMergeEmit.cpp` lines ~140–215 emits (AND:
  `toffoli(l,r,g)`; OR: `cnot(l,g); cnot(r,g); toffoli(l,r,g)`; XOR: the OR node minus its
  toffoli) onto fresh |0> ancillas; `cqrt_rz_i1(root, θ)` (`cqrt_x` bracket for a negated
  arm); then LIFO uncompute — node networks undone in REVERSE order (each self-inverse), then
  each leaf's compare `_unc`, then frees. Rule 14: FACTOR the node emission + node uncompute
  out of `SelectMergeEmit.cpp` into a shared helper (e.g. `CondTreeEmit.{h,cpp}`) and make
  SelectMergeEmit call it — the 4.4 goldens (`slice_control_select_*`, `slice_select_*`) and
  the `control_swap_select_*.ll` fixtures must stay byte-identical (run them: that is your
  Rule-14 witness). `ControlRegion` already has `Conj/CondA/CondB/FlagA/FlagB` fields (a WP5
  leftover, ControlPlan.h:124–131) — either use them or delete them; do not leave two
  representations. Compound conditions are NEW core for `br` regions (PRD §11) — the decline
  partition must cover: a leaf that is not a lowerable compare, a leaf with a data use
  (`condHasDataUse`, RegionTreeDetect.cpp:62 — say whether sharing is admissible as
  `ShareCondFlag` does for a single compare, or decline), a tree with a non-`i1` node, a
  tree mixing a classical leaf (a classical `i1` leaf can be a constant-folded control —
  decline unless you can prove the mint; simplest: decline), self-operand nodes
  (`or i1 %c, %c` — SelectClassify.cpp:511 fence), depth > some bound (state it).
- **P4 genuine depth-2 nest** — `RegionTreeDetect::recoverRegionTree` (line 71) detects
  `if (a) { … if (b) { cq_phi } }` when SimplifyCFG did NOT fold it (inner block carries
  more than a cheap compare). Keep the DETECTION; replace `NestedRouteEmit::lowerNestedRegion`
  (line 51)'s route by P3's conjunction flag: mint fa, mint fb, `toffoli(fa,fb,g)`,
  `rz_i1(g,θ)`, toffoli undo, strip fb, strip fa, frees. The outer arm's other content
  (e.g. an in-place Ry on a third register before the inner compare) is what makes the nest
  genuine — say exactly which outer-arm contents are admitted (PRD: homogeneous PHASE nest;
  an Ry in the outer arm is a MIXED arm → decline, unless part A's P1 already admits an
  Ry+phase combination — check its progress file) and pin it.
- **P5 switch, homogeneous phase** — `SwitchClassify` (G0–G11) + `SwitchArmProve` +
  `SwitchRouteEmit::emitSwitchPhaseRegion` (line 88): each case arm is ONE `cq_phi(θ_i)`.
  Replace the N-way route by per-case eq-flags: for each case value k_i mint
  `icmp eq(scrutinee, k_i)` → f_i, `rz_i1(f_i, θ_i)`, strip, free. The §5 CONST-FOLD
  RE-ANCHOR SCRUB (`A8C0_STRAIGHTTHROUGH_CONSTFOLD.md`, `straightThroughConstFoldHandle`
  ArmClassify.cpp:1946, `EqFoldArm.cpp`) is RETIRED for phase arms — there is no arg-0 to
  fold — but `tryEqFoldArm` (the equality-folded `br` diamond D1–D7) must still recognise a
  `cq_phi` arm and route it to P1's emitter: check what `-O1` does to
  `if (q == 5) cq_phi(θ)` — is it already P1's diamond? (yes per §6.1) — so the eq-fold
  path may be vacuous for phase; say which. Default arm: empty only (C5 stays). The
  data-mux and value switches are untouched (value → Inc 2).
Every accept row gets its fixtures (accept + whole-file negatives in their own prefixes:
NO `cqrt_cswap`, NO `_controlled`, NO `cqrt_rz_<W>` with W≠i1, NO surviving `@cq_phi`), every
decline row a `RUN: not` fixture mirroring the string. The existing nest/switch fixtures
(`control_nested_*.ll`, `control_switch_*phase*.ll`) and their slices
(`slice_control_nested_phase`, `slice_control_switch_phase`) are being migrated by prep (a)
and (b); rewrite the ones whose CHECKs pin the ROUTE only if the migration branch has not
already (check `git log 3qlq-inc1-migration` — the orchestrator will tell you whether it is
merged).

## Witness
`slice_control_phase_nest.c` vs `slice_control_phase_andcond.c` must be BYTE-IDENTICAL
(prep b writes them; they are on branch `3qlq-inc1-slices` — cherry-pick or read them from
`$SP/wt/prep-b/tests/e2e/`), and `slice_control_phase_nest_deep.c` (genuine nest) must emit
the same stream as the folded one modulo the outer-arm content. Run all three on your binary
and the ORACLE; paste traces. Also run the migrated `slice_control_switch_phase.c` and
`slice_control_nested_phase.c` from prep b's worktree.

## Hand-back
Per BRIEF_common: files, commits, fixture counts (measured), the decline strings verbatim,
the three traces, the Rule-14 byte-identity check on the 4.4 select goldens/fixtures, red
partition of `ir-pass-lit` (pending-migration vs other), OWNER QUESTIONS.
