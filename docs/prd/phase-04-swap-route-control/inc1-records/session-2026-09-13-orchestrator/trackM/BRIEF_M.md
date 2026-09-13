# Brief — Track M IMPLEMENTATION: the REGION-MERGE-φ rail leaf for the 4.4 DATA SELECT — bd `boi6` (D-B half), probe `p20`, spelling (a)

Written 2026-09-13 by the orchestrator after `SCOPE_M.md`. Model: opus. Worktree
`/Users/sorenwilkening/Desktop/CQ_mphi`, branch `mphi-rail-leaf` (fast-forwarded to `main` = the commit that
carries `SCOPE_M.md`), its OWN `build/` (configure: `cmake -S . -B build -DLLVM_DIR=$(brew --prefix
llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release && cmake --build build -j8` — BOTH targets, always).
Protocol: `../PROTOCOL.md`, your row is "implementation": inner loop = `lit --filter` + single slices;
`ir-pass-lit` ONCE at hand-off; corpus sweep ONCE at hand-off → `probes/corpus_<hash16>.txt`; the injection
matrix ONCE at hand-off; NO `^e2e-`, NO full suite, NO equivalence sweep. Append to `GATES.md` (hash-keyed,
already carries the scoping line) after every rebuild. Record `IMPL_M.md` beside this file. Do not commit,
do not push. Never write outside your worktree. Report only what you ran (§3.3: `cited:` vs `ran:`).

## 0. Read first

`SCOPE_M.md` — ALL of it (§0.2 the ±1 asymmetry; §0.3 why the wire is CLEAN here; §0.4 the 29-line target
stream T1 read off the ORACLE; §1 the 24-site table at `01c89b5`; §2.1 the predicate verbatim and the three
rungs; §2.2 why deferral is a crash; §3 H-1..H-10; §4 the decline partition; §5 fixtures/injection/cost) and
`probes/README.md` + `probes/run.sh`. Then `CLAUDE.md` (Prime Directive; Rules 1, 6, 7, 8, 12, 13, 14, 17,
19; CORRECTNESS RISK §1 the r9e5 bool data-select row, §2 the rail ladder, §3 L1/L2/L4, §4; Build & Test —
the CQPass-only false-green trap); `../../session-r9e5/IMPL_B1.md` (the 4.4 rail select you are handing your
condition to — its ladder, its `CopyRailRoot` stream, its fixture prefixes); `../../session-l4x4/IMPL_l4x4b.md`
(record style; §4 red-green log; §4c injection matrix; §6 corpus diff; §6b gates).

## 1. Scope — the SELECT consumer ONLY

IN: a 4.4 DATA `select` whose condition is a `PHINode` that is the `Merge` φ of a region ALREADY in the plan
as `BranchRegion` with `ClassArm`/`ClassArmFalse == InPlaceRotation`, `RailLadderProven`, non-empty `Shadow`
— i.e. the owner's `if (b1) a -= 3;` after `if (!b0) b1 = cq_theta(b1, .5)`. Both prep polarities (negated
and true-edge); integer data selects of every width the r9e5 path lowers; fp data selects if r9e5 lowers
them on a rail (measure). OUT — must KEEP its current string, pinned: the VALUE DIAMOND on a φ (`m27`,
`control flow` — bd `fg9k` must land for a rail first; H-10); the PHASE consumer on a φ (`m08`, `branch
phase on a bare i1 condition` — filed separately as a leaf-grammar over-decline); the Ry-stem angle select
and the depth-2 nest (`kBareRailCondReason` / unchanged); `Specialization` (skip a φ tree, one line); a φ in
a loop (`m30`, the loop layer's string). **H-8 = change nothing**: do not wire the new predicate into
`ArmClassify.cpp:3160`/`:3325`; a φ at a `br` keeps `control flow`.

## 2. Decisions taken by the orchestrator (build these; do not re-litigate)

1. **Spelling (a)** — leaf admission by CALLING the one owner, the predicate of `SCOPE_M.md` §2.1 verbatim
   (`R.Kind == BranchRegion && R.Merge == P && (R.ClassArm == InPlaceRotation || R.ClassArmFalse ==
   InPlaceRotation) && R.RailLadderProven && !R.Shadow.empty()` — or `ShadowFalse`, whichever the false-arm
   verdict fills; read `ArmClassify.cpp:4428-4445` and `ControlPlan.h` to get the exact fields). `plan` is
   already a parameter of `classifySelectRegion`. Never re-derive the classifier's verdict.
2. **H-3**: a NEW `CondTree::RailPhiLeaves` field (`SmallVector<PHINode *, 2>`) and a NEW `collectCondTree`
   flag `AllowRailPhi` defaulting **false**, passed `true` ONLY by `classifySelectRegion`. Do not widen
   `isCondRailLeaf`; do not retype `RailLeaves`. Re-arm the `SelectClassify.h:78` obligation note for the new
   field. The grammar's syntactic test is deliberately weak (a tainted 2-incoming `PHINode` of type `i1`);
   the proof is the classifier's predicate above.
3. **The ladder** at the select (rung 0 = the predicate; rung (i) `taint.Tainted.count(P)`; rung (ii)
   `railMeasuredBeforeReadPoint` over **`condProvenance(P)`** — never over `Shadow.front()` alone — H-2,
   `m05` is the red-green program and must flip `control flow` → `condition measured before the control
   route`; rung (iii) = the existing gate 2c at `SelectClassify.cpp:956`, already φ-correct — leave it and
   PIN that it fires for `m15`/H-6). `R.RailLadderProven = !Tree.RailLeaves.empty() || !Tree.RailPhiLeaves.empty()`.
4. **H-1** — `SelectMergeEmit.cpp:96`/`:215` must read the condition off `cast<SelectInst>(R.Merge)->getCondition()`
   (M-β has rewritten it to the theta CALL by then), never the raw `R.Condition` (a dangling pointer after
   the prep's flatten). If the re-read value is NOT `isCondRailLeaf` (and not a compare tree the existing
   path handles), **decline loudly** (`control flow`) — the `RailLadderProven` backstop precedent. Do NOT
   make `ControlRegion::Condition` a `WeakTrackingVH`. Pin H-1 with a fixture that would have dereferenced
   freed memory (ASan is not available in the Release build — pin by the accept's stream being T1 and by a
   `CQ_CTRL_DBG=1`-visible re-read; say in IMPL_M.md how you convinced yourself the raw pointer is gone).
5. **`CondTreeEmit.cpp`: 0 lines EXPECTED** (by emit time the condition is a `cq_theta_i1` call). VERIFY,
   do not assume: if the record at `CondTreeEmit.cpp:248` (`markRailCondRead`) or `RootIsRail` ever sees the
   φ, say so and handle it; the emitted stream must be the r9e5 one byte for byte (`m18`'s 29 lines).
6. **H-6 — probe FIRST, before the rest of the widening is polished**: after the grammar admits the φ,
   `m15` (two preps of `b1`, the second after the select) MUST decline at rung (iii)/gate 2c with
   `condition predates a non-diagonal gate`. If it ACCEPTS, **STOP**, write IMPL_M.md §7 with the trace and
   the walker's answer, and report — the increment then needs a 3d8q-class fence that is a different bead.
7. **H-7** `RegionFlatten.cpp:96/:189/:193`: add the new predicate beside `isCondRailLeaf` (defence in depth;
   no subject today — say so in the comment). **`Specialization.cpp:296`**: also skip a φ-carrying tree.
8. **H-4 pin**: one fixture whose comment states the emergent round-2 property (`RailCondReads`'
   `WeakTrackingVH` follows M-β's RAUW before `reverifyRailCondReads` at `CQLoweringPass.cpp:510`, so
   `ArmClassify.cpp:2504`'s `CallInst` cast succeeds) with `TaintPropagation.h:334-338`'s retirement trigger
   cited. Construct the round-2 window through the select if you can (a `%out`-derived `b0` via the
   `session-9pum` two-TU recipe); if the shape cannot reach the select, say why.
9. **H-9** `cq_invert` around the accepted program: add a DECLINE probe (`m13`-class) and record what the
   subject does (accept-then-link-failure is the pre-existing Phase-8 state; if it now accepts at `opt`,
   note it under the filed bd `ixao` and move on — do not build inversion).

## 3. Rule 12 — red-green, IN THIS ORDER

1. **Pin the ORACLE accepts FIRST, before any pass edit**: `m17`, `m18`, `m19` as fixtures
   (`control_swap_accept_select_rail_after_prep{,_negated}.ll` = `m18`/`m19`; `m17` as a slice) — green on
   the ORACLE and on your unmodified build, byte-identical stream; plus `va` as a fixture-level byte-identity
   pin (`slice_control_cascade_two_bools_base.c` or reuse the existing `slice_control_inplace_ry_bool_stateprep_negated`
   family if it already IS `va` — check `tests/e2e/` before adding). These are the discriminators that the
   widening adds an ACCEPT and not a STREAM.
2. **Declines RED on the ORACLE for the RIGHT reason**, one per `SCOPE_M.md` §4 row:
   `control_swap_reject_select_mergephi_{two_rails,value_region,out_rail,unclaimed,tree_leaf,measure_before,sibling_theta,inloop,invert}.ll`
   (mirror strings character-for-character; Rule 12(b): the `not` on the RUN line is the pin, no vacuous
   `CHECK-NOT`s). `measure_before` (`m05`) and `sibling_theta` (`m15`) are RED on the ORACLE with the WRONG
   string (`control flow`) today and must go GREEN with the RIGHT one.
3. **The widening** (decisions 1–8), minimal.
4. **Accepts**: `control_swap_accept_select_mergephi_rail{,_negated,_prep_true_edge,_int_amux,_two_selects}.ll`,
   each with whole-file count prefixes derived from the pass output (`FCNT`/`XCNT`/`CNOTCNT`/`ACNT`),
   `NOX-NOT: cqrt_x(i32 %h` on the USER register, `NOROUTE-NOT: cqrt_cswap`, `NOFREE-NOT` on the prep rail's
   handle. Counts in their OWN prefix; negatives pure (Rule 12(a)).
5. **Injection matrix** over every new accept: injected `cqrt_x` on the user register; extra `cqrt_free`
   on `h1`; extra uncontrolled `cqrt_ry` on the rail; a `cqrt_cswap`; a rail handle in a classical
   immediate slot; the CNOT pair unbalanced; the two `copy_i32_controlled` swapped. Report MISSED per
   fixture; budget the second pass.
6. **e2e (STRICT stage 2b)**: `slice_control_cascade_two_bools.c` = `../probes/owner_file_2026-09-13.c`
   verbatim (strip nothing but the comment block if the harness dislikes it — keep the code lines) with the
   29-line golden = `va.trace` lines 1–16 + `m18.trace` lines 17–26 renumbered (`h5→h1`, `h2→h3`) + three
   measures — READ IT OFF YOUR BINARY and diff against that prediction; `slice_control_cascade_two_bools_uncond.c`
   = `m17`; `slice_control_cascade_two_bools_int.c` = `m11`. The twin gate ("the select half of `m17`'s
   trace is byte-identical to the owner slice's select half"): add it as a ctest entry only if a ≤10-line
   script/CMake addition suffices; otherwise record the diff command and its empty output in IMPL_M.md §5.
   Register after the last `slice_control_inplace_ry_bool_*` group; run each with `ctest -R '^e2e-slice-<name>$'`.

## 4. Record: `IMPL_M.md`

§0 measured before coding (SCOPE §0.1's 27 rows re-run on your UNMODIFIED build — must equal the ORACLE);
§1 the grammar + classifier sites (`file:line` before/after, the predicate verbatim); §2 the emitter (H-1)
and the 0-line `CondTreeEmit` claim verified; §3 the three rungs + H-6's measured answer; §4 red-green log
(each fixture RED then GREEN, with the lit line); §4c injection matrix with MISSED; §5 e2e (the 29-line
trace, read line by line against the source; the twin diff); §6 corpus sweep ORACLE-vs-SUBJECT over
`ir-pass/test/*.ll` + every session probe dir (`../PROTOCOL.md`) — movers must be DECLINE→ACCEPT on `control
flow` at a select (list each) or DECLINE→a LATER fence (`m05`, `m15` — list each); 0 ACCEPT→DECLINE; 0
both-accept circuit changes; §GATES = a copy of `GATES.md`; §7 open questions / found-in-passing (every
over-decline met in passing with its measured string — the orchestrator files it).

Final message ≤35 lines: the sites, H-1's fix, H-6's measured answer, the owner-file trace line count and
whether it equals the prediction, movers (counts by string), `GATES.md` verbatim, §7.
