# BRIEF_impl_inc1a — bd test_C_libtooling-3qlq.2: Inc 1 (part A) — register-free `cq_phi` by kickback
Read `$SP/briefs/BRIEF_common.md` first. Agent name: `impl_inc1a`. Model: opus.

## Where you work
The MAIN checkout `/Users/sorenwilkening/Desktop/CQ_lang`, branch `3qlq-inc1` (checked out,
at dfb8e83). You are the ONLY agent editing it. Build dir `build/` is configured and built at
HEAD. Commit on the branch after every completed step (`wip(3qlq-inc1): <step>`).

Four prep agents work IN PARALLEL in their own worktrees and merge into your branch BEFORE
review: (a) the 540-fixture migration tool + migration (`3qlq-inc1-migration`), (b) the 66 e2e
`.c` rewrites + new slices (`3qlq-inc1-slices`), (c) the golden audit extension
(`3qlq-inc1-audit`), (d) the twin-matrix surface flag (`3qlq-inc1-matrix`). DO NOT do their
work. Consequence for you: the moment you change the surface, ~540 existing fixtures and ~66
slices go red in YOUR tree until (a)/(b) merge. Do not "fix" them; iterate with
`lit --filter` on YOUR new fixtures and on a measured control set, and at the end MEASURE
the red set of `ir-pass-lit` and confirm it is ⊆ `grep -l cq_phi ir-pass/test/*.ll` (540)
— any red OUTSIDE that set is a regression you own.

## Scope of part A (part B — P3 compound conditions, P4 genuine nest, P5 switch — is a
## SECOND agent that starts from your last commit; do not start them)
PRD §6. Shapes: **P1** flat diamond, **P2** angle select, **P6** in-loop rolled, **P7**
deletion of uncontrolled/classically-controlled `cq_phi`, plus the surface change and the
decline partition of §6.3. Read PRD §3 (physics), §6.1 (measured -O1 shapes), §6.2, §6.3.

### Step 0 — compile the customer FIRST (bd memory drbq-inc3-compile-the-twin-first)
Before touching the pass, write to `$SP/progress/impl_inc1a_probes/` (NOT the tree) the
new-surface Grover in the three spellings — flat 2-iteration, rolled `for (i<K)`, per-bit
loop `for (i<4) if ((q>>i)&1) cq_phi(.3)` — using a stand-in `void cq_phase(double);` decl
(the header still has the old cq_phi), run stage 1 (`clang -O1`) and read the IR: confirm PRD
§6.1's table (diamond with NO merge φ; `select i1 %a, i1 %b, false` for the nest; a `select`
on the angle for if/else). Run the ORACLE on each and record the exact decline string —
that is the PRE-increment disposition. Write it in the progress file.

### Step 1 — surface (`include/CQ.h`)
Replace the 15-width `cq_phi_<sfx>` family + `_Generic` dispatch (lines 37–52, 91, 94,
135–153) with ONE extern `void cq_phi(double angle);`. Keep `cq_theta` untouched. If Inc 0's
`cq_ry` macro is not yet in your tree, ignore it (it lands from branch `3qlq-inc0`; no overlap).
Update `tests/frontend/cq_phi_smoke.c` to the new surface (one call, `call void @cq_phi(double`).

### Step 2 — the pass: recognition + P7 + the legacy decline
- `TaintPropagation.cpp` (`resolveSources` ~236, prototype validation ~172–192,
  `collectAndSeed` ~86–123, `WidthDispatch.cpp` 48-entry table ~539–557 and `phiFn` ~114):
  `@cq_phi` is recognized by EXACT name with prototype `void (double)`; it is NOT a taint
  source and NOT a propagator (no data operand). An old-spelling `@cq_phi_<sfx>` declaration
  is now an ordinary unknown external → whatever loud path it takes today
  (`declineTaintEscapes` "unknown call" on a tainted operand) — PIN IT with a decline fixture
  (`lowering_reject_legacy_phi_register_form.ll`) and check what
  `lowering_reject_decl_prototype_phi.ll` now pins (rewrite its header with the decision).
- The `cq_phi` angle (arg 0) is classical (Rule 3). A TAINTED angle operand declines
  (`rotation angle`-class string — find and reuse the existing `taintedAngleGate` /
  `rotationAngleIsTainted` diagnostic spelling in ArmClassify.cpp ~702, ~1492).
- **P7**: after `lowerControlRegions` (CQLoweringPass.cpp line 323 in `run` AND line 689 in
  the second entry point — BOTH), every surviving `call void @cq_phi` is deleted. INVARIANT
  (Rule 1, PRD P7): by then `detectControlRegions` has claimed or declined every tainted `br`,
  so a surviving `cq_phi` sits under classical control only. Assert it: if a surviving call's
  block is reachable through a TAINTED branch condition (walk the CFG preds up to the
  function entry; a tainted `br`/`switch` condition on the path = violation), emit a loud
  diagnostic (`cq: cq_phi under unclaimed quantum control`) — never delete silently. Fixture
  both: `lowering_phi_uncontrolled_deleted.ll` (accept; `CHECK-NOT: cqrt_rz`, `CHECK-NOT:
  @cq_phi`) and the assert-path decline if you can construct it from IR (a tainted `br`
  that ControlDetect DECLINES with a `cq_phi` in its arm must exit non-zero on the
  ControlDetect decline and must NOT have the call deleted first — that is PRD §10.3 lens 4).
- `RotationLowering.cpp` (~154–200, ~388–460): the `cq_phi_<sfx>` lowering to `cqrt_rz_<W>`
  / `cqrt_rz_<W>_controlled` is DEAD after this step. Delete the code paths, not the runtime
  declarations (Q1). `taint.ControlledRotations` stays for the Ry stem.
- `LoopLowering.cpp` (38 mentions), `WireWalk.cpp` (11), `ArmClassify.cpp` (79),
  `SelectClassify.cpp` (21), `PredMuxFlatten.cpp` (23), `RegionTreeDetect.cpp` (12),
  `SwitchArmProve.cpp` (13): every "Rz is diagonal and exempt" / `isPhiCall` clause becomes
  VACUOUS (no `cq_phi_` prefixed call exists any more). PRD P6 says vacuous, not deleted:
  leave the clauses, retarget `isPhiCall`-style helpers so they cannot match the new void
  call by accident (`"cq_phi".starts_with("cq_phi_")` is false — verify each helper; some
  use `isCallToPrefix(V, "cq_phi_")`, some strip a suffix). Add ONE comment at each helper.

### Step 3 — P1: the flat kickback diamond (the Grover fix)
Shape (PRD §6.1 row 1): `pred: %c = icmp <pred> T %q, k ; br i1 %c, %arm, %merge` (or the
`-O1` swapped polarity, Rule 9), `arm: call void @cq_phi(double θ); br %merge`, merge has
NO φ for this region. Today `ControlDetect::soleMergePhi` (line 239) returns null → OffPattern
→ the region declines. The void-arm precedent is `IOSinkLowering::lowerControlledIOSinks`
(line 471, the 7.6 tape-write diamond, `armIOSink` line 461, `ControlShape.h::uncondSucc`)
— READ IT; but the phase region must still go through `detectControlRegions` /
`lowerControlRegions` because P6 (in-loop rolled) lives there (`flatRegionRollableInLoop`,
LoopLowering's `collapseFlattenedLoopRails` — which has nothing to collapse for a phase arm).
Design: extend ControlDetect to recognise a BranchRegion whose merge has no φ and whose arm
is exactly ONE `call void @cq_phi` + `br` as `ArmClass::Phase` with `Merge == nullptr`;
classification reuses `condWireDisposition` / `condDataUseDisposition` / the compare
lowerability (`comparePredLowerable` ~1776) and the P1 position fences as the existing phase
path does (the condition register is NOT relabelled by a kickback, so R6-style stale-record
fences do not apply to the arm — but the stale-CONDITION fences do). Emission: a new
`emitPhaseKickbackRegion` in `SwapRouteEmit.cpp` REPLACING the Rz half of
`emitInPlaceRotationRegion` (line 531; keep the Ry half byte-for-byte — M-β): the ordinary
flag mint (`CompareLowering::lowerCompareToFlag` — whatever `emitRegion` line 808 calls),
`cqrt_x(f)` bracket for `R.ArmNegated`, `cqrt_rz_i1(f, θ)` via `wd.rzRtFn("i1")`, the
ordinary compare `_unc` strip, `cqrt_free(f)`; erase the call; `RegionFlatten` erases the
diamond. No RAUW at all (no φ). Record the flag+gate in whatever `taint.*` sets the strip
and `free_pairing_check.py` need (read `tools/free_pairing_check.py`'s header: `cqrt_rz` is
transparent to it; the flag mint/strip/free must pair STRICT).
Golden target, measured from PRD §1 for `if (q == 5) cq_phi(PI);`:
```
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_rz_i1(h1, 0x1.921fb54442d18p+1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
```
Fixtures (red-green, Rule 12): accept `control_phase_kickback_diamond{,_negated,_ifne,
_derived_cond,_f64_cond}.ll` with an `ACNT`/`NOROUTE`-style whole-file negative prefix
(NO `cqrt_cswap`, NO `cqrt_rz_i32`, NO `_controlled`, NO surviving `@cq_phi`; count
directives in their OWN prefix — the Inc-3/Inc-4 F-L6-1 lesson: a positive COUNT inside the
NOT prefix windows every NOT after it). Declines for §6.3: N>1 `cq_phi` in one arm; mixed
arm (`cq_phi` beside a value op / an Ry); bare tainted `i1` condition (no compare → Inc 1b,
its own string, `cq: cq_phi under a bare i1 condition` or similar — record the exact string
in the progress file); Q+Q compare (pre-existing string); multi-block arm; tainted angle;
inside a value region. Each decline mirrors its string character-for-character.

### Step 4 — P2: the angle select, Rz stem
`if (c) cq_phi(A); else cq_phi(B);` arrives as ONE `call void @cq_phi(double %sel)` with
`%sel = select i1 %c, double A, double B`. `SelectClassify` gate 3 → `classifyAngleSelect`
(ArmClassify.cpp:4133) and `AngleSelectEmit::emitAngleSelectRegion` (line 76) currently key
on a `cq_phi_<sfx>`/`cq_theta_<sfx>` consumer with the select at arg 1. Add the void-`cq_phi`
consumer (select at arg 0). Rz lowering (PRD §3): flag mint; `cqrt_x(f); cqrt_rz_i1(f, B);
cqrt_x(f); cqrt_rz_i1(f, A)`; strip; free — EXACT, no subtraction, so the 2b by-difference
form, `angleSelectArmsAdmissible` (line 3921) and the 2^-40 fence (`kAngleSelectMaxRoundingRad`)
are RETIRED for the Rz stem and RUN-TIME arms are ADMITTED for Rz (owner Q3, assumed yes).
The Ry stem stays BYTE-FOR-BYTE (constant arms only, clearance F-11): pin BOTH directions
(`control_angle_select_rz_runtime_arms.ll` accept; the existing
`control_angle_select_ry_reject_runtime_arms.ll` still declines; a `double` `ConstantExpr`
arm still refused on Ry — check whether that clause is stem-specific and say which).
Existing Rz-stem fixtures (`control_angle_select_rz_*.ll`, ~half of the 70-file family)
will be REWRITTEN by the migration agent; you write the new ones.

### Step 5 — P6: in-loop rolled
Verify (do not assume) that the P1 region inside a classically-bounded `for` lowers ROLLED
through the 8h7d.5 path: `ControlDetect::flatRegionRollableInLoop`, LoopLowering's
round-2 collapse, `staleRailRecordRead` — a kickback has no gate on `q`, so
`collapseFlattenedLoopRails` must find nothing to collapse and must not decline on that.
Fixtures: `control_phase_kickback_inloop.ll` (accept, rolled: exactly ONE `cqrt_rz_i1` in
the loop body, `br` back-edge intact) + the loop declines that stay (quantum-bounded exit,
irreducible, multi-latch, nested) with their EXISTING strings. Check the per-bit idiom
(D4) from Step 0 lowers rolled at K=4 and K=32 with IR size independent of K (measure line
counts); it is `and(h, 1<<i) → icmp eq 0 → x → rz_i1 → x → 2 _unc → 2 free` per PRD §9.

### Step 6 — hand-back measurements
- `ctest --test-dir build -R ir-pass-lit` in the background; from the log, list every red
  fixture and partition: (i) in `grep -l cq_phi` (pending migration) vs (ii) other. (ii) must
  be empty or explained.
- Run the three Step-0 customer programs + `slice_control_seq_grover.c` (rewritten to the
  new surface, in `$SP/progress/impl_inc1a_probes/`) through the full pipeline on YOUR binary
  and the ORACLE; paste the traces. The subject's Grover trace must show `cqrt_rz_i1` on
  the FLAG and no `_controlled`, no `cqrt_cswap`, no `cqrt_rz_i32`.
- Commit. Progress file hand-back per BRIEF_common. Do NOT write the notes file; the
  orchestrator's review agents do.
