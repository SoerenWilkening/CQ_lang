; lowering_bitcast_measure_after_rerotate.ll — DECLINE (bd test_C_libtooling-3d8q,
; P1). ⚠ THIS FILE'S VERDICT WAS INVERTED, DELIBERATELY, AND ITS OLD HEADER WAS
; THE SPECIFICATION OF THE BUG. It shipped as an ACCEPT arguing *"a measure reads
; the wire in place (captures nothing onto a fresh rail, so there is no
; stale-record hazard) … Only a downstream DATA op / select / tape reading a
; re-rotated wire declines …, NEVER A MEASURE."* That last clause is exactly the
; incomplete enforcement `docs/frontend.md` §3.2 flags in its own words:
;
;     "The rule is the language semantics; the enforcement is per-site and is not
;      yet complete. … the example above declines, but replacing the arithmetic
;      with a MEASUREMENT of the same stale name —
;      `int q = cq_theta(seed,.3); int mark = q; cq_ry(q,.4); cq_measure(mark);`
;      — is accepted … `declineStaleRecordOps` covers tainted PURE OPS only …
;      Do not rely on the compiler to catch this spelling."
;
; This module IS that example: `%b` is another NAME for `%h`'s wire (a same-width
; int bitcast, folded to `%h` by `foldIdentityBitcasts` before any analysis),
; `%h2 = cq_theta(%h, .3)` moves the wire, and `%b` is then MEASURED. The linear
; rule says a rotation CONSUMES the old name, so the measurement names a record
; the register no longer holds; the emitted stream `ry(.5); ry(.3); measure(h)`
; reports the post-`.3` state under the pre-`.3` name. It is the LANGUAGE rule,
; not a taste: `cq_measure` is a register-carrying family exactly like
; `cq_theta`, and the pure-op twin one token away
; (`lowering_reject_bitcast_downstream_stale.ll`) has always declined.
;
; ⚠ THE BITCAST SUBJECT IS NOT LOST — check before believing the conversion cost
; a pin. `foldIdentityBitcasts`' zero-gate identity fold is pinned by
; `lowering_bitcast_i32_identity.ll`, and the "a re-rotation on the folded wire
; does not spuriously decline a well-formed measure" ACCEPT boundary is pinned by
; `lowering_bitcast_chained_theta_before.ll` — the same two rotations with the
; bitcast naming the CHAIN TIP `%h2` instead of the consumed `%h`, which is the
; well-formed spelling of this very program and still lowers to
; `alloc/ry/ry/measure`. There is still NO bitcast-specific guard: this declines
; at `recordStaleQuantumReaders` on the FOLDED wire, exactly as the direct
; `cq_theta;cq_theta;measure(%h)` spelling does.
;
; RETIREMENT TRIGGER: if the owner ever rules that a measurement reads the WIRE
; rather than a NAME — the reading the old header asserted — this file inverts
; back and `docs/frontend.md` §3.2's linear-rule paragraph must be rewritten in
; the same commit. Do not invert one without the other.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so the CHECK-NOTs below pin
; NOTHING on their own (Rule 12 fixture-hygiene defect (b)); the property is
; carried by the `not` inversion on the RUN line and by the CHECK above. They are
; kept because this file's whole history is a stream that should not exist.
; CHECK-NOT: cqrt_measure_i32
; CHECK-NOT: cq_template_bitcast

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %h  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b  = bitcast i32 %h to i32
  ; Chained in-place Ry re-rotates the wire AFTER the bitcast...
  %h2 = call i32 @cq_theta_si32(i32 %h, double 3.000000e-01)
  ; ...and %b (=== the consumed name %h) is MEASURED — the linear-rule violation.
  %m  = call i32 @cq_measure_si32(i32 %b)
  ret i32 %m
}
