; A multi-phi tainted diamond whose branch condition is the grammar's own NOT
; spelling `xor %cmp, true` — NO RAIL ANYWHERE.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp sgt i32 %q, 1
  %n = xor i1 %c, true
  br i1 %n, label %arm, label %merge
arm:
  br label %merge
merge:
  %a4 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %b5 = phi i32 [ 2, %arm ], [ 6, %entry ]
  %c6 = phi i32 [ 2, %arm ], [ 7, %entry ]
  %d7 = phi i32 [ 2, %arm ], [ 8, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %m3 = call i32 @cq_measure_si32(i32 %c6)
  %m4 = call i32 @cq_measure_si32(i32 %d7)
  %m5 = call i32 @cq_measure_si32(i32 %q)
  %s1 = add i32 %m1, %m2
  %s2 = add i32 %s1, %m3
  %s3 = add i32 %s2, %m4
  %s4 = add i32 %s3, %m5
  ret i32 %s4
}
