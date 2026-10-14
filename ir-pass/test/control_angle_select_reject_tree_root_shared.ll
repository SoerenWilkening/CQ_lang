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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control

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
