; SCOPE §15.4 — an incoming that dominates `BI` only through a PHI in `Pred`
; (`%v` is a classical join phi at the top of the region's own pred block).
@g = external global i32
define i32 @example() {
entry:
  %k = load volatile i32, ptr @g, align 4
  %kc = icmp eq i32 %k, 9
  br i1 %kc, label %a1, label %a2
a1:
  br label %pred
a2:
  br label %pred
pred:
  %v = phi i32 [ 7, %a1 ], [ 4, %a2 ]
  %b0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %merge, label %arm
arm:
  %t = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %merge
merge:
  %amux = phi i32 [ %v, %arm ], [ 2, %pred ]
  %b1 = phi i32 [ %t, %arm ], [ 0, %pred ]
  %m1 = call i32 @cq_measure_si32(i32 %b1)
  %ma = call i32 @cq_measure_si32(i32 %amux)
  %s = add nsw i32 %m1, %ma
  ret i32 %s
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
