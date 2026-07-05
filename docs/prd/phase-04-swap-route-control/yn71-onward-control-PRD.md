# yn71 — Onward tainted CONTROL on the control-merge `%out` (Phase 4×6, the CONTROL case)

**Status:** in progress (branch `dugh-repropagate-control-merge`)
**Owner-directed accept-more-physics follow-on from `dugh` (2026-07-04).**
Requires its own Rule-13 clearance (core-lowering: re-detecting + emitting
tainted control flow — the deepest silent-miscompile class in this project).

## 1. Problem

`dugh` (Phase 4×6) added a **second propagation round**
(`repropagateControlMerges`) that re-taints the untainted control-merge `%out`
built by the two untainted-merge emitters (6.5 classical-call arm, 4.5 switch
data-mux). It **accepts** the onward-QUANTUM DATA subset: onward arith
(`add`/`mul`/`icmp`/`cast`), onward straight-line phase (`cq_phi`), onward
by-ref math (0vvq Inc 1), onward spec-clone (0vvq Inc 2), and onward
QRAM/Shadow/IO — terminating at a measure or i32 `ret`.

It **declines** — via `declineReClassifiedControl` — when `%out` (or a
`%out`-derivation) becomes a **NEW TAINTED CONTROL condition**:

```c
int y = 5;  if (q > 3) y = f(a);       // R1: classical-call arm → %out (entangled)
if (y > 7)  y = cq_phi(y, 0.25);       // R2: onward CONTROLLED phase on %out  ← DECLINED today
double m = cq_measure(y);
```

Here `y > 7` (a comparison of `%out`) is a genuinely quantum-controlled branch —
**quantum data used as further quantum control**, the roadmap "quantum data under
quantum control flows onward" (Phase 4×6) for the **CONTROL case** (`dugh`
covered the DATA onward flows). It is **physics-valid** and there is nothing
special about `%out` versus a fresh `cq_theta` handle: after the second
propagation `%out` is a tainted quantum handle, so `if (%out > k) …` is exactly
the tainted-condition diamond `detectControlRegions` already lowers.

The `br`/`switch`/`select` was **classical-conditioned at round-1 detection** (the
merge was data-untainted then), so `detectControlRegions` (step 183) skipped it;
only the second propagation makes its condition tainted. `declineReClassifiedControl`
was `dugh`'s safe **interim over-decline** of this shape (Prime Directive), filed
as this bead for the real lowering.

**Out of scope (stays classical, must NOT be re-handled):** a **CLASSICAL**-condition
downstream `if (cc) y = cq_phi(y, θ)` already accepts via the 5j5 one-register lift
in `declineClassicalMuxes` (step 243). `detectControlRegions` keys strictly on
`taint.Tainted.count(condition)`, so a classical condition is never picked up here
— no double-lower.

## 2. Root cause & fix shape

`dugh` re-tainted `%out`'s onward derivations but then **declined** the tainted
control on it instead of **re-adjudicating** it. The control detect/emit
machinery (`detectControlRegions` → `lowerControlRegions`) is **pure analysis by
SSA identity followed by a self-contained emit** and is safe to **re-run** on the
post-round-1 IR: round-1's accepted regions are already flattened (their tainted
`br`/`switch` erased) or RAUW'd+erased (the emitted `select`), and round-1's
declines already exited `opt` — so the **only** tainted-condition construct
visible at re-detect time is a genuinely new downstream one on `%out`.

**Fix:** replace `declineReClassifiedControl(M, taint)` inside
`repropagateControlMerges` with a **re-detect + emit FIXPOINT** (mirroring the
g387 by-ref / 0vvq spec fixpoints already in the same function):

```
while (true) {
  ControlPlan plan2 = detectControlRegions(M, taint);   // pure analysis; declines unprovable shapes loudly
  if (plan2.Regions.empty()) break;                     // fixpoint reached
  lowerControlRegions(M, wd, taint, plan2);             // emit + flatten the accepted regions
  re-propagate from the whole live taint set (skipRuntimeCalls=true);  // taint any NEW rail's derivations
}
```

`detectControlRegions` itself is the decline authority: a tainted control it
cannot prove fires the precise per-shape `DiagnosticInfoUnsupported` (`opt` exits
non-zero) — so the "accept the known phase/value/select/switch shapes, decline
the rest loudly" contract is preserved **with zero new decline logic** (Rule 14
reuse). `declineReClassifiedControl` is **deleted**.

### Why a FIXPOINT (not a single pass)

Two of the accepted region kinds are themselves **untainted-merge emitters** that
build a *new* `%out2` rail: the 6.5 classical-call arm and the 4.5 switch
data-mux. A downstream `if (%out > k) y = g()` (classical call) produces `%out2`,
which may in turn feed **another** tainted control `if (%out2 > j) …`. Re-seeding
`propagateWorklist` from the whole live `taint.Tainted` after each
`lowerControlRegions` taints the new rail's derivations, and the next
`detectControlRegions` iteration adjudicates the cascaded region.

**Termination:** every `lowerControlRegions` call with a non-empty plan emits ≥1
region, and each emit **removes** exactly one tainted-condition construct (a
`br`/`switch` erased by `RegionFlatten`, a `select` RAUW'd+erased by
`emitSelectRegion`) while creating **none**. The module has finitely many
control constructs and the count strictly decreases per iteration, so the loop
converges. A single-level onward control runs two iterations (emit, then confirm
empty).

### Why the cascade is naturally sequenced (and same-source siblings decline)

At the moment `detectControlRegions` adjudicates an upstream region, the
downstream region's condition is **still classical** (its rail does not exist until
the upstream emits + the *next* re-propagation runs). So `recoverRegion`'s
`hasTaintedCondBranch(merge)` "sequential/nested" guard does **not** fire on the
cascaded case, and it lowers across fixpoint iterations. By contrast two
**same-source** siblings `if (%out > k1) …; if (%out > k2) …` are BOTH tainted in
the same iteration — the first's merge hosts the second's tainted `br`, so
`recoverRegion` returns `Nested`/sequential and **declines** (the block-lifetime
`SIGSEGV`-family guard, unchanged). That over-decline is safe and filed as a
follow-on; the target shape is single onward control (optionally rail-cascaded).

## 3. The re-flatten block-lifetime hazard (the deepest risk — Rule 13)

The CFG is **already flattened** by round-1 `lowerControlRegions` (step 184)
before this second round runs. When the downstream tainted diamond's **pred is the
round-1 spliced merge tail** (`int y=5; if(q>3) y=f(a); if(y>7) y=cq_phi(y,θ)`,
where the round-1 merge block ends in the downstream `br i1 %c2`), round-1's
`flattenRegion` splices that terminator into `Pred` and **must** re-point the
downstream merge phi's incoming block `Merge → Pred` before erasing `Merge` —
otherwise a PHI incoming *block* (not an operand-use) dangles as `<badref>`
(`SIGSEGV` on valid input). This is exactly the **D1 fix** `dugh` already landed
in all three `RegionFlatten` functions
(`Pred->replaceSuccessorsPhiUsesWith(Merge, Pred)`) — it fires for the CLASSICAL
downstream `if(cc)` (5j5, `accept_onward_phase_downstream_if.ll`), and it is
equally load-bearing for the yn71 TAINTED `if(%c2)`. After round-1 flatten the
downstream diamond is a clean standalone diamond whose pred is the flattened
block, and round-2 `flattenRegion` handles it with the same discipline (its own
D1 fix re-points any THIRD region's merge phi).

Detection is **pure SSA-identity analysis before any mutation** (Rule 9); no block
pointers are cached across erasures (each `detectControlRegions` call builds a
fresh `ControlPlan` + `Claimed` set). This hazard is stress-tested under
guard-malloc in the Rule-13 sweep.

## 4. Scope — ACCEPT / DECLINE

**ACCEPT** (whatever `detectControlRegions` proves on the newly-tainted condition):
* onward **phase**-arm diamond / if-else (`if(%out>k) %out=cq_phi(%out,θ)`) → SwapRouteEmit routed phase stream;
* onward **value**-arm diamond / if-else (method-B) — the routed base is `%out`;
* onward **select** (`%out>k ? a : b`) → SelectMergeEmit controlled-XOR copy merge (new `%out2`);
* onward **switch** (`switch(%out)`) → the four 4.5 accept shapes (phase route / value / data-mux / eq-fold);
* rail-**cascaded** onward control (a downstream classical-call-arm / switch-data-mux / select `%out2` feeding a further onward control) — via the fixpoint.

**DECLINE loudly** (the machinery's own precise messages; over-decline is safe):
* every off-pattern shape `detectControlRegions` already declines (mixed arm,
  §3c clobber, tainted angle, non-reconverging, nested-non-provable, in-loop
  `br`/`switch` `d8jl`, unsupported width/fp/i128, impure/unowned switch, …);
* two SAME-source sibling controls on `%out` (`recoverRegion` sequential decline);
* onward **spec DETECTION** off a *round-2-control-produced* rail `%out2` (a
  DIFFERENT capability; declines via the re-run `declineTaintEscapes`
  `kMsgUnknownCallee` — 0vvq/9paa boundary, unchanged), and the pre-existing onward
  **tainted-angle** decline (`declineTaintedAngle`). (Onward **by-ref math** off a
  round-2 rail is LOWERED by the §5a in-fixpoint `lowerByRefMath` re-run — or
  loud-declines an off-pattern cell — rather than a broken module.)

## 5. Ordering (inside `repropagateControlMerges`)

```
1. propagateWorklist from UntaintedMergeRails      (dugh)
2. lowerByRefMath fixpoint + re-propagate          (0vvq Inc 1)
3. compute the round-2 reseed set
4. replanReseedSpecialization(reseed)               (0vvq Inc 2)
5. [yn71] detect+emit onward control FIXPOINT       ← replaces declineReClassifiedControl
6. declineTaintEscapes  (re-run)
7. declineStaleRecordOps (re-run)
```

The control fixpoint runs where `declineReClassifiedControl` did (after by-ref /
spec re-plan): round-1 rails feeding onward by-ref/spec are handled by steps 2/4.
Steps 6/7 then adjudicate every remaining escape / stale op on the fully-emitted,
fully-re-tainted module (they already ran over round-1-emitted `cqrt_*` streams in
`dugh`, so the emitted control stream is a tolerated, carved-out consumer — no new
decline surface).

### 5a. By-ref re-run inside the fixpoint (Rule-13 robustness fix)

The step-5 fixpoint ALSO re-runs `lowerByRefMath` each iteration (after the control
emit, so the diamond is flattened and the cell is straight-line — the 0vvq Inc 1
enabler). **Why:** a round-2 onward classical-call-arm / switch-data-mux / select
builds a NEW rail `%out2` AFTER the step-2 `lowerByRefMath` fixpoint already ran; a
`frexp`/`modf`/`remquo` fed by `%out2` would otherwise survive RAW, and
`declineTaintEscapes`'s by-ref carve (`isByRefMathCall → continue`, assuming
`lowerByRefMath` owned it) would wave it through into `lowerOps`, which lowers its
`sitofp` arg to an i32 handle — leaving `frexp(i32, ptr)` against `frexp(double,
ptr)`, a type-mismatched **BROKEN MODULE** (the yn71 Rule-13 finding — the sole
non-refuted finding of the adversarial sweep). The re-run lowers a round-2-rail
by-ref to `@cq_byref_*`/`cq_template_frexp` markers byte-identical to a round-1-rail
by-ref, or loud-declines an off-pattern cell — never a raw survivor. A control emit
may expose a new by-ref and a by-ref marker may expose a new onward control, so both
run each iteration until neither changes (termination: each removes one finite
construct). The broken-module shape is NOT clang-`-O1`-emittable (a constant-
straight-through arm merge that also keeps `%out` live as an un-threaded onward
comparison is mutually exclusive under clang's threading), so it is a robustness pin
(Rule 10), not a live miscompile. The SPEC case (a round-2 rail feeding a Phase-6
candidate) already declines cleanly via `kMsgUnknownCallee` (bead 9paa), no broken
module — so only by-ref needs the re-run. Pinned by
`control_classical_call_arm_onward_ctl_rail_byref.ll`.

## 6. Tests (Rule 12 red-green + Rule 16 e2e)

Lit fixtures (ir-pass/test), each positive `CHECK` + a mirrored negative:
* `control_classical_call_arm_accept_onward_ctl_phase.ll` — onward phase arm on `%out` under a tainted `if` → routed `cqrt_cswap`/`cqrt_rz` stream (dugh `reject_onward_branch` intent, flipped);
* `control_swap_switch_datamux_onward_ctl_phase.ll` — switch-data-mux `%out` → onward tainted `if` phase arm;
* `control_classical_call_arm_accept_onward_ctl_select.ll` — `%out>k ? a : b` select → controlled-XOR merge;
* `control_classical_call_arm_reject_onward_ctl_clobber.ll` — an onward tainted control the machinery declines (§3c clobber / mixed) still declines loudly (decline authority preserved);
* `control_classical_call_arm_onward_ctl_rail_byref.ll` — the §5a Rule-13 robustness pin: an onward-ccarm rail `%out2` feeding `frexp` lowers to markers, not a broken module.

The old `control_classical_call_arm_reject_onward_branch.ll` is repurposed/replaced
(its intent — onward tainted control declines — is superseded; the remaining
DECLINE fixtures pin the shapes that still decline).

e2e golden (tests/e2e): `slice_control_cond_onward_ctl_phase` — a self-contained
`switch(q){…}; if(r>k) r=cq_phi(r,θ); measure(r)` driven through the full
clang -O1 → opt → link → run pipeline (the only layer that LINKS — proves the
onward controlled `cqrt_cswap`/`cqrt_rz` stream resolves + signature-matches).

## 7. Non-negotiable gates

* Full `ctest` green + `gen_templates.py --check` clean (this adds **no** new ABI
  — it reuses `detectControlRegions`/`lowerControlRegions` verbatim, Rule 14).
* **Rule 13** independent adversarial clearance BEFORE commit — a finder+verifier
  workflow that BUILDS and RUNS adversarial `.ll` probes (incl. guard-malloc for
  the re-flatten UAF), targeting: a phi dropped on the wrong edge, a gate fired on
  the wrong branch, a dirty free, a re-flatten `<badref>`, a shape that should
  decline but accepts (the one unforgivable bug). A green `ctest` is **not**
  sufficient (Rule 2/13).
