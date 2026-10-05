; control_swap_reject_switch_value_derived_angle.ll — DECLINE (Rule-9 detect-before-
; mutate; the WI-3 Rule-13 clearance probe). A VALUE switch (`case 0: r = p + 3;
; case 1: r = p + 5;`) preceded by `cq_phi((double)p)`, a branch phase whose angle is
; QUANTUM-DERIVED. The switch value twin of
; control_swap_reject_value_derived_tainted_angle.ll (the diamond fixture).
;
; Pre-3qlq the tainted angle sat on the switch's derived routed base
; `%pd = cq_phi(%p, sitofp(%p))`, and `proveSwitchValue` had to decline it before
; `emitSwitchValueRegion` mutated anything. Since 3qlq the phase is register-free
; and outside the region, and RotationLowering's quantum-derived-angle guard owns
; the decline (Rule 3).
;
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: rotation angle under quantum control
; NEW: cq rotation lowering: unsupported quantum-derived rotation angle
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; the value-arm emit machinery must NEVER run on this region
; CHECK-NOT: value-arm swap-route
; CHECK-NOT: cqrt_copy
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %f = sitofp i32 %p to double                    ; TAINTED angle producer
  call void @cq_phi(double %f)  ; derived routed base, tainted angle
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v1 = add i32 %p, 3
  br label %merge
a1:
  %v2 = add i32 %p, 5
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v1, %a0 ], [ %v2, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
