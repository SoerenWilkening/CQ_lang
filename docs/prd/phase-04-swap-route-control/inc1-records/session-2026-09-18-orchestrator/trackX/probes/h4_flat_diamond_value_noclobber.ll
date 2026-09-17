; h4_flat_diamond_value_noclobber.ll — Track X (bd x5fp), session 2026-09-18.
; POSITIVE CONTROL, hand IR: a real CFG diamond whose arm is a pure one-op value
; chain, with NO clobber (the condition reads %q, the arm rewrites %r).
; `-O1` if-converts this shape out of existence from C (measured: x05/x07), so
; the §3c prong at ArmClassify.cpp:5774 is only reachable from hand IR.
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 9, double 3.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.000000e-01)
  %c = icmp sgt i32 %q, 5
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
