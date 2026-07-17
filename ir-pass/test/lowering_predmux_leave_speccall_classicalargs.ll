; lowering_predmux_leave_speccall_classicalargs.ll — DECLINE probe (bd adia,
; the 6.5 ANTI-OVERLAP fence): the E4 pending-spec admit requires ≥1 TAINTED
; call argument. An all-classical-args pure call in a tainted arm is the 6.5
; classical-call-arm owner's territory (flat diamonds) — PredMux must NOT
; steal it, in ANY nesting. Here the nested shape has no shipped owner, so
; the region is left and the existing loud nested-control decline fires,
; char-for-char — never a silent claim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @purefn(i32 %a) {
  %t = mul i32 %a, 3
  %r = add i32 %t, 7
  ret i32 %r
}
define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @purefn(i32 %u)          ; classical arg — NOT pending-spec
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
