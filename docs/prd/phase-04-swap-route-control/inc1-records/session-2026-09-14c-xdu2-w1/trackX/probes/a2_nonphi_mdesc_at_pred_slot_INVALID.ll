; a2 — the same attempt at F2's OTHER slot: the merge phi's PRED-edge incoming.
; EXPECT: opt -passes=verify REJECTS (use-before-def on the pred edge).
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %t = call i32 @cq_theta_si32(i32 7, double 9.000000e-01)
  br label %merge
merge:
  %m = phi i32 [ %t, %arm ], [ %bad, %entry ]
  %bad = add i32 %m, 0
  %mm = call i32 @cq_measure_si32(i32 %m)
  ret i32 %mm
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
