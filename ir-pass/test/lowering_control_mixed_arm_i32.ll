; lowering_control_mixed_arm_i32.ll — Family A (WP7), the mixed-arm shape. A
; tainted `if (u > 5) { y = 5; u = gate(u); }` arriving from real `clang -O1` as
; a `br`-diamond whose merge carries TWO `φ` of DIFFERENT classes: a
; `[modified, original]` gate-handle `φ` for `u`, and a `[classical, classical]`
; data `φ` for `y` (`phi [5, then], [0, entry]`) that rode along under the same
; quantum guard. Phase-4 core dissolved only the first `φ`; the classical-data
; `φ` leaked → broken module. WP7 dissolves each `φ` by its own arm-taint class:
; the gate `φ` RAUWs to the in-place handle; the classical-data `φ` reduces via
; the §5.5 host-difference path (`y` becomes a quantum-controlled write —
; `0 + flag·(5−0)`), exactly like the WP4 classical-arm `select`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; The gate body lowers controlled; the classical-data `φ` reduces to a seeded
; handle (`cqrt_alloc_i32(0)`) plus a flag-controlled add of the host difference
; `5 − 0 = 5` — the same reduction the WP4 `select` uses, now reached from a
; `br`-diamond merge `φ`.
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; CHECK:     call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call i32 @cq_template_add_i32_hl_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK-NOT: br i1
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %then, label %merge
then:
  %ru = call i32 @cq_phi_si32(i32 %u, double 0.25)   ; gate body (u)
  br label %merge
merge:
  %u2 = phi i32 [ %ru, %then ], [ %u, %entry ]       ; [modified, original] (u)
  %y  = phi i32 [ 5, %then ], [ 0, %entry ]          ; [classical, classical] (y)
  %mu = call i32 @cq_measure_si32(i32 %u2)
  %my = call i32 @cq_measure_si32(i32 %y)
  %r = add nsw i32 %mu, %my
  ret i32 %r
}
