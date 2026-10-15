; control_angle_select_reject_tree_root_shared.ll — DECLINE (bd
; test_C_libtooling-dm7f.54, S4 one node up): the compound condition's ROOT is
; also read as DATA.
;
;     int z = a && b; cq_theta(&t, (a && b) ? .7 : .3);   // -O1 CSEs the and
;
; The network is minted from the tree and its dead root erased; a second
; consumer of the root would be a second owner of one predicate (the S4
; single-user clause the bare compare has). `NotApplicable`, so the caller's
; `rotation angle` decline fires.
;
; ⚠ FLIPPED TO AN ACCEPT IN THE SAME BATCH (bd dm7f.54 round-1 review item D),
; NAME KEPT (L8): the single-user clause one node up was an over-decline with a
; misleading string. The network reads the LEAVES, not the root, so the root
; `%ab = and i1` survives for its data use (lowered by `lowerOps` as
; `cq_template_and_i1`, measured) while the angle network mints its own ancilla.
; ANALYTIC: t gets Ry(.7) iff a ∧ b, Ry(.3) otherwise (after Ry(.4)); the template
; `and` and the network both read a and b in control slots only.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[AB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i1(i32 %[[A]], i32 %[[B]])
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G]], i32 %[[T]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[AB]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[T]])

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01) #0
  %t0 = call i1 @cq_theta_i1(i1 false, double 4.000000e-01) #0
  %ab = and i1 %a, %b
  %ang = select i1 %ab, double 0x3FE6666666666666, double 3.000000e-01
  %t = call i1 @cq_theta_i1(i1 %t0, double %ang) #0
  %mab = call i1 @cq_measure_i1(i1 %ab)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %z1 = zext i1 %mab to i32
  %z2 = zext i1 %mt to i32
  %s = add i32 %z1, %z2
  ret i32 %s
}

attributes #0 = { nomerge nounwind }
