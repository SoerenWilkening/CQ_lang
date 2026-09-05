; control_swap_reject_nested_stalecond_direct.ll — DECLINE (bd tayx clearance,
; the p16 probe family): the depth-2 homogeneous-phase NEST had NO
; stale-condition wire guard AT ALL. ControlDetect dispatches
; RegionShape::Nested to recoverRegionTree, BYPASSING classifyArms (and with
; it condWireDisposition, then named nonDiagonalGateBeforeBranch), and
; RegionTreeDetect walked only the inner
; condition's provenance against the rail closure — neither condition's WIRE
; was ever checked for a non-diagonal gate. A chained cq_theta re-rotating the
; outer condition's wire before the outer compare — here DIRECTLY, no router
; needed — let the outer eq-flag mint read the post-Ry basis while the SSA
; condition denoted the pre-Ry record: the routed nested stream emitted
; verify-clean (pre-fix exit 0: `ry(.5); ry(.7); icmp_sgt mint ...`),
; plain-C-reachable at -O1. Fixed by the per-level stale-condition guard in
; RegionTreeDetect (the flat-path mirror: position-free router-crossing wire
; walk over each condition's provenance + the bounded compare->branch scan).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_cswap
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b, i1 %cc) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %cc, label %x, label %y
x:
  br label %pre
y:
  br label %pre
pre:
  %r  = phi i32 [ %q, %x ], [ %q, %y ]
  %g2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)  ; DIRECT in-place Ry on q's wire
  %c1 = icmp sgt i32 %q, 5                                    ; outer compare: pre-Ry record
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  %m2 = call i32 @cq_measure_si32(i32 %g2)
  ret i32 %m
}
