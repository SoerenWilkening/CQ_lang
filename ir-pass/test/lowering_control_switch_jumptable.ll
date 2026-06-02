; lowering_control_switch_jumptable.ll — Phase 4.x (test_C_libtooling-5zu),
; POSITIVE. `clang -O1` may lower a tainted angle `switch`/`if-else-if` over
; rotation ANGLES not to a select chain (WP16) but to a jump TABLE — a constant
; array + bound-check diamond + `getelementptr`/`load` indexed by the scrutinee.
; Indexing memory by the quantum HANDLE id is a silent miscompile, so the
; tainted-memory-escape guard diagnoses any UN-recognized such shape.
;
; This canonical shape is now NORMALIZED (normalizeJumpTableAngle, a pre-pass
; before detection): `a = (idx<N) ? table[idx] : base` with `idx = q + K` and a
; constant `@table` is rewritten into the eq-flag angle-select chain
; `base + Σ_i [q == i−K]·(table[i] − base)` (constants read at compile time), the
; diamond collapsed and the gep/load deleted — so detection sees a clean WP16
; `AngleSelectRegion` chain and `reduceAngleSelectChain` lowers it as base +
; per-case controlled-difference, with NO handle-indexed memory access.
;
; Here idx = q−1, table = [0.1, 0.2, 0.3], base = 0.9, N = 3 → in-bounds q∈{1,2,3}
; map to eq-flags q==1/2/3 with differences table[i]−base = {−0.8, −0.7, −0.6}.
; Net angle: q==1→0.1, q==2→0.2, q==3→0.3, else 0.9 — exactly table[q−1] / 0.9.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; The unconditional base (out-of-bounds / default angle):
; CHECK:     call void @cqrt_rz_i32(i32 %[[HV:[a-zA-Z0-9_.]+]], double 9.000000e-01)
; One controlled-difference per in-bounds case, each in its own eq compute/uncompute:
; CHECK:     %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F3]], i32 %[[HV]], double 0xBFE3333333333334)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 3)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 2)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[HV]], double 0xBFE6666666666666)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 2)
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[HQ]], i32 1)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[HV]], double -8.000000e-01)
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[HQ]], i32 1)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[HV]])
; No handle-indexed memory, no residual table dispatch:
; CHECK-NOT: getelementptr
; CHECK-NOT: load double
; CHECK-NOT: error
; CHECK-NOT: = phi
@switch.table = private unnamed_addr constant [3 x double] [double 1.000000e-01, double 2.000000e-01, double 3.000000e-01], align 8
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %idx = add i32 %q, -1
  %bound = icmp ult i32 %idx, 3
  br i1 %bound, label %lookup, label %merge
lookup:
  %zext = zext i32 %idx to i64
  %gep = getelementptr inbounds [3 x double], ptr @switch.table, i64 0, i64 %zext
  %ang = load double, ptr %gep, align 8
  br label %merge
merge:
  %a = phi double [ %ang, %lookup ], [ 9.000000e-01, %entry ]
  %r = call i32 @cq_phi_si32(i32 %v, double %a)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
