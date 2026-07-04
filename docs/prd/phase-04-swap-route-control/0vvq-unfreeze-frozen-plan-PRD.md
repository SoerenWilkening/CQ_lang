# 0vvq — Unfreeze the frozen-plan lowerings for a round-2 control-merge `%out`

**Status:** Increment 1 (BY-REF half) **DONE + Rule-13 CLEARED** (branch
`dugh-repropagate-control-merge`, 2026-07-04). Increment 2 (the Phase-6 spec-clone
re-plan) scoped in §7, shipped separately with its own clearance.
Owner-directed accept-more follow-on from `dugh` (2026-07-04): *"lower/compile
everything not ruled out by physics — unfreeze."* Core-lowering change; cleared via
multi-agent adversarial review (§6 — one UAF found + fixed, no silent miscompile).

## 1. Problem

`dugh` re-propagates the untainted control-merge `%out` so onward **arith/phase**
lowers. But two lowerings **freeze their per-call plan before** the second
propagation (`repropagateControlMerges`, step 200) and never revisit it, so a
round-2 `%out` argument they never saw is mishandled — `dugh`'s
`declineReseedIntoFrozenPlan` therefore **loudly over-declines** them (safe, but
physics-valid; tracked here):

* **Phase-6 specialization** — `detectSpecializations` (step 127) fixes each
  clone's per-arg quantum/classical **mask** from round-1 taint. A merge-fed arg,
  untainted then, is masked **classical**; the driver `specialize` (step 262)
  clones with that stale mask → reads the `%out` **qubit-handle tag as a literal**
  (D2 silent miscompile). → **Increment 2.**
* **By-ref math (g387)** — `lowerByRefMath` (step ~88) rewrites only *tainted*
  by-ref math (`frexp`/`modf`/`remquo`) to `@cq_byref_*` markers. A merge-fed call
  is untainted in round 1 → left **raw**; after round-2 taints it, an un-lowered
  `frexp(i32 <handle>, ptr)` (D3 broken module) → declined. → **Increment 1.**

Both shapes are **reachable on the -O1/-O2/-O3 floor** (unlike `d3ji`): by-ref
math and specialization operate on **non-inlined** calls (a libc `frexp` extern,
a `noinline`/large specializable callee) that GVN cannot collapse. Confirmed: the
`frexp` slice survives -O1 with the merge phi and `@frexp` call intact.

## 2. Physics (both increments accept-valid)

`%out` is a superposition register (an `i32` handle entangled with `q`).
`frexp(sitofp %out)` reversibly decomposes it into mantissa `m ∈ [0.5,1)` and
exponent `e` with `x = m·2^e`; both are functions of `%out`, so computing them
via the reversible `cq_byref_*` producers yields quantum values entangled with
`%out`. Measuring or `i32`-returning them is a valid onward-quantum flow (the
uncompute spine reverses the markers via their `_inv` twins). A specialized pure
call over `%out` is a clone×merge composition. **Physics-valid — an *architectural*
freeze, not a physics barrier.**

## 3. Increment 1 — the by-ref half: fix shape

After `repropagateControlMerges` re-taints `%out`, **re-run `lowerByRefMath`** on
the now-tainted by-ref calls, then stop declining them. The key enabler: the
tainted-condition diamond is **already flattened** by `lowerControlRegions`
(step 184, before repropagate at 200), so `analyzeCell`'s `underTaintedControl`
check — which declined at round 1 because the merge block was dominated by the
tainted `br` — now **passes** (no tainted `br` remains), and g387 lowers the call
to `@cq_byref_frexp`/`cq_byref_frexpexp` markers exactly as it would a round-1
tainted `frexp`. **Reuse, not reinvention (Rule 14):** the round-2 lowering is
*byte-identical* to the round-1 g387 path; only the trigger point moves.

The machinery is the proven g387/g7ip pattern — `while (lower…) re-propagate` — a
re-run-to-fixpoint after re-propagation, now applied to the dugh round-2 taint.

### 3.1 Implementation (all inside `TaintPropagation.cpp`)

| Site | Change |
|---|---|
| `lowerByRefMath` teardown (`ByRefMath.cpp`) | **Scrub** each erased instruction (the `frexp` `CI`, its loads) from `taint.Tainted`/`HandleWidth` before freeing. Required because the round-2 re-propagation seeds its work-list from the live taint set — a freed `Instruction*` there is a use-after-free. Harmless at the step-2 fixpoint (the full re-`propagate` there rebuilds `Tainted` from scratch). |
| `repropagateControlMerges` | After the initial `propagateWorklist` from the rails, add the by-ref fixpoint: `while (lowerByRefMath(M, wd, taint, declined2)) { re-propagate: propagateWorklist(seed = all current `Tainted`, skipRuntimeCalls=true); }`. A `cq_byref_*` marker is a plain user of the tainted fp arg (not a `cqrt_`/`cq_template_`/measure/angle edge), so `propagateWorklist` taints it and its downstream. Compute the round-2 **reseed set AFTER** the fixpoint (so the markers' downstream is included). |
| `declineReseedIntoFrozenPlan` | Make it **spec-only** — drop the `|| isByRefMathCall(CI)` clause (by-ref is now re-run above, no longer frozen). Keep the `shouldSpecialize` clause (Increment 2). Update the comment. |

Twin-pipeline parity is automatic — the change lives inside
`repropagateControlMerges`, already wired in both entry points.

### 3.2 Seed-from-all-taint / scrub interaction (the one subtlety)

`propagateWorklist` only re-pushes a value whose users produced a *new* taint;
seeding from the rails alone would **not** reach a freshly-emitted marker (its fp
arg `%d` is already tainted → not re-pushed → its new marker user is never
visited). Seeding from the **entire current `Tainted` set** re-visits `%d`'s users,
taints the marker, and propagates onward. That seed set must contain **no freed
pointers** — hence the `lowerByRefMath` scrub (§3.1).

## 4. Scope boundary — what still declines (Increment 1)

Every existing g387 decline is **preserved** (they run in the re-run's
`analyzeCell`/`validSignature`), so the re-run only *accepts* what g387 proves and
loud-declines the rest:

* by-ref under **nested** tainted control (a downstream new tainted `br` not
  flattened) → `under quantum control`;
* by-ref in a **loop** → `by-ref call in a loop`;
* **escaping / aliased** out-cell, **post-call** cell store → the cell reasons;
* **tainted out-pointer** (a quantum address) → `tainted by-ref out-pointer`;
* unsupported **signature / fp width** → `unsupported by-ref math signature`;
* the mantissa **fp result reaching a rotation angle** → `declineTaintedAngle`
  (downstream, unchanged — the angle fence is producer-agnostic).

The Phase-6 **spec-clone** frozen-plan stays declined (Increment 2).

## 5. Fixtures (red-green, Rule 12)

**Flip to ACCEPT** (the committed dugh reject, now lowered):
`control_classical_call_arm_reject_onward_byref_math.ll` →
`control_classical_call_arm_accept_onward_byref_math.ll` — check the merge `%out`,
`sitofp` cast, `cq_template_frexp…`/`cq_template_frexpexp…` markers, and the
measure/`i32`-ret; `CHECK-NOT: @frexp`, `CHECK-NOT: under quantum control`.

**New ACCEPT** — mantissa AND exponent both measured (from probe
`P1_byref_frexp_on_out`): `cq_measure_f64(mantissa)` + `cqrt_measure_i32(exponent)`.

**Retained DECLINE probes** (Increment-1 partition, adversarial):
by-ref-in-loop, by-ref under a downstream *new* tainted `br` on `%out`, escaping
out-cell, tainted out-pointer, mantissa→angle. Each mirrors its g387 diagnostic
character-for-character.

**e2e golden smoke:** a `.c` slice — classical-call arm builds `%out`, `frexp` on
the merged value, measure the exponent (and use the mantissa) — through the full
clang -O1 → opt → link → run pipeline (the only layer that LINKs the `cq_byref_*`
markers against the templates).

## 6. Rule-13 adversarial clearance (Increment 1) — CLEARED

Independent multi-agent adversarial review (5-lens finder workflow + 3-verifier
pass, then a 2-agent re-clearance on the fixed build). **One defect found + fixed;
no silent miscompile.**

**DEFECT (found, fixed, regression-pinned) — round-2 USE-AFTER-FREE (3-lens
convergence: memsafety + overaccept + undercontrol all found it independently).**
`lowerByRefMath`'s teardown scrubbed the erased Loads and the CI from
`taint.Tainted`/`HandleWidth` but **not the dead pre-call Stores**. A dead pre-call
whole-cell store `store %out, %cell` (clang's `int e = y; frexp((double)y,&e);`)
has a `%out`-derived VALUE, so after the second propagation the *store instruction*
is in `taint.Tainted` (a plain user of the tainted rail). `analyzeCell` accepts it
(dead pre-call store) and the teardown erases it un-scrubbed → the freed `StoreInst*`
dangles in `taint.Tainted`, and the 0vvq fixpoint re-seed
(`WL(taint.Tainted…); propagateWorklist`) dereferences it via `V->users()`. Silent
under the default allocator (verify-clean, exit 0); SIGSEGV ~7/8 under guard malloc.
**Latent, delta-exposed:** round-1's `while(lowerByRefMath) taint = propagate(…)`
rebuilds `Tainted` from scratch so the stale pointer is dropped; the 0vvq re-seed
from the LIVE incrementally-mutated set is what makes it live — and the delta *added*
the Loads/CI scrubs but *omitted* the symmetric Store scrub. **FIX:** scrub Stores
symmetrically (`ByRefMath.cpp`). Guard-malloc A/B (5 probes across frexp/modf/remquo +
chained): reverted → 5/5 SIGSEGV, fixed → 0 crashes. Pinned:
`control_classical_call_arm_accept_onward_byref_prestore.ll`.

**Re-clearance verdict (fixed build):**
* **UAF class fully closed** — the g387 fixpoint re-seed is the *only* site that
  dereferences a `taint.Tainted` member; all three potentially-tainted erased kinds
  (Loads/Stores/CI) are scrubbed, and Lifetimes + the Cell alloca are provably never
  tainted (proven by guard-malloc across the whole erased surface).
* **No silent miscompile / broken module / over-accept** — a 16-probe matrix (frexp/
  modf/remquo × QQ/`_hl`/`_lh`, chained, 4.5 switch-data-mux `%out`, spec-clone→decline,
  mantissa→angle→decline, escape→decline) all lower verify-clean or decline loudly.
  The by-ref DAG bottoms out at a `ControlOwnedRail` (`%out`) → `DagTraversal` marks it
  `NotClosed` → the safe-leak path (markers left allocated, never `_inv`/freed) —
  strictly *more* conservative than round-1 (Rule 6/8). The dead-mantissa marker is an
  inherited g387 property, unchanged by 0vvq.
* **No spec regression** — `declineReseedIntoFrozenPlan` (now spec-only) still declines
  a marker result feeding a Phase-6 clone (reseed computed after the g387 loop);
  spec-only is safe because `reseed ⊆ taint.Tainted` ⇒ any reseed-reading by-ref call
  has `ReadsTainted` ⇒ is always lowered-or-declined, never skipped un-lowered.

## 7. Increment 2 — the spec-clone re-plan (scoped, shipped separately)

After repropagate, re-plan a `shouldSpecialize` candidate whose C-masked arg is
now round-2 tainted: recompute the mask with `%out` as **quantum** (a Q+C/Q+Q
clone body), re-clone, retarget the call, drop the now-dead C-mask clone; iterate
transitively; in-clone tainted control/memory the clone cannot emit stays declined
(tracked). Touches `SpecializeDetect`/`SpecializeClone`/`Specialization` — the D2
core. Its own PRD increment + independent Rule-13 clearance.

## 8. Done criteria (Increment 1)

Fixtures (flip + new accept + retained declines) + ≥1 e2e golden smoke; full
ctest green; `gen_templates.py --check` clean (no new ABI — the `cq_byref_*` /
`cq_template_frexp…` surface already exists from g387); independent Rule-13
adversarial clearance.
