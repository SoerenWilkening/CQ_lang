; control_angle_select_ry_mergephi_cond.ll — ACCEPT (bd test_C_libtooling-dm7f.54):
; a Ry ANGLE SELECT whose condition is the MERGE φ of a preceding controlled
; STATE PREP, on a fresh target (the Dicke-cascade shape, reporter t6).
;
;     bool a = 0, b = 0, t = 0;
;     cq_theta(&a, 1.0);
;     if (a) cq_theta(&b, 0.5);            // prep: b = a ? Ry(.5)|0> : |0>
;     cq_theta(&t, b ? 0.7 : 0.3);
;
; The φ is claimed by the prep region (rung 0, `preppedRailPhiRegionIdx`); the
; angle-select region records a precedence edge to it (`PrepRegionIdxs`, the
; 4.4 select's F-M1 discipline), so the prep is emitted FIRST, its M-β turns
; the φ into the hoisted `cq_theta_i1`, and the angle select re-reads its
; condition as that RAIL and takes the CNOT copy flag.
; ANALYTIC: b's rail h_b holds a ? Ry(.5)|0> : |0>; bf copies its basis label;
; t = Ry(.7)|0> on b = 1, Ry(.3)|0> on b = 0; bf un-copied and freed at |0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  br i1 %a, label %arm, label %merge

arm:
  %b1 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01) #0
  br label %merge

merge:
  %b = phi i1 [ %b1, %arm ], [ false, %entry ]
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
; CHECK-NOT:  call void @cqrt_free(

; NEG-NOT: = select
; NEG-NOT: = phi
; NEG-NOT: br i1
; NEG-NOT: cq_theta_
