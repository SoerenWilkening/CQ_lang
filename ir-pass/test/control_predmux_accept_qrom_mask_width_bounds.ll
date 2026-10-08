; control_predmux_accept_qrom_mask_width_bounds.ll — ACCEPT (bd 01po.2): the
; boundaries of the narrow-source PredMux mask
; (control_predmux_accept_qrom_mask_narrow_source.ll). The mask moves onto the
; W-bit source of the gep's widening only when N-1 fits in W bits (N <= 2^W) AND
; N <= 2^31 (the count `cqrt_qram_alloc_<W>` takes is an i32). Outside that the
; flatten keeps the pre-01po.2 pointer-width mask byte for byte:
; `<ext>_iW_to_i64 -> and_i64_hl(.., N-1) -> trunc_i64_to_i32` bracket.
;   * sext i8 into [512 x i8]: N = 2^9 > 2^8, the mask does not fit the source
;     (sext(src) & 511 keeps sign-copy bit 8) -> the i64 form;
;   * sext i32 into [2^31 x i8]: N = 2^31, the largest narrowed table ->
;     `and_i32_hl(src, 2147483647)`, no bracket;
;   * sext i32 into [2^32 x i8]: N = 2^32 > 2^31 -> the i64 form. (The table's
;     count does not fit the i32 alloc operand, `cqrt_qram_alloc_i8(i32 0)`; that
;     encoding is pre-existing and untouched here.)
; RETIREMENT TRIGGER: the two alloc counts pinned below for N = 2^31 and N = 2^32
; (`i32 -2147483648`, `i32 0`) are the WRAPPED encoding bd 01po.6 tracks, pinned
; only so a change to them is seen. When 01po.6 lands (loud failure or a wider
; count) those two cases change with it; the mask expectations do not.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
@t512 = internal unnamed_addr constant [512 x i8] zeroinitializer
@t2p31 = internal unnamed_addr constant [2147483648 x i8] zeroinitializer
@t2p32 = internal unnamed_addr constant [4294967296 x i8] zeroinitializer
declare i8 @cq_theta_si8(i8, double)
declare i32 @cq_theta_si32(i32, double)
declare i8 @cq_measure_si8(i8)

define i8 @sext_i8_n512(i8 %u0) {
entry:
  %q = call i8 @cq_theta_si8(i8 %u0, double 5.000000e-01)
  %c = icmp sgt i8 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %idx = sext i8 %q to i64
  %g = getelementptr inbounds [512 x i8], ptr @t512, i64 0, i64 %idx
  %v = load i8, ptr %g, align 1
  br label %merge
merge:
  %rm = phi i8 [ %v, %arm ], [ 99, %entry ]
  %m = call i8 @cq_measure_si8(i8 %rm)
  ret i8 %m
}
; CHECK-LABEL: define i8 @sext_i8_n512(
; CHECK: %u0.stable = freeze i8 %u0
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i8(i32 512)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %u0.stable)
; CHECK-NOT:  cq_template_and_i8
; CHECK:      %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i8_to_i64(i32 %[[Q]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[E]], i64 511)
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[M]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i8(i32 %[[T]], i32 %[[X]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[X]], i32 %[[M]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cq_template_and_i64_hl_unc(i32 %[[M]], i32 %[[E]], i64 511)
; CHECK-NEXT: call void @cqrt_free(i32 %[[M]])
; CHECK-NEXT: call void @cq_template_sext_i8_to_i64_unc(i32 %[[E]], i32 %[[Q]])
; CHECK-NOT:  cq_template_and_i8

define i8 @sext_i32_n2p31(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %idx = sext i32 %q to i64
  %g = getelementptr inbounds [2147483648 x i8], ptr @t2p31, i64 0, i64 %idx
  %v = load i8, ptr %g, align 1
  br label %merge
merge:
  %rm = phi i8 [ %v, %arm ], [ 99, %entry ]
  %m = call i8 @cq_measure_si8(i8 %rm)
  ret i8 %m
}
; CHECK-LABEL: define i8 @sext_i32_n2p31(
; CHECK: %u0.stable = freeze i32 %u0
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i8(i32 -2147483648)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0.stable)
; CHECK-NOT:  _to_i64
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 2147483647)
; CHECK-NEXT: call i32 @cqrt_qram_load_i8(i32 %[[T]], i32 %[[M]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[M]], i32 %[[Q]], i32 2147483647)
; CHECK-NEXT: call void @cqrt_free(i32 %[[M]])
; CHECK-NOT:  _to_i64

define i8 @sext_i32_n2p32(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %idx = sext i32 %q to i64
  %g = getelementptr inbounds [4294967296 x i8], ptr @t2p32, i64 0, i64 %idx
  %v = load i8, ptr %g, align 1
  br label %merge
merge:
  %rm = phi i8 [ %v, %arm ], [ 99, %entry ]
  %m = call i8 @cq_measure_si8(i8 %rm)
  ret i8 %m
}
; CHECK-LABEL: define i8 @sext_i32_n2p32(
; CHECK: %u0.stable = freeze i32 %u0
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i8(i32 0)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0.stable)
; CHECK-NOT:  cq_template_and_i32
; CHECK:      %[[E:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i32_to_i64(i32 %[[Q]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i64_hl(i32 %[[E]], i64 4294967295)
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[M]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i8(i32 %[[T]], i32 %[[X]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[X]], i32 %[[M]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cq_template_and_i64_hl_unc(i32 %[[M]], i32 %[[E]], i64 4294967295)
; CHECK-NEXT: call void @cqrt_free(i32 %[[M]])
; CHECK-NEXT: call void @cq_template_sext_i32_to_i64_unc(i32 %[[E]], i32 %[[Q]])
; CHECK-NOT:  cq_template_and_i32
; CHECK-LABEL: declare
