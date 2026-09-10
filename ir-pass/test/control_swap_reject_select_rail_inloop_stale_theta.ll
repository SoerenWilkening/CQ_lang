; control_swap_reject_select_rail_inloop_stale_theta.ll — DECLINE (bd
; test_C_libtooling-r9e5, Inc 1b-B.1): a body `cq_theta` on the condition rail
; inside a classically-bounded loop (probe `k1`/`s18`, plain `clang -O1` C).
;
; THIS IS THE LOOP-SAFETY OF THE DT PRONG, and it is the reason the prong is
; `provablyBefore` and not plain dominance. The body theta DOMINATES nothing
; useful: it is reached from the select on the back edge, so
; `!isPotentiallyReachable(theta, Sel)` is FALSE — the gate is NOT proven to run
; after EVERY execution of the select, because iteration 2's select reads a rail
; iteration 1's theta already moved. Decline (`WireWalk.h`'s proof obligation:
; "IF B executes, A has already executed AND never runs again"). The invariant
; twin with no body gate ACCEPTS and lowers ROLLED
; (`control_swap_select_rail_inloop_invariant.ll`). Green on both binaries.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i1 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %acc2, %loop ]
  %t = add nuw nsw i32 %i, 2
  %a = select i1 %b, i32 %t, i32 5
  %n = call i32 @cq_measure_si32(i32 %a)
  %s = call i1 @cq_theta_i1(i1 %b, double 1.000000e-01)
  %sm = call i1 @cq_measure_i1(i1 %s)
  %acc2 = add i32 %acc, %n
  %i2 = add nuw nsw i32 %i, 1
  %ic = icmp eq i32 %i2, 3
  br i1 %ic, label %exit, label %loop
exit:
  %m = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %m to i32
  %r = add i32 %acc2, %z
  ret i32 %r
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
