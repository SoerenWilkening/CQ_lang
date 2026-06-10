; lowering_reject_stale_record_loop.ll — DECLINE: the stale-record shape where
; the pure producer DOMINATES the chained theta but a loop back-edge
; RE-EXECUTES it (test_C_libtooling-uzb adversarial probe; the
; iteration-2 staleness).
;
; In the loop body the add precedes the chained Ry, so a dominance-only guard
; would accept — but the emitted `cq_template_add` fires ONCE PER ITERATION
; while the SSA value `%d = add i32 %q, 1` is loop-invariant (it denotes the
; pre-any-Ry record, fixed): from iteration 2 on, the template reads the wire
; AFTER the previous iteration's `cqrt_ry` — the same verify-clean stale-record
; wrong unitary, hidden behind the back-edge. The guard's order proof is
; therefore dominance PLUS no-reach-back (`isPotentiallyReachable(theta, add)`
; must be provably false); here the theta reaches the add via the back-edge,
; so the guard declines. (The same module would also die later in FreePoint's
; loop-backedge live-range reject — but opt exits at the FIRST diagnostic, and
; relying on a downstream guard for a soundness hole is not a fix; Rule 10.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %d = add i32 %q, 1                                  ; dominates the theta, BUT...
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; ...the Ry reaches it back
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, %n
  br i1 %done, label %loop, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
