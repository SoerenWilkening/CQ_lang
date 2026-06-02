; lowering_control_angle_rotdiff.ll — Family B2 (WP10), positive. `-O1` sinks a
; tainted `if (u > 5) { u = rz(u, a); } else { u = rz(u, b); }` into
; `rz(u, select(u>5, a, b))` — a tainted-condition select over the classical
; `double` rotation angle, feeding ONLY the `cq_phi` angle operand. WP10 lowers
; it as controlled-rotation-by-difference: the unconditional base `Rz(u, b)`
; (false arm) then a flag-controlled `Rz(u, a−b)`. Ry/Rz are angle-additive, so
; `Rz(b + flag·(a−b))` = `Rz(b)·ctrl_flag Rz(a−b)` — total angle `a` when the
; quantum condition holds, `b` otherwise: trace-equivalent to the braced
; controlled rotation, and verify-clean (replaces the WP9 B1 diagnostic for this
; lowerable shape; non-rotation double-selects still diagnose).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; The condition lowers to the flag; the base Rz uses the false-arm angle %b; the
; controlled Rz uses the host difference a−b; the flag is then uncomputed.
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     call void @cqrt_rz_i32(i32 %[[H]], double %b)
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = fsub double %a, %b
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[H]], double %[[D]])
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[H]], i32 5)
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  %ang = select i1 %c, double %a, double %b      ; rotation angle under quantum control
  %r = call i32 @cq_phi_si32(i32 %u, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
