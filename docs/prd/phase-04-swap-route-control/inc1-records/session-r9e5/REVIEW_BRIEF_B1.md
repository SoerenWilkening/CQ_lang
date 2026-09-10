# Rule-13 review brief — bd `test_C_libtooling-r9e5` sub-increment 1b-B.1 (the 4.4 DATA select on a bare `_Bool` rail-root condition)

Branch `3qlq-inc1b-b-rail-select` (off `main` 87d0699), 2026-09-10. Tree state under review: the B.1
implementation (`IMPL_B1.md`) PLUS the orchestrator's F-B1-1 fix (below). Build in `build/` is current.

## What changed (read these diffs first: `git diff main -- ir-pass/src ir-pass/include`)

* `CondTreeEmit.{h,cpp}` — `emitCondNetwork(..., bool CopyRailRoot=false)`: when the tree's ROOT is a rail
  leaf and the caller asks, mint `bf = cqrt_alloc_i1(0); cqrt_cnot(h_rail, bf)` LAST, hand `bf` back as
  `Net.Root` (`RootIsRail=false`, `RailRoot`/`RailRootFlag` recorded); `stripCondNetwork` emits
  `cqrt_cnot(h_rail, bf); cqrt_free(bf)` FIRST. Every phase caller passes nothing (byte-unchanged).
* `SelectMergeEmit.cpp` — passes `CopyRailRoot=true`; the pre-emission `kBareRailCondReason` guard is
  replaced by the INVERTED drift guard (`Net.RootIsRail` ⇒ loud `control flow`). The merge stream on the
  flag is the shipped one, instruction for instruction.
* `SelectClassify.cpp` — the rail ladder in `classifySelectRegion`: per rail leaf (i) tainted, (ii)
  `railMeasuredBeforeReadPoint(Rail, Sel, …)`, (iii) gate 2c split into `CmpProv` (position-free,
  byte-unchanged) and `RailProv` (position-free clean ⇒ accept; else no `DT` ⇒ decline; else
  `findNonDiagonalWireGate(RailSeeds, true, /*EmitPoint=*/Sel, DT, &taint)` — a gate NOT provably after
  every execution of the select declines). The trailing `kBareRailCondReason` decline after the angle
  hand-off is deleted. Gates 4/5/6 unchanged.
* `ArmClassify.cpp` / `ArmAnalysis.h` — `railMeasuredBeforeBranch(Rail, Pred, …)` generalised and exported
  as `railMeasuredBeforeReadPoint(Rail, ReadPoint, …)`; the two kickback callers pass
  `Pred->getTerminator()`. **F-B1-1 (orchestrator, on the first B.1 build, plain-C reachable, CONFIRMED):**
  the first spelling returned `M->comesBefore(ReadPoint)` for a same-block measure without asking
  reachability, so `for (i…) { int a = b ? i : 5; acc += cq_measure(a) + cq_measure(b); }` ACCEPTED (exit 0,
  verify-clean, STRICT 2b clean) with every activation after the first controlling its copies on a
  register the previous trip collapsed. Fixed by asking `isPotentiallyReachable(M, ReadPoint, nullptr, DT)`
  for EVERY measure (LLVM's same-block handling: before ⇒ true; after ⇒ true iff the block reaches
  itself). Pinned by `control_swap_reject_select_rail_inloop_measure_after{,_constarm}.ll`. The COMPARE
  twin of that program ACCEPTS on `main` (the 4.4 compare-select classifier has NO measured-before rung at
  all) — PRE-EXISTING, filed as bd `test_C_libtooling-r10v`, NOT this increment's; reproducer
  `probes/m2_inloop_select_measure_after_compare_twin.c`.

## The analytic argument the emitter rests on (challenge it)

After `cnot(b, f)` the pair is `Σ α_x |x⟩_b |x⟩_f`. `copy_c(f, T, out)` writes `T` iff `x = 1`; `x(f);
copy_c(f, F, out); x(f)` writes `F` iff `x = 0`; `b` is untouched throughout (copies write `out`, brackets
act on `f`); the second `cnot(b, f)` returns `f` to `x ⊕ x = 0` on every basis branch, so the `cqrt_free(f)`
is a proven-|0⟩ free (Rule 6) and `b` is left exactly as found, entangled with `out` (Rule 8: a copy of a
LIVE source, nothing freed). Gates that touch the register: two `cqrt_cnot(h_b, ·)` with the register at
arg 0 — a read-only control, the gate class the Inc-1b nest already emits on a rail.

## Where to look for a silent miscompile (the Prime Directive: over-accept is the only unforgivable bug)

1. **The read point.** The select is mid-block; the kickback's is the terminator. Every rung that was
   argued for "at the branch" must hold "at the select": measured-before (F-B1-1 found one hole — find the
   next), the DT prong (`WireWalk.h`'s "IF B executes, A has already executed and never runs again" — is
   there a placement of a chained/sibling Ry on `b`'s wire that is provably after the SELECT by that test
   yet stales a LATER activation, a second select, or a kickback on the same rail?), and the P1 transfer
   argument (does anything of the region survive on `b`? — the copies entangle `b` with `out`; a later
   in-place Ry on `b` after the select is the S† accept; is there a later consumer for which that
   entanglement matters — a second select on `b`, `b` read as data (`zext`), a kickback on `b`, an
   `_unc` of a chain that BORROWS `b` as a parent, the whole-DAG spine's disposition of `h_b` when `b` is
   dead?).
2. **Two seed sets.** Gate 2c now walks compare seeds position-free and rail seeds with the DT prong. A
   tree mixing a compare leaf and a rail leaf (`(b != c) ? …`, `select b, cmp, false` is off-grammar for
   data) — can a theta on the RAIL's wire that is provably post-select be wrong for the COMPARE leaf, or
   vice versa? Is `condProvenance(Rail)` seeding the right wire for a CHAINED rail (`b = θ(b0, ·)`)?
3. **The network with `CopyRailRoot`.** `Out.Root` is re-pointed to the ancilla AFTER the walk; is there
   any path where `FlagOf[root]` is read elsewhere (a shared subtree, `Specialization::mintCondNetwork`,
   the nest) that now sees the wrong rail? Is `RootIsRail=false` read by anything that then brackets the
   REGISTER? The inverted drift guard in `SelectMergeEmit` — can `RootIsRail` be true there? Can the strip
   run with `RailRootFlag` set but the forward not emitted (a `MintDiagnosed`/`Malformed` path)?
4. **The spine.** `h_b` now has two `cqrt_cnot` users at arg 0. `Uncomputation::preservesBorrowedParent`
   refuses `cqrt_cnot` (fails closed) — the impl says the disposition is the LEAK direction (OQ-B1-3):
   measure it on a chain that borrows `b` (`int z = b + 1` beside the select; `int w = b ? 2 : 5; int z =
   zext(b)`; a `cq_measure(b + 1)`), and on a DEAD `b`. Does `ChainWalk` ever recover a `cqrt_cnot` whose
   TARGET is `bf` as an in-place gate on anything? Does `FreePoint` ever free `bf` twice or `h_b` at all?
   Does `EmitInverse` ever adjoint the network (a `cq_invert` around a rail-conditioned select)?
5. **The RAUW hazard.** At emit time `%b` is still the `i1` call; the cnots are created with the `i1`
   value in an `i32` slot and rely on `lowerRotations`' RAUW-to-handle — as the kickback and the nest do.
   Is there an ordering where the select's stream is emitted but the theta is NOT lowered (a `cq_theta_i1`
   the rotation lowering declines or skips AFTER the control emitter ran — a stale-record decline, a
   quantum-derived angle, a clone)? What is left in the module then?
6. **Round 2 (`repropagateControlMerges`).** A rail-conditioned select whose ARM is a round-2-tainted value
   (a 6.5/4.5 `%out`, or another select's `%out`), and a select whose CONDITION becomes a rail only at
   round 2 (impossible — a rail is a theta result — say why). Two selects on one rail, a select inside a
   kickback's arm block, a select in a loop with a kickback on the same rail in the same body, a select
   under a classical guard whose other path measures `b` (F-1b-2's shape — fixture exists; find a
   sibling), a select in a clone (`f(b)` with a rail argument — `Specialization` skips rail trees; is the
   select then left neither lowered nor declined?).
7. **`-O1` reachability.** For every decline fixture that is hand IR, find the plain-C spelling or show
   there is none; for every accept, write the twin the compare path already lowers and diff the traces
   (they should differ ONLY by the mint/strip lines).
8. **Stage 2b blindness.** A leaked TEMPLATE-minted or ancilla rail has no `cqrt_alloc` count to catch it;
   count `cqrt_alloc_i1` vs `cqrt_free` per activation in the rolled loop slice and its unrolled twin.

## Method

Read `IMPL_B1.md`, `PRD_14_DRAFT.md`, `probes/README.md`; run the probe family and the fixtures yourself
(the binary is built; DO NOT rebuild, DO NOT edit `ir-pass/` or `tests/`); write your own probe corpus
under your scratch dir (plain C at `-O1` first, hand IR second) and run each against BOTH the branch
binary (`build/ir-pass/cq-opt`) and the saved pre-change one
(`/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/05a94f34-2e8d-4c24-b48c-aaecd3961c97/scratchpad/impl_b1/pre/cq-opt`,
same `-load-pass-plugin` with its sibling `libCQPass.so`). Every accept you find must be argued from the
state vector (Rule 2), never from `opt -verify`, the trace's plausibility, or stage 2b. Grade each finding
CONFIRMED-MISCOMPILE / OVER-ACCEPT-ARGUED / OVER-DECLINE / LEAK / DOC, with the exact program, both
binaries' outputs, and the analytic reason. Verdict: BLOCK (any CONFIRMED miscompile), CLEAR-WITH-ITEMS,
or CLEAR. Write the report to
`docs/prd/phase-04-swap-route-control/inc1-records/session-r9e5/review_b1_r1.md` and your probes to
`…/session-r9e5/review_b1_r1_probes/` (with a `corpus.py`/shell runner so the next round can re-run them).
