; control_angle_select_ry_mergephi_chained_cond.ll — ACCEPT (bd test_C_libtooling-dm7f.54):
; a Ry ANGLE SELECT whose condition is the merge φ of a CHAINED in-place Ry
; region (the register was live before the region rotated it), fresh target.
;
;     bool a = 0, b = 0, t = 0;
;     cq_theta(&a, 1.0); cq_theta(&b, 0.6);
;     if (a) cq_theta(&b, 0.5);
;     cq_theta(&t, b ? 0.7 : 0.3);
;
; `condProvenance(φ)` is {φ, T(b0), b0}; closed per seed, the arm gate T is an
; OFF-ancestry sibling of b0, so gate 2c declined `condition predates a
; non-diagonal gate` although the condition reads φ, the record AFTER T. The
; angle select now passes dm7f.53's covered producer set
; (`condTreeCoveredPhiGates`, the one spelling the `br` twin uses) at gate 2c
; and at S11 — the twin `if (a) cq_theta(&b,.5); if (b) cq_theta(&t,.5);`
; already lowered. (The 4.4 DATA select over the same φ still declines: filed.)
; ANALYTIC: h_b = Ry(.6) then Ry(.5) controlled on a; bf copies b; t = Ry(.7)
; on b = 1, Ry(.3) on b = 0; bf un-copied, freed at |0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  %b0 = call i1 @cq_theta_i1(i1 false, double 6.000000e-01) #0
  br i1 %a, label %arm, label %merge

arm:
  %b1 = call i1 @cq_theta_i1(i1 %b0, double 5.000000e-01) #0
  br label %merge

merge:
  %b = phi i1 [ %b1, %arm ], [ %b0, %entry ]
  %ang = select i1 %b, double 0x3FE6666666666666, double 3.000000e-01
  %t = call i1 @cq_theta_i1(i1 false, double %ang) #0
  %ma = call i1 @cq_measure_i1(i1 %a)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %za = zext i1 %ma to i32
  %zb = zext i1 %mb to i32
  %zt = zext i1 %mt to i32
  %s1 = add i32 %za, %zb
  %s = add i32 %s1, %zt
  ret i32 %s
}

attributes #0 = { nomerge nounwind }

; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[A]], double 1.000000e+00)
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 6.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[A]], i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[B]], i32 %[[F]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[B]], i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[A]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[B]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[T]])
