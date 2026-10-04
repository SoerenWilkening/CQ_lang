; control_swap_reject_select_rail_inloop_measure_after.ll — DECLINE (bd
; test_C_libtooling-r9e5, 1b-B.1; orchestrator finding F-B1-1 on the first B.1
; build, plain-C reachable):
;
;     bool b = (bool)0; cq_theta(&b, 0.5); int acc = 0;
;     for (int i = 0; i < 3; ++i) { int a = b ? i : 5; acc += cq_measure(a) + cq_measure(b); }
;
; The select stays INSIDE the loop body because its true arm is the loop counter
; (loop-VARIANT — the constant-arm form `b ? 2 : 5` is LICM-hoisted out of the
; loop by -O1 and then measures genuinely downstream, `..._rail_measure_after`).
; The measurement of `b` sits AFTER the select in the SAME block, so a
; position-only test says "after" — but the block is on a cycle, and every
; activation after the first controls its copies on a register the previous
; trip COLLAPSED: a post-measure gate, Rule 6's loud-reject class, and exactly
; what the kickback's block-terminator read point refuses on the same program.
; The first B.1 build ACCEPTED this module (`opt` exit 0, verify-clean, STRICT
; stage 2b `0 violation(s)`); the rail rung now asks `isPotentiallyReachable`
; for EVERY measure, which answers the same-block-on-a-cycle case itself.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %loop
loop:
  %acc = phi i32 [ 0, %entry ], [ %acc1, %loop ]
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = select i1 %b, i32 %i, i32 5
  %m = call i32 @cq_measure_si32(i32 %a)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %mb to i32
  %t = add i32 %m, %acc
  %acc1 = add i32 %t, %z
  %i1 = add nuw nsw i32 %i, 1
  %c = icmp eq i32 %i1, 3
  br i1 %c, label %exit, label %loop
exit:
  ret i32 %acc1
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
