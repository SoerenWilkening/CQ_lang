; control_swap_reject_value_derived_tainted_angle.ll — DECLINE: a VALUE arm's
; DERIVED routed base carries a quantum-derived angle.
;
;     int q = u0; cq_theta(&q, 0.5);
;     int p = v0; cq_theta(&p, 0.25);
;     cq_theta(&p, (double)p);       /* derived base, TAINTED angle */
;     if (q > 5) p = p + 3;
;     return cq_measure(p);
;
; `%pd = cq_theta(%p, sitofp(%p))` is the routed base of an otherwise
; accept-class value diamond (`if (q > 5) { pd = pd + 3 }`, condition disjoint
; from %pd). A rotation angle derived from quantum data has no fixed unitary
; today (Rule 3; NORTHSTAR goal 1 makes it a GAP, bd 94ad), so the module must
; fail loudly and source-located.
;
; Hand IR, not `clang -O1` output: clang speculates the arm's `add` and folds the
; diamond into `select i1 %c, i32 %v1, i32 %pd` (measured), which is the 4.4
; select path, not the value DIAMOND this file pins. The value-arm twin of
; control_swap_reject_tainted_angle_prebase.ll; the switch twin is
; control_swap_reject_switch_value_derived_angle.ll.
;
; WHO DECLINES IT TODAY. Pre-3qlq the base was the register form
; `%pd = cq_phi(%p, sitofp(%p))`, and `classifyArms` declined it pre-mutation
; with the phase path's string (found by the WI-4 §8 adversarial review,
; 2026-06-11: without that value-path check the region was fully EMITTED and
; FLATTENED before rotation lowering's own guard fired). That base check matches
; only the retired `cq_phi_<sfx>` family, so for the in-place Ry base the decline
; now comes from `RotationLowering`'s `declineTaintedAngle`, which runs after
; `lowerControlRegions` (loud either way; the pre-mutation question is reported with bd
; jttf). The asserted string is that clause's.
;
; History: the 3qlq migration turned the base into a register-free `cq_phi(f)`
; ahead of the diamond (no derived base at all); bd jttf (2026-10-05) re-spelled
; it as the tainted-angle in-place Ry above, which restores the derived routed
; base. (The retired stdout `CHECK-NOT`s were vacuous on a decline, R10, and are
; not carried over.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved); jttf: re-spelled register-free 2026-10-05
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %f  = sitofp i32 %p to double                    ; TAINTED angle producer
  %pd = call i32 @cq_theta_si32(i32 %p, double %f) ; derived base, tainted angle
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = add i32 %pd, 3
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %pd, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
