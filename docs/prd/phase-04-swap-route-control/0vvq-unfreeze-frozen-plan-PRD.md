# 0vvq — Unfreeze the frozen-plan lowerings for a round-2 control-merge `%out`

**Status:** Increment 1 (BY-REF half) **DONE + Rule-13 CLEARED** (branch
`dugh-repropagate-control-merge`, 2026-07-04). Increment 2 (the Phase-6 spec-clone
re-plan, the D2 core) implemented 2026-07-05 — **full spec in §9** (§7 is the
earlier forward-scope stub, superseded by §9's corrected ordering analysis).
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

---

## 9. Increment 2 — the spec-clone re-plan (the D2 core)

**Status:** implemented on branch `dugh-repropagate-control-merge` (2026-07-05).
Owner-directed accept-more follow-on; core-lowering change, cleared via independent
multi-agent adversarial review (§9.6).

### 9.1 The frozen plan is the `Pending` mask — NOT a built clone

The D2 silent miscompile (`control_classical_call_arm_reject_onward_spec_call.ll`,
dugh's own regression pin): a 6.5 classical-call arm's untainted merge `%out` is
passed to a Phase-6 specialization candidate `z = ipow(q, %out)` whose per-arg
mask was **frozen classical** for that argument at `detectSpecializations`
(step 127, when the merge was data-untainted). dugh re-taints `%out` in round 2 but
the driver `specialize` (step 262) would clone `ipow` with the stale mask `0b01`,
lowering `base + exp` as `cq_template_add_i32_hl(base, exp)` with `exp` = the `%out`
**qubit-handle tag** read as a classical literal — a verify-clean wrong unitary.
dugh over-declined it (`declineReseedIntoFrozenPlan`, spec-only after Inc 1).

**The unfreezing is far simpler than the by-ref half.** The "frozen plan" is not a
built artifact — it is the `SpecCandidate{Site, Callee, Mask}` in `plan6.Pending`,
whose `Mask` was fixed at detection. But the DRIVER that actually clones runs at
**step 262, downstream of `repropagateControlMerges` (step 200)**. So at re-plan
time **no clone exists yet**: unfreezing is simply **updating the Pending
candidate's `Mask`** before the driver consumes it. There is no premature clone to
drop and no retarget to redo — the driver clones the corrected Q+Q body, and its
existing depth-first transitive machinery (6.3) specializes any inner call whose
argument the wider mask newly taints. (The bead's "re-clone / drop the dead C-mask
clone / retarget" framing was written pre-analysis; the real ordering makes those
steps no-ops.)

`Site` is a stable pointer here: `lowerControlRegions` (step 184) flattens the
diamond by `RegionFlatten::flattenRegion`, which **`splice`s** the merge tail into
the pred — it MOVES the `ipow` call, never erases/recreates it — so the Pending
`Site` is live at step 200 (the same invariant dugh's `shouldSpecialize` walk
already relies on).

### 9.2 Soundness of the wider mask (why Q+Q is correct where Q+C was)

The re-plan grows the mask `0b01 → 0b11` (`%out` C→Q). Two facts make this provably
sound for **exactly** the shape `scanBody` accepts:

1. **`scanBody` is mask-INDEPENDENT.** The single authoritative body verdict inside
   `classifyCandidate` (`SpecializeReject.cpp`) scans the callee's — and, transitively,
   every reachable visible callee's — body for shape (straight-line, single-BB, `ret`
   only), for non-reversibilizable constructs (memory / control / EH / recursion /
   atomics), and for op scope (`unsupportedWidth` / `compareInScope` / `castInScope`).
   None of these read the taint mask. So a body proven Accept at round-1 detection is
   Accept at round-2 with **any** mask — the whole transitive body was already
   validated as all-in-scope data ops.
2. **The binary / unary / cast data ops carry a complete `QQ` + `unc_qq` grid**
   (`tools/opcode_table.yaml`): the 18 binary ops and `fneg` have `fwd_qq`/`unc_qq`
   twins, and every cast is arity-1 (its width is on the op type, never laundered).
   So a binary operand flipped C→Q switches one `cq_template_<op>_<W>_hl` producer
   to its bare-QQ twin `cq_template_<op>_<W>` — **both** with an `_unc` twin the
   Bennett wrap's `emitInverseChain` reverses. A binary op recovers its width from
   its own result type, and a cast from its op types, so **neither loses width when
   an operand becomes a laundered handle**.

There are **two** mask-dependent gates, and BOTH are decline-only (never a silent
miscompile):

* `classifyCandidate` **step (A)**: every *tainted* argument must arrive as an
  **i32 handle** (Rule 15). Round-1-tainted args were already proven i32; the only
  NEW tainted args are reseed args, so step (A) can only newly fail on a **non-i32
  reseed arg** → loud `kMsgFpAbi`.
* **The Q+Q compare limitation (a genuine data-path decline, not a QQ-grid gap).**
  A `CmpInst` whose *both* operands become tainted is a **Q+Q compare**, and the
  Phase-3 data path deliberately **loud-declines** it (`CompareLowering.cpp:101-112`,
  `no template for opcode 'icmp/fcmp …' in tainted context`): a compare's logical
  width is unrecoverable from two i32-laundered handles (the result is an i1, unlike
  a binary op whose result type carries the width), and minting `cq_template_icmp_*`
  on the laundered i32 would be a wrong symbol — so it conservatively declines. This
  is the pre-existing `lowering_icmp_qq_no_width_reject` limitation. `scanBody`
  accepts a compare **mask-independently** (it only proves `compareInScope`), so
  re-planning a candidate whose compare flips C→Q to Q+Q **loud-declines** — SAFELY:
  `opt` exits non-zero, the module is discarded, **no wrong unitary**. This decline
  is **byte-identical** to a *round-1* mask-`0b11` compare candidate
  (`__cq_q_<f>_11: no template for opcode 'icmp i1' …`) — the re-plan reaches the
  SAME pre-existing boundary, not a new one. It surfaces **late** (at `lowerOps`,
  naming the clone, not source-located) — a shared, pre-existing WI-1.13-class
  deferred boundary (round-1 mask-`0b11` compare candidates already do this).
  Moving it earlier (a mask-AWARE source-located pre-check in `scanBody`, shared
  with detection) is **tracked follow-on `test_C_libtooling-6o60`**, not correctness
  debt (the decline is already loud and safe; Prime Directive).

### 9.3 Fix shape — `replanReseedSpecialization` (replaces `declineReseedIntoFrozenPlan`)

Inside `repropagateControlMerges`, after the by-ref fixpoint + reseed computation,
**before** the re-run escape net, replace the spec decline with a re-plan
(`TaintPropagation.cpp`, anonymous namespace). For each `plan6.Pending` candidate
whose `Site` reads a reseed value (`%out` or a `%out`-derivation) as an argument:

* `newMask = taintArgMask(Site, taint)` (round-2 taint; monotonically ⊇ the frozen
  `Cand.Mask` since propagation only ever ADDS taint — a reseed arg's bit grows).
* Re-run `classifyCandidate(SpecCandidate{Site, Callee, newMask}, taint, wd, …)`:
  * **Accept** → `Cand.Mask = newMask` (**re-plan**). The step-262 driver clones the
    Q+Q body and transitively specializes inner calls via the unchanged 6.3 path.
  * **Reject** (only ever `kMsgFpAbi` on a non-i32 reseed arg) → `diagnoseReject`
    (loud, source-located), insert `Site` into `plan6.Diagnosed` (so the re-run
    `declineTaintEscapes` carve renders no duplicate `kMsgUnknownCallee`), and
    **remove it from `Pending`** (so the driver never clones a stale-mask body —
    `opt` exits non-zero regardless, but the drop keeps the transient IR clean).

`plan6` becomes a **mutable** reference through `repropagateControlMerges` (both
twin-pipeline call sites already pass the non-const local `plan6`).
`declineReseedIntoFrozenPlan` is **deleted** — its sole remaining owner (spec) is
now re-planned, and by-ref was already dropped in Inc 1.

### 9.4 Scope boundary — what still declines (Increment 2)

* **A non-i32 reseed argument** (`f(q, (short)%out)`, `f(q, sitofp %out)`) → the
  re-plan's `classifyCandidate` step (A) → loud `kMsgFpAbi`. The clone's tainted
  arg ABI is i32-only (Rule 15) — a narrowed / fp-cast reseed value has no i32
  handle representation.
* **A body compare whose operand flips C→Q to a Q+Q compare** (`cmpf(q, %out)`
  with `icmp %a, %b` on both params) → loud `no template for opcode 'icmp/fcmp …'
  in tainted context` at `lowerOps` (the pre-existing data-path Q+Q-compare
  width-decline, §9.2). SAFE (opt exits non-zero, no wrong unitary) and
  byte-identical to a round-1 mask-`0b11` compare candidate.
* **A round-2-only NEW candidate** — a visible pure callee `g(%out)` whose args
  were *all* classical at round 1 (so it never entered `Pending`) — is a round-2
  spec **DETECTION**, a genuinely distinct capability from this **re-plan**. It
  stays loud-declined by the re-run `declineTaintEscapes` (`kMsgUnknownCallee`, a
  visible-body callee reading tainted, not carved). **Tracked** as follow-on
  `test_C_libtooling-9paa` (round-2 spec detection); NOT correctness debt (a safe
  over-decline of a shape outside this increment's target, Prime Directive + Rule 17).
* **An in-clone construct the clone cannot emit** (in-body control / memory /
  recursion / a non-i32 return / an out-of-scope op) was already declined at
  DETECTION by the mask-independent `scanBody`, so such a callee never entered
  `Pending` and cannot be re-planned. The transitive inner-call declines (6.3) are
  likewise preserved by the driver's own `classifyCandidate` on each inner site.

### 9.5 Fixtures (red-green, Rule 12)

**Flip to ACCEPT** — `control_classical_call_arm_reject_onward_spec_call.ll` →
`control_classical_call_arm_accept_onward_spec_call.ll`: the dugh regression pin
(same `@ipow(i32 %base, i32 %exp)` body as `spec_accept_two_arg_mask.ll`) now lifts
to the QQ clone `@__cq_q_ipow_11` — `cq_template_mul_i32` + `cq_template_add_i32`
(bare QQ, NOT `_hl`) + `_unc` reverse; `CHECK-NOT: under quantum control`;
`CHECK-NOT: cq_template_add_i32_hl`.

**New ACCEPT (transitive)** — `spec` … a re-planned top whose Q+Q body calls an
inner classical helper whose arg is now tainted → the 6.3 inner clone + `_unc`
twin, minted from the round-2 re-plan.

**New DECLINE** — `control_classical_call_arm_reject_onward_spec_i16arg.ll`: a
candidate reading a non-i32 `%out`-derivation (`(i16)%out`) → `kMsgFpAbi` (mirrored
char-for-char). `control_classical_call_arm_reject_onward_spec_newcand.ll`: the
round-2-only new-candidate case (`g(%out)`, all-classical round 1) declines via the
escape net (`kMsgUnknownCallee`) — the tracked-follow-on boundary (round-2 spec
DETECTION). `control_classical_call_arm_reject_onward_spec_qqcmp.ll`: a re-planned
compare that flips to Q+Q loud-declines (`no template for opcode 'icmp i1' …`) — the
pre-existing width limitation (§9.2), safe.

**e2e golden smoke** — a 2-file `run_slice_multi.sh` slice: a classical-call arm
builds `%out`, a separate-TU pure `combine(q, %out)` re-plans to `@__cq_q_combine_11`,
the result measured — through the full clang -O1 → llvm-link → opt → link → run
pipeline (the only layer that LINKs the QQ clone + its `_unc` twin against the
templates).

### 9.6 Rule-13 adversarial clearance (Increment 2) — CLEAR

Independent multi-agent adversarial review (6 finders across distinct lenses, each
building + RUNNING probe .ll files, then per-finding refute-by-default verifiers +
a synthesis judge). **Verdict: CLEAR — 0 confirmed silent-miscompile / crash /
broken-module on valid input.** The positive miscompile hunt came back clean: the
cast-body C→Q flip round-trips (matching `*_unc` twins, verify-clean), the
transitive inner re-plan mints `@__cq_q_inner_1` + its `_unc` twin correctly, and
the non-i32 reseed arg declines via `kMsgFpAbi`. `Site` liveness, the reject-path
`Pending`/`Diagnosed` bookkeeping, and the two-mask multiplicity all held.

**One finding (surfaced + addressed): the Q+Q-compare boundary.** The review found
that a re-planned clone whose compare flips to Q+Q **loud-declines** at `lowerOps`
(`no template for opcode 'icmp i1' …`), which **contradicted an over-stated §9.2
claim** ("every op has a QQ grid"). Investigated + corrected: this is the
pre-existing data-path Q+Q-compare width limitation (§9.2), it is **SAFE** (opt
exits non-zero, no wrong unitary), and it is **byte-identical** to a round-1
mask-`0b11` compare candidate (verified by hand: both emit
`__cq_q_<f>_11: no template for opcode 'icmp i1' …`, exit 1, empty output). §9.2/§9.4
now state it accurately, `control_classical_call_arm_reject_onward_spec_qqcmp.ll`
pins it, and the source-located-early-decline improvement is tracked
(`test_C_libtooling-6o60`). No blocker.

### 9.7 Done criteria (Increment 2)

Flip + transitive-accept + non-i32-decline fixtures + the new-candidate boundary
probe + ≥1 e2e golden; full ctest green; `gen_templates.py --check` clean (no new
ABI — the QQ + `unc_qq` grid already exists); independent Rule-13 clearance.
