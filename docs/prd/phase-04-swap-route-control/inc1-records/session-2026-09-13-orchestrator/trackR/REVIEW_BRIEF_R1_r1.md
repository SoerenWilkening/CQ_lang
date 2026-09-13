# Rule-13 review brief, round 1 — Track R increment R-1 (bd `rb9x`): F2 excludes the peel's compare CLONES via a `taint.PeelClones` record

Written 2026-09-13 by the orchestrator. Model: opus. Worktree `/Users/sorenwilkening/Desktop/CQ_rb9x`, branch
`rb9x-f2-clones` (base `main` 81956a2), `build/` current (`cq-opt` sha256 `221c1caa465db61e…` per
`GATES.md` — your ONE build-side obligation is `shasum -a 256 build/ir-pass/cq-opt` and confirming it
matches). Protocol: `../PROTOCOL.md`, row "review": **NO build, NO suite**; `GATES.md` is fact for that
hash (`ir-pass-lit` 1900/1899/1 XFAIL/0; injection 2 fixtures × 10 mutations 0 MISSED; corpus 2949 rows,
12 movers, 0 different-IR); at most ONE fixture re-run to test a doubted claim. ORACLE
`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` (`fbbe0820…`, read-only). Do not edit
`ir-pass/`, `include/`, `tests/`, `tools/` anywhere. Read in order: `BRIEF_R1.md`, `IMPL_R1.md` (all; §7's
nine open items), `SCOPE_R.md` (§1.1 the route, §2 R-1 + the PREIMAGE argument, §3a the dominance TRAP,
§3b the two-diamond reach, §3e the `zext` reach, §5), `SCOPE_R2.md` §0–§1 (the rival audit — what fences
actually protect F2's family), `GATES.md`, `probes/README.md`, the diff (`git diff -- ir-pass`), the new
fixtures (`git status --short`), `CLAUDE.md` (Prime Directive; Rules 1, 12, 13, 14; CORRECTNESS RISK §2
"F1 / F2", §3 L1/L5/L8, §4 "what the F2 narrowing silently absorbs" and its retirement triggers).

## What changed

Three sites, +11/−1 non-comment: `TaintPropagation.h:322-332` (`SmallVector<WeakTrackingVH,4> PeelClones`
+ `isPeelClone()`); `MergePhiPeel.cpp:516` (`taint.PeelClones.push_back(Clone)` beside
`Tainted.insert(Clone)`; the `:454-469` false comment replaced by SCOPE §3f); `ArmClassify.cpp:1682`
(`… && !CondWire.count(V) && !Taint.isPeelClone(V) && f2Exact(V,S) == Seed` — at the TEST only, the users
walk unpruned). Round-2: `taint = propagate(M,wd)` occurs 15× but every one is in the pre-peel prologue,
`repropagateControlMerges` mutates and never replaces the set, so round-2 clones APPEND (`R1_p80_bool.c` is
a round-2 customer that now accepts). Fixtures: 2 accepts (the `rb9x` shape, seed `false`/`true`), the
pre-peel/hand-written pair pinning PROVENANCE-NOT-SHAPE (same circuit, opposite verdicts), `r_R1b`/`r_R5`
(second non-clone compare — kept declining), `r_R4` (kept declining), the two-diamond shape (unreachable at
HEAD — declines `control flow` at `reorderable()` — pinned with a bd `35t0` retirement trigger),
retirement-trigger header lines on `control_peel_reject_fp_stateprep.ll` and `…_second_flag_i1.ll`. Slice
`e2e-slice-control-stateprep-bool-under-int-compare-fused` 22 lines measured, 2b `4 verified`.

## Where to look — over-ACCEPT is the only unforgivable bug here (F2 is the fence that lost four rounds running)

1. **The PREIMAGE argument, attacked as a claim about the CLONE's consumers.** "The clone has exactly one
   consumer (the peeled select), so no source program passed it to a theta." Find a way the clone acquires
   a SECOND consumer before F2 asks: a stage between the peel (`CQLoweringPass.cpp:451`) and `classifyArms`
   — `adjudicateTaintDelta`, `foldIdentityBitcasts`, `declineStaleRecordOps`, `detectSpecializations`, the
   PredMux flatten — or a round-2 re-propagation that RAUWs something onto the clone; or a clone that the
   peel manufactures for a φ whose OTHER incoming is itself an `i1` value (a φ over `i1`s peeled into a
   select whose arms are `i1` — does the peeled SELECT then become an `i1` that a later prep's seed can
   collide with, and is THAT excluded? it should NOT be: the select is not a clone).
2. **`O3_mux_quantum_incomings` and `R1_p80_bool` — the customers the scope did not measure.** Attack
   them hardest: re-derive each accept's state vector from its stage-1 IR; name every value F2 pinned
   before R-1 (`CQ_CTRL_DBG=1` on the ORACLE) and confirm each is a manufactured clone; construct the
   nearest UNPEELED twin of each and confirm it accepts on the ORACLE (the direction argument of SCOPE §3b).
3. **The two-diamond reach (§3b).** The implementer bisected it as unreachable at HEAD because `hcrg`'s
   `reorderable()` declines the composition. That is a STRUCTURAL guard, not a semantic one (L6), and bd
   `35t0` is filed to widen `reorderable()`. Construct the composition in HAND IR that `reorderable()`
   admits today (two `BranchRegion`/`PhaseKickback` kinds — is a state-prep region a `BranchRegion` kind?
   check `ControlRegion::Kind` for the prep) so the second region's F2 sees the FIRST region's clone
   pinned on ITS edge — does R-1 exclude it, and is that accept correct? Grade it either way and say
   whether the fixture's retirement trigger is the right one.
4. **`WeakTrackingVH` lifetime.** The clone is erased by `SelectMergeEmit` (step 6) / `lowerOps`. After
   erasure the handle is null; `isPeelClone(V)` on a null entry — can a NEW instruction be allocated at the
   same address and compare equal to a stale non-null entry? (`WeakTrackingVH` nulls on delete — confirm
   by reading `ValueHandle.h`; a raw pointer would not.) And the reverse: can the peel's clone be RAUW'd
   (not erased) to another value so the handle FOLLOWS it and `isPeelClone` starts answering true for a
   user-written compare?
5. **The `zext` reach (§3e) and the `i1`-only claim.** `r_R4` stays declining by design; confirm on the
   subject; then a plain-C program where the clone's SELECT (not the clone) is `zext`ed and pinned —
   still declines (should).
6. **The fp fixture.** `control_peel_reject_fp_stateprep.ll` must still decline through `f2Model`'s
   conservative arm (the users walk is unpruned) — confirm on the subject with its own `CQ_CTRL_DBG=1`
   anchor, not by the lit line alone.
7. **IMPL §7 item 4** — `datamux_peeled_control.ll`'s unqualified `CPCNT-NOT: @cqrt_copy_` matches its
   own `declare`: is the fixture green by accident, and does that accident hide anything R-1 changes?
8. **Over-declines met in passing** (`R2_p80_window` → `control flow`, `R4_p80_measured` → `condition
   measured before the control route`, `b_HP_b_orig` one fence earlier): grade each.
9. **Every accept: `-O1` reachability + state vector; every decline: is the circuit invalid?**

## Method

Scratch `/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/ddf48412-8498-4d8b-9bac-51279fb090c0/scratchpad/trackR_review/`;
plain C `-O1` first, hand IR second; SUBJECT vs ORACLE per probe; grade CONFIRMED-MISCOMPILE /
OVER-ACCEPT-ARGUED / OVER-DECLINE / LEAK / DOC; verdict BLOCK / CLEAR-WITH-ITEMS / CLEAR. Report
`review_R1_r1.md` beside this file, probes `review_R1_r1_probes/` with a runner. Final message ≤30 lines:
verdict, findings one line each with grade + reproducer, items 1/3/4 answered explicitly.
