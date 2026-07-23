# Addendum — bd 20xt.7: Provable-pow2 clone-read identity mask

**Status:** DONE (shipped, Rule-13-cleared). Branch `3c6m.14-control-l6`. A
follow-on to 20xt.5.2 (this directory's PRD) that closes the Provable-phi-index
over-decline 20xt.5.2 documented as a deferred scope boundary.

## The over-decline 20xt.5.2 left, and why it's in-scope

20xt.5.2's coherent-escape bypass unblocked the **NeedsMask** clone-read-under-
control (atanl's index has the `-1`/`4294967295` sentinel → NeedsMask → the
flatten's `and id, N-1` mask, which the emitter re-proves). But a **Provable**
phi-index clone read (index a phi/select over ALL-in-bounds constants, e.g.
`{0,1,2}`, no OOB sentinel) recorded NO mask, so after `lowerCloneSelect` lowered
the region-internal index to an opaque `cqrt_alloc_i64` handle, `lowerQramReads`'
`qromIndexKnownInBounds` re-proof (the blocker-c OOB fence) could no longer see
the pre-flatten Provable proof → loud `kMsgQramCloneUnbounded` decline. A
safe-but-fragile claim/emit divergence: the E4 claim accepted, the emitter
rejected. It's *within* the clone-QROM-under-control capability (a natural
in-bounds table lookup) and fragile (clang's if-conversion could flip an index
between the NeedsMask and Provable shapes), so per Rule 17 it is closed here.

## The fix — mask ONLY the opaque phi-index case

In `recoverRegion`'s E4-load gate, a Provable read on a pow2 table is ALSO recorded
in `R.MaskLoads` — but ONLY when its index **becomes opaque** after the flatten. The
mask `and idx, N-1` is the IDENTITY on a provable-in-bounds index (Provable ⟹
known-bits max < N = 2^k ⟹ `and idx, N-1` == idx at runtime), so it is semantically
inert; its sole effect is to carry the flatten's bounds proof to the emitter.

The distinguishing signal is a new `classifyQromReadUnderControl` out-param
`OutIndexBecomesOpaque = !taint.count(M->RawIndex)`: a claimed **untainted** index is
region-internal-phi-derived (the taint gate admitted it only via
`indexWillTaintAfterFlatten`) → the flatten + `lowerCloneSelect` lower it to an opaque
handle → NEEDS the mask. A claimed **tainted** index is a straight-line data
computation (e.g. a source `& 3`) → its raw op SURVIVES to the gep → the emitter
re-proves it directly → NO mask.

### Why "mask only opaque" is load-bearing (the Rule-10 lesson)

The FIRST cut of this fix masked ALL Provable-pow2 clone reads. It was
Rule-13-cleared as *sound* (the mask is idempotent) — but it **double-masked** a
source-masked read (`(long)(x*4)&3`, already `and,3` at the gep) with a redundant
second `and,3`, drifting the `e2e-slice-spec-qrom-read-arm-escape` golden. `ctest`
caught it. A shallow fix with a hidden interaction (Rule 10); the opaque-only gate is
the correct scope (Rule 14 — no redundant gate).

## Miscompile-freedom (the crux)

Not-masking a tainted-index Provable read NEVER yields a wrong row / OOB read — it is
doubly backstopped: a pre-existing tainted i64 `select` index is rejected at
`scanBody` (a non-i32/non-fp select) BEFORE the clone builds (verified: opt exit 1, 0
loads emitted); and any index that reaches the emitter opaque is caught by the
un-bypassed `qromIndexKnownInBounds` fence (loud `kMsgQramCloneUnbounded`). So the
refinement only ever produces a correct accept (straight-line raw op re-proven) or a
safe loud decline — never a silent miscompile.

## Scope (safe residuals, unchanged)

- A tainted index that becomes opaque some other way (e.g. a pre-existing tainted
  select over const arms) stays declined — at `scanBody` today. Unchanged from before.
- A non-pow2 Provable clone read stays declined (can't mask non-pow2). Rare, safe.

## Verification

- **Rule 12 red-green:** `spec_accept_qrom_read_arm_provable_index.ll` (a phi-index
  Provable `{0,1}` clone read — RED pre-fix `kMsgQramCloneUnbounded`, GREEN post-fix
  with the identity mask; CHECK-LABEL-scoped negatives, verified to catch an injected
  dirty free). The `e2e-slice-spec-qrom-read-arm-escape` golden is UNCHANGED (the
  source-masked index is NOT double-masked). `spec_reject_qrom_read_arm_nonpow2.ll`
  still declines.
- Files: `PredMuxFlatten.cpp` (the opaque-gated clause + `MathExtras.h`),
  `QramLowering.{h,cpp}` (the `OutIndexBecomesOpaque` out-param). Freeze-orthogonal.
- **Rule 13:** an independent adversarial re-review of the refined dispatch (the
  soundness envelope — identity mask, emitter-backstop — was cleared in the 20xt.5.2
  and broad-20xt.7 reviews; the re-review targets the new opaque-index signal).
- Full ctest green (fresh clean rebuild).
