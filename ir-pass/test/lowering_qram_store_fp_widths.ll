; lowering_qram_store_fp_widths.ll — ACCEPT (bd 38t2): width smoke for the fp cell
; family at f16 / f32 / f80 (f64 is covered by the carrier/measure/guarded fixtures).
; Each is a dead-scratch tainted-index store `arr[q] = q` (a carrier value), lowering to
; `cqrt_qram_alloc_f<W>` + `cqrt_qram_store_f<W>` with the whole-DAG `_unc` reversal;
; the fp width only tags the symbol name (all handles i32, Rule 15).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare half     @cq_theta_f16(half, double)
declare float    @cq_theta_f32(float, double)
declare x86_fp80 @cq_theta_f80(x86_fp80, double)

define void @s16(double %u0) {
  %arr = alloca [8 x half], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 16, i1 false)
  %q = call half @cq_theta_f16(half 0xH0000, double 5.000000e-01)
  %qi = fptosi half %q to i32
  %iq = sext i32 %qi to i64
  %g = getelementptr inbounds [8 x half], ptr %arr, i64 0, i64 %iq
  store half %q, ptr %g, align 2
  ret void
}

define void @s32(double %u0) {
  %arr = alloca [8 x float], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call float @cq_theta_f32(float 0.0, double 5.000000e-01)
  %qi = fptosi float %q to i32
  %iq = sext i32 %qi to i64
  %g = getelementptr inbounds [8 x float], ptr %arr, i64 0, i64 %iq
  store float %q, ptr %g, align 4
  ret void
}

define void @s80(double %u0) {
  %arr = alloca [8 x x86_fp80], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 128, i1 false)
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK00000000000000000000, double 5.000000e-01)
  %qi = fptosi x86_fp80 %q to i32
  %iq = sext i32 %qi to i64
  %g = getelementptr inbounds [8 x x86_fp80], ptr %arr, i64 0, i64 %iq
  store x86_fp80 %q, ptr %g, align 16
  ret void
}

; CHECK:     call i32 @cqrt_qram_alloc_f16(i32 8)
; CHECK:     call void @cqrt_qram_store_f16(i32
; CHECK:     call void @cqrt_qram_store_f16_unc(i32
; CHECK:     call i32 @cqrt_qram_alloc_f32(i32 8)
; CHECK:     call void @cqrt_qram_store_f32(i32
; CHECK:     call void @cqrt_qram_store_f32_unc(i32
; CHECK:     call i32 @cqrt_qram_alloc_f80(i32 8)
; CHECK:     call void @cqrt_qram_store_f80(i32
; CHECK:     call void @cqrt_qram_store_f80_unc(i32
