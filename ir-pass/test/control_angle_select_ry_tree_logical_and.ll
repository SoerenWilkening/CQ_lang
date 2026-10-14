; control_angle_select_ry_tree_logical_and.ll — ACCEPT (bd test_C_libtooling-dm7f.54):
; a Ry ANGLE SELECT under a COMPOUND condition over two `_Bool` rails, on a
; prepped target.
;
;     bool a = 0, b = 0, t = 0;
;     cq_theta(&a, 1.0); cq_theta(&b, 0.5); cq_theta(&t, 0.4);
;     cq_theta(&t, (a && b) ? 0.7 : 0.3);
;
; `-O1` spells `a && b` as the LOGICAL select `select i1 %a, i1 %b, i1 false`.
; Before dm7f.54 the angle select declined `control flow` (gate 2 collected
; the tree without `AllowLogicalSelect`) and the logical select was classified
; on its own as a 4.4 i1 DATA select. Now `ControlDetect` pre-claims the node
; and the angle select's network (`CondTreeEmit`, the dm7f.52 in-place tree's
; grammar) mints the AND onto a fresh ancilla `g` by `toffoli(a, b, g)`.
; ANALYTIC: g = a ∧ b; g = 1 -> Ry(.7) on t, g = 0 -> Ry(.3); the second
; toffoli returns g to 0 (a, b untouched: control slots only), proven-|0> free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01) #0
  %t0 = call i1 @cq_theta_i1(i1 false, double 4.000000e-01) #0
  %ab = select i1 %a, i1 %b, i1 false
  %ang = select i1 %ab, double 0x3FE6666666666666, double 3.000000e-01
  %t = call i1 @cq_theta_i1(i1 %t0, double %ang) #0
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
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[A]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[B]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[T]])
; CHECK-NOT:  call void @cqrt_free(

; NEG-NOT: = select
; NEG-NOT: cq_theta_
; NEG-NOT: cqrt_copy
