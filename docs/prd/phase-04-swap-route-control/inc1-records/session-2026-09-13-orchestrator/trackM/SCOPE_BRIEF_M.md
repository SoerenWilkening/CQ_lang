# SCOPING brief — Track M: the REGION-MERGE-φ rail leaf for the 4.4 DATA SELECT (and the VALUE-diamond) consumer — bd `boi6` (the D-B half), probe `p20`

Written 2026-09-13 by the orchestrator. Model: opus. **READ-ONLY, measure-first.** You build nothing and run
no suite; you run the per-probe pipeline against the ORACLE only. Protocol: `../PROTOCOL.md` (read it
first; your row is "scoping"). Record: `SCOPE_M.md` beside this file; probes under `probes/` with a
`README.md` verdict table and a runner script. Final message ≤40 lines.

## 0. The customer and the wall — MEASURED on the ORACLE (do not re-measure §0 of `../ORCHESTRATOR_PROMPT.md`; extend it)

`../probes/owner_file_2026-09-13.c` = the 2026-09-11 file + ONE line, `if (b1) a -= 3;` (line 99). It declines
`…:99:9: … cq controlled lowering: control flow under quantum control`. `-O1` (`../probes/owner.main.O1.ll`):
one fused diamond `br i1 %1, label %4, label %2` (arm = FALSE successor); merge phis `%5 = phi i32 [5,%2],[2,%0]`
(the `a`-mux — peelable) and `%6 = phi i1 [%3,%2],[false,%0]` (the `b1` STATE-PREP merge — NOT peelable, P3
arm-defined incoming); line 99 is `%8 = select i1 %6, i32 %7, i32 %5` — a 4.4 DATA select whose CONDITION IS THE
PREP'S MERGE φ. Firing site (lldb on `diagnoseUnderControl`): `SelectClassify.cpp:781-782`, GATE 2 of
`classifySelectRegion` — `collectCondTree(%6)` returns false: the only leaf kinds are `CmpInst` and
`isCondRailLeaf` (`SelectClassify.cpp:543-549`: `dyn_cast_or_null<CallInst>` + `getName() == "cq_theta_i1"`).
`vb`/`vc` (other spellings of line 99) produce BYTE-IDENTICAL `main` IR — no source rewrite helps.

`va` (line 99 deleted) ACCEPTS: 19 trace lines (`../probes/va.trace`), STRICT 2b clean. **`va` must stay
byte-identical under any widening** — it is the discriminator.

## 1. What to measure and write (SCOPE_M.md sections)

**§0 Verdict table, ≥20 probes on the ORACLE.** Every C spelling the owner might write around the shape (both
polarities `if (b1)` / `if (!b1)`; `a -= 3` / `a += 1` / `a = 7`; `b1` measured before/after the select; `b1`
read as data (`zext`); TWO selects on one prep output; a prep output feeding a `cq_phi` (= `../../session-boi6/`
probe `p5`); N=3 `../probes/vd.c`; the prep un-negated (`if (b0)` arm on the TRUE edge); `int b1` with `bool b0`
(row B) + line 99; `int b0`/`int b1` + line 99; `cq_invert_begin/_end` around it; the S† `b0 = cq_theta(b0,-.5)`
after line 99; `b1` prepped twice; a run-time `a`), PLUS the hand-IR twins: (T1) `owner.main.O1.ll` with `%6`
replaced by the HOISTED `cq_theta_i1` call as `emitInPlaceRotationRegion`'s M-β would leave it (i.e. the module
AFTER the prep region emitted, BEFORE the select is classified) — does the ORACLE accept T1 and what is its trace?
That trace, read line by line, is the TARGET STREAM: it must be `va.trace`'s 19 lines followed by ONE more
rail-root CNOT-copy select merge controlled on `h1` (`alloc_i1→bf; cnot(h1,bf); alloc_i32(0)→out;
copy_i32_controlled(bf, h_{a-3}, out); x(bf); copy_i32_controlled(bf, h_a, out); x(bf); cnot(h1,bf); free(bf)`,
with the `a-3` chain hoisted and `_unc`'d) — READ IT OFF THE ORACLE, do not guess it. (T2) the same with the
select's condition left as the φ but the φ's incomings both on ONE wire (the `p5` shape) — declines where?

**§1 Every site, `file:line`, predicate VERBATIM** (line numbers at 86c0d25 — re-grep, `../../session-boi6/SCOPE_boi6.md`
§1 is the table to update, its numbers are from 0c7380c): `isCondRailLeaf` `SelectClassify.cpp:543`;
`CondTree::RailLeaves` (`SelectClassify.h:88`, `SmallVector<CallInst*,2>` — the TYPE is the enforcement, H-3:
**do not propose retyping it**; a new field `RailPhiLeaves` + an `AllowRailPhi` flag, the `AllowLogicalSelect`
precedent); `collectCondTree` `:551`; gate 2 `:781`; the r9e5 rail ladder in `classifySelectRegion` (rungs
(i)/(ii)/(iii) with the SELECT as read point — quote them); `RailLadderProven` `:1115` and `SelectMergeEmit.cpp`'s
backstop; `CondTreeEmit.cpp` `FlagOf[V]=V`, `RootIsRail`, `CopyRailRoot` (`CopyRoot = CopyRailRoot &&
isCondRailLeaf(Root)`); `markRailCondRead` (`ArmClassify.cpp:2383`) / `reverifyRailCondReads` (`:2485` — does it
`dyn_cast_or_null<CallInst>` and SKIP a φ record? after M-β's RAUW the `WeakTrackingVH` follows to the hoisted
CALL — so for a FLAT merge φ does the record become re-askable? measure by reading, then by a probe);
`RegionFlatten.cpp` "never erase a user's rail" (`isCondRailLeaf`-keyed, H-7); `classifyArms` ternary
(`ArmClassify.cpp:3325` region, `kBareRailCondReason` vs `control flow`); `Specialization.cpp` RailLeaves skip;
`emitInPlaceRotationRegion` (`SwapRouteEmit.cpp:667`) M-β RAUW target (`:940` `G.first = TNeg`) — the ONE
OWNER of "what this merge φ becomes"; `lowerControlRegions`' Kahn order (`SwapRouteEmit.cpp:2370-2600`,
`reorderable()` at `:2494`) — is a `SelectRegion` ordered AFTER the `InPlaceRotation`/StatePrep region that
defines its condition, and if not, what does the precedence graph do with the pair?; `detectControlRegions`
(`ControlDetect.cpp:725-870`) block-order: is the fused diamond's `br` classified BEFORE the select in `%4` in
the same round (it should be — `%0` precedes `%4`), so at select-classification time the plan already holds the
prep region's verdict?

**§2 The two candidate spellings — feasibility of EACH, measured, and a recommendation.**
(a) **Leaf admission by CALLING the one owner**: the select's condition φ is admitted iff it is the `MergePhi`
of a region ALREADY CLAIMED in this plan as `InPlaceRotation`/`StatePrep` (so M-β will RAUW it to the region's
last hoisted gate, a `cq_theta_i1` CALL) — name the exact field/function that answers "this φ is that region's
merge φ" (never a second spelling of the classifier's verdict); then the r9e5 rail ladder is asked with the
region's HOISTED theta as the rail (is it available at classification time? it is minted at emission — so what
does rung (ii)/(iii) walk over before emission?). The emitted CNOT copy names the φ, which the region's M-β then
RAUWs → the hoisted call → the handle. Which order must `lowerControlRegions` emit the two regions in for the
CNOT to sit AFTER the prep gates in the stream, and does Kahn already give it?
(b) **Deferral**: leave the select unclassified in round 1 when its condition is a same-plan region's merge φ;
after `lowerControlRegions` the φ is gone (M-β) and a SECOND detection round would see `cq_theta_i1` and take the
r9e5 path unchanged. Measure: (b1) does anything re-run detection today for this shape? — `repropagateControlMerges`'s
`detectAndLowerOnwardControl` is a no-op unless `taint.UntaintedMergeRails` is non-empty
(`TaintPropagation.cpp:1653` region — re-grep); (b2) Rule 1 "no third path": a deferred-and-never-claimed select
MUST hit a loud decline — measure that `declineClassicalMuxes` (`TaintPropagation.cpp:1253`) fires on a surviving
tainted-condition select (hand IR: a select on a tainted `i1` that no region claims), with the exact string;
(b3) what `RegionFlatten` does to the merge block the select lives in. State the L1 obligation for (b): "a stage
that runs ONCE has a round-2-FALSE premise" — which stages between round 1 and the deferred re-detect would
compute over the un-lowered select?
Recommend ONE spelling with the reason; the orchestrator decides.

**§3 Hazards (H-n), reviewer order.** At least: the L1 round-2 windows this consumer owes (`markRailCondRead`
for the CNOT-copy read; `!cq.branchphase` n/a; `taint.CmpCondReads` n/a — say why) and WHERE each is re-asked;
H-3 (type = enforcement); H-7 (`RegionFlatten`); H-8 (which STRING a φ takes at every non-select consumer —
decide once); the control is a PREPPED register: on the `b0=0` branch `b1 = Ry(.5)|0⟩`, on `b0=1` `b1 = |0⟩` —
the CNOT copy `Σ αₓ|x⟩|x⟩` is basis-faithful on both; the un-copy returns `bf` to `|0⟩` on every branch — write
the state vector; the 3d8q class (the select's CNOT reads the M-β name, the `cq_measure(b1)` reads the same name
— same register, fine; but TWO preps of `b1` = two siblings → must decline, which fence?); `cq_invert` (Phase 8,
unimplemented — the link fails; note it); the value-DIAMOND consumer (fg9k's shape on a merge φ): does plain C
ever reach `classifyArms` with a merge-φ condition, or only hand IR? If only hand IR, say so and scope it as
"admit at the same site, pin by hand IR".

**§4 Decline partition** — what must STILL decline after the widening, with the string: a φ over TWO distinct
rails; a φ whose region is NOT an in-place/prep region (a value region's merge φ, a 6.5 `%out`); a φ in a loop
(`p6` class, loop layer first); a compound tree with a φ leaf; the phase consumer `p5` (goes to the wire fence
`condition predates a non-diagonal gate` — bd `drbq.7`; the orchestrator files it there unless the owner says
otherwise); the φ read as a condition BEFORE its region has been claimed (cannot happen in block order — prove
or measure).

**§5 Fixtures / slices / witnesses / cost.** Accept fixtures (whole-file count prefixes, `NOX-NOT: cqrt_x(i32 %h`
on the user register); decline fixtures per §4 row (RED on the ORACLE for the right reason); e2e:
`slice_control_cascade_two_bools.c` (= the owner's file, STRICT 2b) with the golden read off T1; the injection
matrix rows; production-line estimate per file; adversarial rounds (budget 2 minimum).

## 2. Style models

`../../session-boi6/SCOPE_boi6.md` (measure-first, the site table, hazards as H-n with the fix cost);
`../../session-l4x4/SCOPE_l4x4.md` §0/§2.1 (target streams read off accept twins). Every number measured, with
the command in `probes/README.md`. Line numbers dated to 86c0d25.
