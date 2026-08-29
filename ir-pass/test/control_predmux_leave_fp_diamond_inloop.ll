; control_predmux_leave_fp_diamond_inloop.ll — DECLINE (bd vyqi, W5 matrix;
; message re-dispositioned by bd test_C_libtooling-8h7d.5, 2026-08-29): a sole-phi
; both-arms-write FP diamond whose entry sits ON A CFG CYCLE (inside a loop body).
;
; TWO OWNERS, AND THE INCREMENT SWAPPED THEM — the disposition is unchanged, the
; MESSAGE moved. PredMux's W5 witness fires but its E2 (acyclic) fence LEAVES the
; region byte-untouched, exactly as before. What used to catch it next was the
; d8jl `regionEntryInLoop` decline (`control flow inside a loop body`); since
; 7.3 Increment 3 that guard ADMITS a flat region wholly inside a reducible loop,
; so the region reaches `classifyArms`, which declines it for the reason it
; declines the SAME diamond outside a loop: the arms are floating-point value
; arms, which no swap-route emitter lowers.
;
; The new message is the more accurate one — the loop is no longer why this
; program is refused — and it is the SAME string the acyclic spelling produces.
; The fixture's job is unchanged: no flat in-loop FP value diamond is ever
; CLAIMED, and no `cqrt_copy` is emitted for one.
;
; (The INTEGER in-loop value arm — which the acyclic path DOES lower, method-B —
; is fenced separately and keeps the loop message; see
; control_swap_reject_inloop_value_arm.ll.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp olt double %q, 5.000000e-01
  br i1 %c, label %lo, label %hi
lo:
  %a = fadd double %q, -5.000000e-01
  br label %latch
hi:
  %b = fmul double %q, 2.000000e+00
  br label %latch
latch:
  %zv = phi double [ %a, %lo ], [ %b, %hi ]
  %m = call double @cq_measure_f64(double %zv)
  %inext = add i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head
exit:
  ret double %m
}
