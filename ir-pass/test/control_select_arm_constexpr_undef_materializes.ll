; control_select_arm_constexpr_undef_materializes.ll — ACCEPT, the CONTROL of
; control_select_arm_undef_refined_zero.ll (bd test_C_libtooling-dm7f.81; owner
; ruling ruling-dm7f81-open-qs-2026-10-15 Q1). Mirrors
; control_inplace_ry_reject_stateprep_constexpr_undef_seed.ll (bd z9t1).
;
; The refine-to-zero rule is gated on the arm BEING an `UndefValue`, not on it
; CARRYING one. `ptrtoint (gep @g, undef, 1)` denotes an address that no choice of
; the leaf makes 0, so replacing it with zero would be a silent value change. It
; is a link-time constant uniqued into ONE relocation (bd bu96), so it is written
; as an ordinary literal operand of the controlled xor. Point `armWriteIsNoop` at
; `valueCarriesUndef` and this file goes red (the arm would vanish).
;
; The merge out is MEASURED (never discharged), so the literal sits in exactly one
; emitted slot and LiteralIntegrity guard 1 (two slots) does not fire.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define i32 @example(
; CHECK:      %[[F:[0-9a-zA-Z_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(
; CHECK-NEXT: %[[O:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[O]], i32 ptrtoint (ptr getelementptr ([4 x i32], ptr @g, i32 undef, i32 1) to i32))
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[F]], i32 %[[O]], i32 9)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NOT:  @cqrt_alloc_i32(i32 ptrtoint

@g = external global [4 x i32]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  %a = select i1 %c, i32 ptrtoint (ptr getelementptr ([4 x i32], ptr @g, i32 undef, i32 1) to i32), i32 9
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}
