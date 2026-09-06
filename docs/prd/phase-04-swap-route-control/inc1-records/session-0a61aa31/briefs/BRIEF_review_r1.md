# BRIEF_review_r1 — Rule-13 ROUND 1, read-only adversarial lenses on Inc 1 part A (kickback cq_phi)
Read `$SP/briefs/BRIEF_common.md` first, then `$SP/briefs/BRIEF_impl_inc1a.md` (what the
implementer was asked to build), then `$SP/progress/impl_inc1a.md` (what it says it built).
Agent name: `review_r1_L<n>` (your lens number). Model: opus. READ-ONLY: you never write
into `ir-pass/test`, `tests/`, `include/`, `ir-pass/src`. All your reproducers live under
`$SP/progress/review_r1_L<n>/`. You report; a separate fix agent acts.

## Subject and oracle
SUBJECT: the main checkout `/Users/sorenwilkening/Desktop/CQ_lang` at commit fa96336
(branch `3qlq-inc1`), binaries `build/ir-pass/cq-opt` + `build/ir-pass/libCQPass.so`,
archives `build/runtime/*.a`, header `include/CQ.h` (the NEW `void cq_phi(double)`).
ORACLE: `$SP/wt/pre-3qlq` (52d7764, the OLD `cq_phi(x,θ)` surface). Every program you cite
must be compiled, lowered, STRICT stage-2b checked, linked and RUN on BOTH — for the oracle,
spell the SAME program in the old surface where it exists (`x = cq_phi(x, θ)`) and say when
no oracle spelling exists (a kickback under a compound condition has none — the oracle
declines). A finding is CONFIRMED only with a reproducer that runs on the subject and a
statement of what the correct unitary is versus what the trace does (analytic/trace
reasoning; there is no simulator — Rule 2).

## The claim under review (PRD §3, §6.2)
Under a tainted single-compare condition, `cq_phi(θ)` lowers to: flag mint (the existing
compare template into a |0> ancilla f) → [`cqrt_x(f)` if the arm is the false successor] →
`cqrt_rz_i1(f, θ)` → [`cqrt_x(f)`] → the compare `_unc` strip (reads the SAME operand
registers as the mint) → `cqrt_free(f)`. The condition register is NOT touched. An
uncontrolled/classically-controlled `cq_phi` is deleted (D2). The angle select lowers as
`x(f); rz_i1(f,B); x(f); rz_i1(f,A)`, run-time arms admitted for Rz, Ry stem unchanged.
Grading: CONFIRMED-MISCOMPILE (wrong unitary, wrong free, or an over-accept of a shape the
oracle declined for a REAL reason) / OVER-DECLINE (a target shape of §6.2 declined) /
DOC-OR-FIXTURE-TRUTH (a comment, count, or fixture that claims something false) / CLEAR.

## Lenses (one per agent; PRD §10.3 items 1–7 plus the integrity lens)
L1 **Kickback polarity.** `¬f` arms in every spelling `-O1` produces: `if (q != k)`,
   `if (!(q == k))`, `xor i1 %c, true`, swapped successors, `select i1 %c, i1 false, i1 true`,
   `if (q == k) {} else cq_phi(θ)`, a compare with the constant on the LEFT, `icmp ne`
   canonicalised to `eq` + swapped `br`, `sgt`/`ult` etc. Prove the emitted `cqrt_x` bracket
   is present exactly when the arm executes on `c == false`. Also: the strip's `_unc` must
   see f in the SAME state it was minted in (the bracket is closed BEFORE the strip).
L2 **Strip after a diagonal gate; operand relabelling between mint and strip.** The `_unc`
   reads the operand registers. Construct every way an operand could be relabelled between
   mint and strip: an in-place `cq_theta` on q inside the arm (must be a MIXED arm → decline;
   is it?), an in-place dtzb `add`/`xor` on q in the arm, a `cq_theta` on q in the MERGE
   block that `-O1` hoists/sinks, a second region whose mint precedes the first's strip
   (sequential regions, bd hcrg ordering), an Ry on q that `-O1` moved ABOVE the compare
   (stale condition — the gate-2c / P4 fences). Also the derived-condition case
   (`if (q*3+1 == 7)`): the derived chain's `_unc` must run AFTER the flag strip and its
   rails must be freed clean; check `free_pairing_check.py` STRICT on every reproducer.
L3 **P7's boundary / Rule 1 "no third path".** A `cq_phi` that is neither claimed nor
   declined must be impossible. Probes: `cq_phi` under a tainted `br` that ControlDetect
   DECLINES for another reason (a Q+Q compare; a multi-block arm; a value op in the same
   arm; a tainted `switch` with a non-empty default; an irreducible loop) — `opt` must exit
   non-zero and the call must not have been deleted first (read the emitted diagnostic and
   inspect whether the deletion pass ran: does the subject's second entry point,
   CQLoweringPass.cpp ~689, ALSO run the deletion?). Probe classical control:
   `if (classical_c) cq_phi(θ)` deleted; `cq_phi` inside a classical loop deleted; `cq_phi`
   in a function called from a tainted arm through the Phase-6 clone (a `cq_phi` in a
   CALLEE whose clone runs under quantum control — is the callee's `cq_phi` a global phase
   or a branch phase? It is a BRANCH phase — the call is under the arm — and the clone
   mechanism must not delete it as uncontrolled; this is the deepest probe of the lens).
   Also `cq_phi` under a tainted branch inside a Bennett-wrapped specialised clone.
L4 **Angle select, both stems.** Run-time arms accept for Rz and decline for Ry (pin both
   directions with reproducers on both binaries); a `double` `ConstantExpr` arm; NaN/inf
   constant arms for Rz (nothing is computed — but the trace prints the angle; is a NaN
   angle a silent nothing?); `select` with a tainted ANGLE operand; two `cq_phi` consumers
   of one select; a select feeding both a `cq_phi` and a `cq_theta`; a select whose
   condition is a compound tree; a select inside a loop; nested selects on the angle
   (`c1 ? A : (c2 ? B : C)`). Check the angle-select S1–S10 fences still apply where they
   should for Rz and that the retired 2^-40 fence is retired ONLY for Rz.
L5 **In-loop per-activation (P6).** The kickback has no gate on `q`. Probe a MIXED loop body:
   kickback region + an Ry arm region on another register in the same body; kickback +
   in-place `q = cq_theta(q, .)` after the region; two kickback regions on two registers;
   kickback whose condition register is loop-INVARIANT (must decline per bd drbq.12 —
   does it, with which string?); a kickback region in the loop EXIT block; a loop with
   the region on the back-edge path only; K=1; the per-bit idiom at K=4 vs hand-unrolled —
   BYTE-IDENTITY of rolled vs unrolled traces on every accepted pair (that is the witness;
   both on the subject; the oracle declines these).
L6 **Migration + surface truth.** With the new header, does every OLD spelling fail loudly at
   compile (`x = cq_phi(x, θ)` → clang error, not a silent int conversion? `cq_phi` is now
   `void(double)`: `x = cq_phi(x, θ)` errors on arity; but `cq_phi(x)` with an INT `x` compiles
   as an implicit int→double conversion and lowers as a global phase — is that a silent
   behaviour change for a user who wrote `cq_phi(q)` by mistake? Report it as a
   DOC/OWNER item). Check the `.ll` legacy-prototype decline fixture. Check `WidthDispatch`
   and `TaintPropagation` no longer accept `@cq_phi_<sfx>` in any entry point. Sample
   ≥30 fixtures the implementer added: re-derive each CHECK from the subject's output and
   confirm handle names exist in the output.
L7 **Free/uncompute interaction.** The flag is freed inside the region. Probe what the
   whole-DAG uncompute spine does when the CONDITION's derived chain is dead after the
   region (it should `_unc` and free the derived rails AFTER the region), when the
   condition register itself is dead after the region (the `cq_theta` root: today "dead
   chain would free a measured register" for measured; for an UNMEASURED dead root the
   spine frees it — is a rail that carried a KICKBACK phase still `|0>`-provable? It is
   NOT: after `if (q==5) cq_phi(π)` the register q carries a relative phase and is
   entangled with nothing but is not |0>; the spine's `_unc` of the theta chain would
   apply Ry† and free — that is a HIDDEN MEASUREMENT unless Ry† restores |0>, which it does
   NOT once a phase sits on the branch: Ry†·P(π)·Ry|0> ≠ |0>). THIS IS THE LENS MOST LIKELY
   TO FIND THE ROUND'S CONFIRMED MISCOMPILE: does the subject FREEZE a register whose branch
   carried a kickback phase (as drbq Inc 1 freezes a controlled-Ry rail —
   `ChainWalk::railCarriesControlledRotation`)? If not, construct `int q = cq_theta(0,.3);
   if (q == 1) cq_phi(PI);` with q then DEAD (no measure) and read the trace: an
   `cqrt_ry_..._unc`/inverse followed by `cqrt_free(q)` is a dirty free. Compare with the
   oracle's behaviour on the routed form (which had the SAME hazard for a phase arm — if the
   oracle also frees it, it is a PRE-EXISTING miscompile: say so, and it is still a finding).
L8 **Fixture integrity.** For EVERY accept fixture the implementer added (list them from
   `git diff --stat main..HEAD -- ir-pass/test`): inject, one at a time, into the subject's
   output (a) a `cqrt_cswap`, (b) a `cqrt_rz_i32_controlled`, (c) a second `cqrt_rz_i1` on the
   flag after its free, (d) a surviving `call void @cq_phi`, (e) a dropped `cqrt_free` of the
   flag; FileCheck the fixture against the injected text; report per fixture which
   injections are CAUGHT. Control EVERY injection with a clean run (must pass) and a
   known-bad run (must fail) — two harnesses lied to their agents in Inc 4 (an injection
   harness appending a matching `declare`; a zsh `set -- $B` loop scoring declines as
   accepts). Also check counts in the progress file against `ls | wc -l`.

## Output (each lens writes `$SP/progress/review_r1_L<n>.md` and returns it as the final message)
Numbered findings `F-L<n>-<k>`: grade, ONE-line claim, reproducer path, the two traces (or
diagnostics) subject vs oracle, the analytic argument, the proposed fix location
(`file:line`), and the fixture that should pin it. End with a verdict line for the lens.

## Round-1 specifics from the implementer's hand-back (read `$SP/progress/impl_inc1a.md` fully)
- Subject commit `fa96336` (6 commits over dfb8e83; 45 files; 21 fixtures: 11 accept / 10 decline).
  Entry points: `ArmClassify::classifyPhaseKickback` (pre-peel in `handleBranchRegion`),
  `SwapRouteEmit::emitPhaseKickbackRegion`, `ControlRegion::PhaseKickback`,
  `ArmAnalysis::phaseAngleTail` (the MERGE-TAIL angle phi: `-O1` sinks the last `cq_phi` of
  each arm into the merge with its angle muxed through `phi double`; emitted with PER-INCOMING
  polarity brackets — L1: this is the richest polarity surface in the increment, probe
  three-way and swapped-incoming spellings, `phi` with a `Pred` incoming, nested phis),
  `deleteGlobalPhases` (P7, both entry points), `WidthDispatch::phaseFn`, `TaintSet::PhaseCalls`.
- ⚠ The implementer reports `opt` EXIT 0 on a module the verifier flagged (`PHI nodes not
  grouped at top of basic block!`) during development. CLAUDE.md claims opt's in-process
  VerifierPass makes the exit non-zero. L3 (and L6): REPRODUCE whether `cq-opt` (and stock
  `opt`) exit non-zero on a verifier failure after `cq-lowering`; if `cq-opt` exits 0, every
  fixture in the tree that relies on "verify-clean ⇒ exit 0" is weaker than documented — a
  harness finding of the first order.
- Known and expected: 3 hand-IR fixtures (`control_swap_switch_*`) still emit a non-i1
  `cqrt_rz` through `NestedRouteEmit.cpp:116` / `SwitchRouteEmit.cpp:113` — part B's rows
  (P4/P5), being implemented in parallel; not a round-1 finding unless reachable from C.
- Known: 155 fixtures reference the retired `@cq_phi_<sfx>` family and are GREEN on the subject
  (4 of them CALL it with a classical arg-0); the migration agent (prep a2) re-derives them —
  L6 should sample them for FALSE GREEN rather than re-do the migration.
- The `ifelse_derived` customer: true arm carries a gate; the genuinely-empty-arm `phi double`
  variant is intercepted by `flattenPredMuxRegions` and declines on S6 — pinned hand-IR only.
- Orchestrator decisions in force (challenge them if you find a hole): N `cq_phi` per arm →
  N `rz_i1` on one flag (exact); the `phi double` merge tail is a P2 spelling.
