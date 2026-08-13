; lowering_bitint_intermediate_masked_i40.ll — Phase 7.1 follow-up D5
; (test_C_libtooling-m0yi). A non-power-of-2 _BitInt(N) INTERMEDIATE lowers TODAY
; with NO new ABI, because clang -O1 does the round-up + mask ITSELF and emits
; only ABI-width stock ops.
;
; FINDING (verified against real clang 19.1.7 -O1, NOT the plan's R-D assumption):
; `unsigned _BitInt(40) z = x + y` does NOT emit a raw `add i40` (which would hit
; abiWidthFromType-empty -> "no template"). clang ROUNDS the i40 up to the i64
; storage width and emits the i40 wraparound as a VISIBLE high-bit mask itself:
;   %s = add i64 ...            ; the add at the rounded ABI width
;   %r = and i64 %s, 1099511627775   ; 2^40-1 — preserves 2^40 wraparound
; Both are stock ops with EXISTING frozen templates (cq_template_add_i64,
; cq_template_and_i64_hl). So the proposed cq_template_mask_<W> frozen family is
; UNNECESSARY — the mask is a plain `and`. (u40)x casts likewise lower as the
; per-operand `and i64 ..., 2^40-1`.
;
; This fixture pins (A) the forward lowering of the round+mask shape and (B) that
; the mask op participates correctly in the whole-DAG _unc reversal: a DEAD masked
; value (kept alive by cq_phi) is uncomputed via cq_template_and_i64_hl_unc(out,
; src, lit) — recompute-and-XOR from the live source, exactly like any `and` (the
; _unc-shape proof the D5 follow-up requires; no masking-specific uncompute code).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)
declare i64 @cq_phi_sll(i64, double)

define void @example(i64 %u0, i64 %u1) {
entry:
  ; (A) measured unsigned _BitInt(40) add — per-operand mask, i64 add, result mask.
  %q0 = call i64 @cq_theta_sll(i64 %u0, double 0.25)
  %q1 = call i64 @cq_theta_sll(i64 %u1, double 0.50)
  %m0 = and i64 %q0, 1099511627775
  %m1 = and i64 %q1, 1099511627775
  %s  = add i64 %m1, %m0
  %r  = and i64 %s, 1099511627775
  %z  = call i64 @cq_measure_sll(i64 %r)
  ; (B) dead masked value kept alive by cq_phi — exercises the and-mask _unc.
  %q2 = call i64 @cq_theta_sll(i64 %u0, double 0.10)
  %d  = and i64 %q2, 1099511627775
  %p  = call i64 @cq_phi_sll(i64 %d, double 0.30)
  ret void
}

; (A) forward: the i40 mask is an ordinary `and` at the rounded i64 ABI width.
; CHECK:     %[[Q0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %u0)
; CHECK:     call void @cqrt_ry_i64(i32 %[[Q0]], double 2.500000e-01)
; CHECK:     %[[Q1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %u1)
; CHECK:     %[[MA:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[Q0]], i64 1099511627775)
; CHECK:     %[[MB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[Q1]], i64 1099511627775)
; CHECK:     %[[ADD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i64(i32 %[[MA]], i32 %[[MB]])
; CHECK:     %[[RES:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[ADD]], i64 1099511627775)
; CHECK:     call i64 @cqrt_measure_i64(i32 %[[RES]])
;
; (B) the dead mask is uncomputed by its void _unc (recompute-and-XOR from live src),
; then the rail is freed |0> — the same Bennett shape as any `and`, no mask-special code.
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[Q2:[a-zA-Z0-9_.]+]], i64 1099511627775)
; CHECK:     call void @cqrt_rz_i64(i32 %[[D]], double 3.000000e-01)
; CHECK:     call void @cq_template_and_i64_hl_unc(i32 %[[D]], i32 %[[Q2]], i64 1099511627775)
; CHECK:     call void @cqrt_free(i32 %[[D]])
;
; No invented masking symbol family — the i40 mask is a stock `and`.
; CHECK-NOT: cq_template_mask
; CHECK-NOT: cq taint escape
