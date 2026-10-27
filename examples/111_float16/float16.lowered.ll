; HAND-WRITTEN. Rules: 25, 3, 4, 18, 5, 2.
; Checked: (float)twice16(h) with h = (_Float16)(f * c + 1) (measured).
; Clean: the half rail h, its promotion, the product and sum rails of the unfused fmuladd, the half result of the
; arithmetic, the clone's result rail (zeroed by the twin, then freed), and every rail inside the clone and its twin.
; Kept: the user register f; the result rail (measured).
; Rotations: Ry(th) on f.
; C23 _Float16 reaches -O1 IR as the native half type. On x86-64 clang promotes half arithmetic to float: every op is
; fpext half->float, the float op, fptrunc float->half; only an op inside a function whose ABI keeps half (the callee
; twice16) stays a half op (fadd half). half is one more FP width (rule 25): cq_template_fptrunc_f32_to_f16 /
; fpext_f16_to_f32 are width variants of 19's casts, fadd_f16 of 13's templates, cqrt_alloc_f16/copy_f16 of the handle
; ABI; fmuladd.f32 is UNFUSED (§2, cf. 14): fmul_f32_hl(h, c) into a product rail, then fadd_f32_hl(product, 1.0); the
; product is uncomputed after the sum it fed (rule 5). The clone of twice16 takes and returns half handles (06/07's
; copy-out, rule 18). Everything but f and the measured rail is uncomputed.
source_filename = "float16.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define float @float16_q(float noundef %0, double noundef %1, float noundef %2) {
  %4 = call i32 @cqrt_alloc_f32(float %0)    ; IR: %4 = cq_theta_f32(%0, %1)  [register f]
  call void @cqrt_ry_f32(i32 %4, double %1)    ; IR: %4 = cq_theta_f32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_fptrunc_f32_to_f16(i32 %4)    ; IR: %5 = fptrunc float %4 to half  [h: a 16-bit rail]
  %6 = call i32 @cq_template_fpext_f16_to_f32(i32 %5)    ; IR: %6 = fpext half %5 to float  (promotion for the arithmetic)
  %7 = fptrunc float %2 to half    ; IR: %7 = fptrunc float %2 to half  (classical)
  %8 = fpext half %7 to float    ; IR: %8 = fpext half %7 to float  (classical)
  %9 = call i32 @cq_template_fmul_f32_hl(i32 %6, float %8)    ; IR: %9 = llvm.fmuladd.f32(%6, %8, 1.0)  [unfused product h * c]
  %10 = call i32 @cq_template_fadd_f32_hl(i32 %9, float 1.000000e+00)    ; IR: %9 = llvm.fmuladd.f32(%6, %8, 1.0)  [unfused sum + 1]
  %11 = call i32 @cq_template_fptrunc_f32_to_f16(i32 %10)    ; IR: %10 = fptrunc float %9 to half  (back to _Float16)
  %12 = call fastcc i32 @__cq_q_twice16_1(i32 %11)    ; IR: %11 = call @twice16(%10), clone (arg 0 quantum)  [half result rail]
  %13 = call i32 @cq_template_fpext_f16_to_f32(i32 %12)    ; IR: %12 = fpext half %11 to float  [result rail]
  call fastcc void @__cq_q_twice16_1_unc(i32 %12, i32 %11)    ; IR: uncompute %11 (adjoint of the call)
  call void @cqrt_free(i32 %12)    ; IR: release the %11 rail (|0>)
  call void @cq_template_fptrunc_f32_to_f16_unc(i32 %11, i32 %10)    ; IR: uncompute %10
  call void @cqrt_free(i32 %11)    ; IR: release the %10 rail (|0>)
  call void @cq_template_fadd_f32_hl_unc(i32 %10, i32 %9, float 1.000000e+00)    ; IR: uncompute %9  [sum]
  call void @cqrt_free(i32 %10)    ; IR: release the %9 rail (|0>)
  call void @cq_template_fmul_f32_hl_unc(i32 %9, i32 %6, float %8)    ; IR: uncompute %9  [product]
  call void @cqrt_free(i32 %9)    ; IR: release the product rail (|0>)
  call void @cq_template_fpext_f16_to_f32_unc(i32 %6, i32 %5)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_fptrunc_f32_to_f16_unc(i32 %5, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %14 = call float @cqrt_measure_f32(i32 %13)    ; IR: %13 = cq_measure_f32(%12)
  ret float %14    ; IR: ret float %13
}

define internal fastcc i32 @__cq_q_twice16_1(i32 %0) {
  %2 = call i32 @cq_template_fadd_f16(i32 %0, i32 %0)    ; IR: %2 = fadd half %0, %0  (a half op: the callee's ABI keeps half)
  %3 = call i32 @cqrt_alloc_f16(half 0xH0000)    ; IR: ret half %2  [result rail of the call]
  call void @cqrt_copy_f16(i32 %2, i32 %3)    ; IR: ret half %2  [copy the result out]
  call void @cq_template_fadd_f16_unc(i32 %2, i32 %0, i32 %0)    ; IR: uncompute %2
  call void @cqrt_free(i32 %2)    ; IR: release the %2 rail (|0>)
  ret i32 %3    ; IR: ret half %2
}

define internal fastcc void @__cq_q_twice16_1_unc(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_fadd_f16(i32 %1, i32 %1)    ; IR: recompute %2
  call void @cqrt_copy_f16(i32 %3, i32 %0)    ; IR: ret half %2  [xor the result out of %out]
  call void @cq_template_fadd_f16_unc(i32 %3, i32 %1, i32 %1)    ; IR: uncompute %2
  call void @cqrt_free(i32 %3)    ; IR: release the %2 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_f32(float)
declare void @cqrt_ry_f32(i32, double)
declare float @cqrt_measure_f32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_alloc_f16(half)
declare void @cqrt_copy_f16(i32, i32)
declare i32 @cq_template_fptrunc_f32_to_f16(i32)
declare void @cq_template_fptrunc_f32_to_f16_unc(i32, i32)
declare i32 @cq_template_fpext_f16_to_f32(i32)
declare void @cq_template_fpext_f16_to_f32_unc(i32, i32)
declare i32 @cq_template_fmul_f32_hl(i32, float)
declare void @cq_template_fmul_f32_hl_unc(i32, i32, float)
declare i32 @cq_template_fadd_f32_hl(i32, float)
declare void @cq_template_fadd_f32_hl_unc(i32, i32, float)
declare i32 @cq_template_fadd_f16(i32, i32)
declare void @cq_template_fadd_f16_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
