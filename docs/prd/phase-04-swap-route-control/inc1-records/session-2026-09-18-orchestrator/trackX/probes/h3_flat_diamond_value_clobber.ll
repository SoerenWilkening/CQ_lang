; h3_flat_diamond_value_clobber.ll — Track X (bd x5fp), session 2026-09-18.
; NEGATIVE CONTROL, hand IR: h4 with ONE operand changed — the condition now
; reads the routed register %r, so the arm rewrites the very register the flag
; was minted from. This is the within-activation §3c clobber, and it must keep
; declining `arm rewrites a condition operand` after any per-activation
; narrowing.
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 9, double 3.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.000000e-01)
  %c = icmp sgt i32 %r, 5
  br i1 %c, label %arm, label %merge

arm:
  %r1 = add nsw i32 %r, 3
  br label %merge

merge:
  %rm = phi i32 [ %r1, %arm ], [ %r, %entry ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %s = add nsw i32 %m, %m2
  ret i32 %s
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
