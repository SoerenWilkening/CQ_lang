; control_swap_reject_nested_cond_datause_measure_early.ll — DECLINE probe
; (ziov.3, MeasuredEarly arm): a depth-2 phase nest whose OUTER condition is
; reused as data, and that data is MEASURED in the OUTER route block (Pred),
; BEFORE the route would control on the flag.
;
; `bool f = cq_measure(q>5); if (q>5) { ... }` — clang -O1 CSEs to ONE `icmp` and
; the `cq_measure` of the flag-derived value lands in the outer Pred (the route
; block), ahead of the conditional `br`. A shared-flag lowering would emit
; `cqrt_measure` on the flag BEFORE the route's cswap — a route controlled by an
; ALREADY-COLLAPSED flag (the WI-1 atk9 hazard, now on the nested level). ziov.3
; declines it with the SAME string the flat path uses ("condition measured before
; the control route"); a measure DOWNSTREAM of the route would not (but nested
; declines every cond-data-use regardless until sharing lands).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition measured before the control route under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  %z  = zext i1 %c1 to i32          ; DATA use of the OUTER condition
  %mz = call i32 @cq_measure_si32(i32 %z)   ; MEASURE the flag-derived value in PRED
  br i1 %c1, label %mid, label %merge
mid:
  %g  = call i32 @cq_phi_si32(i32 %q, double %b)
  %c2 = icmp slt i32 %g, 9
  br i1 %c2, label %arm, label %merge
arm:
  %h  = call i32 @cq_phi_si32(i32 %g, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  %r  = add i32 %m, %mz
  ret i32 %r
}
