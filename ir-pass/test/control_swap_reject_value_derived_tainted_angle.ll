; control_swap_reject_value_derived_tainted_angle.ll — DECLINE: a branch phase
; with a quantum-derived angle ahead of a VALUE diamond.
;
; The value-arm twin of control_swap_reject_tainted_angle_prebase.ll:
; `cq_phi((double)p); if (q > 5) r = p + 3;` — an otherwise accept-class value
; diamond (condition disjoint from %p) preceded by a phase whose angle is the
; sitofp of %p. RotationLowering's quantum-derived-angle guard owns the decline
; (Rule 3). Pre-3qlq the angle sat on the diamond's derived routed base
; `%pd = cq_phi(%p, sitofp(%p))`, and classifyArms had to decline it before the
; region was EMITTED and FLATTENED (found by the WI-4 §8 adversarial review,
; 2026-06-11).
;
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: rotation angle under quantum control
; NEW: cq rotation lowering: unsupported quantum-derived rotation angle
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %f  = sitofp i32 %p to double                    ; TAINTED angle producer
  call void @cq_phi(double %f)  ; derived base, tainted angle
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = add i32 %p, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; the value-arm defer/accept machinery must never run on this region
; CHECK-NOT: value-arm swap-route
; CHECK-NOT: cqrt_copy
