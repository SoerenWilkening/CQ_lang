; lowering_control_angle_diamond_multi.ll — Family B2, MULTI-CONSUMER angle φ,
; POSITIVE (test_C_libtooling-byx, adversarial-review anchor lock). A single
; classical-angle merge φ feeds TWO rotations (on distinct handles %u and %w).
; Both controlled-difference rotations MUST precede the single flag uncompute
; (compute → controlled body → uncompute, §1.5).
;
; ANCHOR LOCK: the angle reducer collects consumers in use-list order (NOT program
; order); deriving the uncompute anchor from the last-ITERATED consumer would
; splice the `..._hl_inv` flag uncompute BETWEEN the two controlled rotations, so
; the program-later rotation fires on an already-uncomputed flag — a verify-clean
; SILENT miscompile. The CHECK-NOT below forbids any uncompute between the two
; controlled-difference rotations.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(
; CHECK-NOT: cq_template_icmp_sgt_i32_hl_inv
; CHECK:     call void @cqrt_rz_i32_controlled(
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK-NOT: phi double
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %w0, double %a, double %b) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w = call i32 @cq_theta_si32(i32 %w0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
merge:
  %ang = phi double [ %a, %arm ], [ %b, %entry ]
  %r1 = call i32 @cq_phi_si32(i32 %u, double %ang)
  %r2 = call i32 @cq_phi_si32(i32 %w, double %ang)
  %m1 = call i32 @cq_measure_si32(i32 %r1)
  %m2 = call i32 @cq_measure_si32(i32 %r2)
  %s = add i32 %m1, %m2
  ret i32 %s
}
