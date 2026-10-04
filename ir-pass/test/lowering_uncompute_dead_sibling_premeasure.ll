; lowering_uncompute_dead_sibling_premeasure.ll — DECLINE: a DEAD tainted
; template terminal whose register lineage is LATER measured through an
; upstream handle (test_C_libtooling-3h8; straight-line, NO control region).
;
; `%q = @cq_theta_si32(...)`; `%dead = q + 7` (never read); `measure(q)`. The
; whole-chain adjoint of the dead `%dead` chain re-emits `add_hl_inv` and
; `cqrt_ry(%h, -θ)` and `cqrt_free(%h)` — undoing the prep Ry and freeing the
; register — at a point BEFORE `cqrt_measure(%h)` reads it. `cqrt_free` is a
; hardware reset = projective measurement (Rule 6); emitting it on a register a
; user measurement still reads is a hidden collapse (the measure sees |0>, not
; the prepared state): a verify-clean wrong unitary AND a Rule 5/6 violation.
;
; ChainWalk::forwardConsumerCount excluded measure sinks, so the measured
; upstream handle `%h` (Lineage[1]) never tripped the fan-out guard, and
; FreePoint inspected only the dead TERMINAL's users (empty), so its
; post-measure guard never saw `%h`'s measure — exit 0, the adjoint+free
; emitted before the measure. The fix scans every NON-terminal lineage handle
; for a measure sink (recoverForwardChain) and declines the whole chain LOUDLY
; (Rule 6: a post-measure gate is a loud reject, never a silent skip). A
; measured TERMINAL stays the existing silent Measured skip; the dead chain
; whose lineage is NOT measured still uncomputes
; (lowering_uncompute_dead_sibling_no_measure.ll).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %x) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %dead = add i32 %q, 7                          ; DEAD tainted template terminal
  %m    = call i32 @cq_measure_si32(i32 %q)      ; measures the register via the upstream handle
  ret i32 %m
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
