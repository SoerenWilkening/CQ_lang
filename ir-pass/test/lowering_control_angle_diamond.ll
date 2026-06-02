; lowering_control_angle_diamond.ll — Family B1, diamond form (test_C_libtooling-cwk).
; The `br`-diamond analog of lowering_control_angle_select.ll: a tainted-condition
; branch whose merge `φ` is a classical `double` (a rotation ANGLE) feeding a
; `cq_phi` rotation. The SELECT form `rz(u, select(cmp,a,b))` is lowered as
; controlled-rotation-by-difference (lowering_control_angle_rotdiff.ll); this
; CFG-diamond form is NOT yet routed there.
;
; Before the fix, detection built a BranchRegion and `dissolveBranchPhi` treated
; the `phi double` as integer-handle DATA via its `reduceClassicalMux` path —
; emitting `cqrt_alloc_f64` + `cq_template_add_f64_hl_controlled` and rewriting
; the rotation's `double` angle operand to an i32 handle (a broken/wrong lowering,
; also an integer `sub` on `double` operands). Detection now diagnoses a
; classical-FP merge `φ` under quantum control as "rotation angle", on the same
; surface as the select-form B1 guard — never a miscompiled region. (Lowering the
; diamond-form angle dispatch as controlled-rotation-by-difference is a future
; enhancement, the cwk follow-on.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5                      ; tainted condition (q is a handle)
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
merge:
  %ang = phi double [ %a, %arm ], [ %b, %entry ]  ; classical double under control
  %r = call i32 @cq_phi_si32(i32 %v, double %ang) ; angle feed — unlowerable today
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
