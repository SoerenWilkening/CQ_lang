; v1 — Rule-13 self-review vector (b): can a CROSS-BLOCK COMPARE leaf ride into step 6
; behind a φ leaf, where its `scanForward` window is vacuous?  Step 5a is supposed to
; decline a cross-block compare leaf `control flow` before step 6 is ever reached.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %q  = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  %cmp = icmp sgt i32 %q, 3            ; the COMPARE leaf, defined HERE
  br label %gap
gap:
  %c2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)  ; a chained Ry the vacuous window would miss
  br label %gap2
gap2:
  %and = select i1 %b1, i1 %cmp, i1 false    ; the TREE: phi leaf AND compare leaf
  br i1 %and, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  %m2 = call i32 @cq_measure_si32(i32 %c2)
  ret i1 %m
}
