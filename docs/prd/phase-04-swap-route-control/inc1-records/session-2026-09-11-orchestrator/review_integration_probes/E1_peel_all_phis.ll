; A tainted-condition diamond whose merge carries TWO phis, BOTH available at the pred.
; After the peel the merge has ZERO phis: what owns the still-tainted `br`?
define i32 @main() local_unnamed_addr {
entry:
  %b0 = tail call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  br label %merge
merge:
  %a = phi i32 [ 2, %arm ], [ 5, %entry ]
  %z = phi i32 [ 4, %arm ], [ 1, %entry ]
  %m1 = tail call i32 @cq_measure_si32(i32 %a)
  %m2 = tail call i32 @cq_measure_si32(i32 %z)
  %m3 = tail call zeroext i1 @cq_measure_i1(i1 zeroext %b0)
  %z3 = zext i1 %m3 to i32
  %s1 = add i32 %m1, %m2
  %s2 = add i32 %s1, %z3
  ret i32 %s2
}
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
