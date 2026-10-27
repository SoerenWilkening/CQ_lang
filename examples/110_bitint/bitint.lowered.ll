; HAND-WRITTEN. Rules: 25, 1, 4, 3, 18, 5, 2.
; Checked: bitint_u100: (unsigned long)(a >> 36) (measured, the trunc rail %11 -> %12); bitint_s7: (int)bump7(x, k)
; (measured, the sext rail %8 -> %9).
; Clean: bitint_u100: the i100 zext of x (%5), the product (%7), the shifted copy (%8), the sum (%9) and the final shift
; (%10), uncomputed in LIFO order and freed; bitint_s7: the i7 trunc of x (%5) and the clone's copied-out i7 result (%7,
; zeroed by the __cq_q_bump7_10_unc twin), both freed; the clone-internal sum rail.
; Kept: x (%4 in both functions: the rotated 64-bit user register).
; Rotations: (Ry, x, th, 1) in each of the two functions (an i64 Ry).
; C23 _BitInt(N) reaches -O1 IR as the native iN types (i100, i7), with the ordinary opcodes and casts on them. RULE: the handle ABI is
; width-only, so a template exists for EVERY width N on demand: cq_template_<op>_i<N>[_hl|_lh], cq_template_zext_i<M>_to_i<N>,
; cq_template_trunc_i<N>_to_i<M>, cqrt_alloc_i<N>/cqrt_copy_i<N>; the runtime's width set is a generator parameter, not a
; limit; signedness stays in the opcode (lshr/ashr, sext/zext) as always; a classical iN operand is passed as an iN literal.
; The user register is the i64 x (cq_theta has no _BitInt overload); the i100 rails are minted by the zext template.
; bitint_u100: all arithmetic is i100 (mul, lshr, add), then a trunc to i64 for the measurement. bitint_s7: clang keeps
; _BitInt(7) as i7 only across the call boundary (it would otherwise widen to i32 with shl/ashr); the clone of bump7 takes
; two i7 handles (signext is an ABI note on classical i7 values, the rail is 7 wide) and returns an i7 handle through
; the copy-out ABI of 06/07; the sext to i32 is the cast template. Everything but x and the measured rail is uncomputed.
source_filename = "bitint.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i64 @bitint_u100(i64 noundef %0, double noundef %1, i64 noundef %2) {
  %4 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %4 = cq_theta_ul(%0, %1)  [register x, 64 bits]
  call void @cqrt_ry_i64(i32 %4, double %1)    ; IR: %4 = cq_theta_ul(%0, %1)  [Ry]
  %5 = call i32 @cq_template_zext_i64_to_i100(i32 %4)    ; IR: %5 = zext i64 %4 to i100  [a: a fresh 100-bit rail]
  %6 = zext i64 %2 to i100    ; IR: %6 = zext i64 %2 to i100  (classical)
  %7 = call i32 @cq_template_mul_i100_hl(i32 %5, i100 %6)    ; IR: %7 = mul i100 %5, %6
  %8 = call i32 @cq_template_lshr_i100_hl(i32 %5, i100 7)    ; IR: %8 = lshr i100 %5, 7
  %9 = call i32 @cq_template_add_i100(i32 %7, i32 %8)    ; IR: %9 = add i100 %7, %8
  %10 = call i32 @cq_template_lshr_i100_hl(i32 %9, i100 36)    ; IR: %10 = lshr i100 %9, 36
  %11 = call i32 @cq_template_trunc_i100_to_i64(i32 %10)    ; IR: %11 = trunc nuw i100 %10 to i64  [result rail]
  call void @cq_template_lshr_i100_hl_unc(i32 %10, i32 %9, i100 36)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (|0>)
  call void @cq_template_add_i100_unc(i32 %9, i32 %7, i32 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cq_template_lshr_i100_hl_unc(i32 %8, i32 %5, i100 7)    ; IR: uncompute %8
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i100_hl_unc(i32 %7, i32 %5, i100 %6)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_zext_i64_to_i100_unc(i32 %5, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %12 = call i64 @cqrt_measure_i64(i32 %11)    ; IR: %12 = cq_measure_ul(%11)
  ret i64 %12    ; IR: ret i64 %12
}

define i32 @bitint_s7(i64 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %4 = cq_theta_ul(%0, %1)  [register x, 64 bits]
  call void @cqrt_ry_i64(i32 %4, double %1)    ; IR: %4 = cq_theta_ul(%0, %1)  [Ry]
  %5 = call i32 @cq_template_trunc_i64_to_i7(i32 %4)    ; IR: %5 = trunc i64 %4 to i7  [a 7-bit rail]
  %6 = trunc i32 %2 to i7    ; IR: %6 = trunc i32 %2 to i7  (classical)
  %7 = call fastcc i32 @__cq_q_bump7_10(i32 %5, i7 %6)    ; IR: %7 = call @bump7(%5, %6), clone (arg 0 quantum)  [i7 result rail]
  %8 = call i32 @cq_template_sext_i7_to_i32(i32 %7)    ; IR: %8 = sext i7 %7 to i32  [result rail]
  call fastcc void @__cq_q_bump7_10_unc(i32 %7, i32 %5, i7 %6)    ; IR: uncompute %7 (adjoint of the call)
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_trunc_i64_to_i7_unc(i32 %5, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %9    ; IR: ret i32 %9
}

define internal fastcc i32 @__cq_q_bump7_10(i32 %0, i7 %1) {
  %3 = call i32 @cq_template_add_i7_hl(i32 %0, i7 %1)    ; IR: %3 = add nsw i7 %1, %0  (commutative: the quantum operand first)
  %4 = call i32 @cqrt_alloc_i7(i7 0)    ; IR: ret i7 %3  [result rail of the call]
  call void @cqrt_copy_i7(i32 %3, i32 %4)    ; IR: ret i7 %3  [copy the result out]
  call void @cq_template_add_i7_hl_unc(i32 %3, i32 %0, i7 %1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret i32 %4    ; IR: ret i7 %3
}

define internal fastcc void @__cq_q_bump7_10_unc(i32 %0, i32 %1, i7 %2) {
  %4 = call i32 @cq_template_add_i7_hl(i32 %1, i7 %2)    ; IR: recompute %3
  call void @cqrt_copy_i7(i32 %4, i32 %0)    ; IR: ret i7 %3  [xor the result out of %out]
  call void @cq_template_add_i7_hl_unc(i32 %4, i32 %1, i7 %2)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i64(i32, double)
declare i64 @cqrt_measure_i64(i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_alloc_i7(i7)
declare void @cqrt_copy_i7(i32, i32)
declare i32 @cq_template_zext_i64_to_i100(i32)
declare void @cq_template_zext_i64_to_i100_unc(i32, i32)
declare i32 @cq_template_mul_i100_hl(i32, i100)
declare void @cq_template_mul_i100_hl_unc(i32, i32, i100)
declare i32 @cq_template_lshr_i100_hl(i32, i100)
declare void @cq_template_lshr_i100_hl_unc(i32, i32, i100)
declare i32 @cq_template_add_i100(i32, i32)
declare void @cq_template_add_i100_unc(i32, i32, i32)
declare i32 @cq_template_trunc_i100_to_i64(i32)
declare i32 @cq_template_trunc_i64_to_i7(i32)
declare void @cq_template_trunc_i64_to_i7_unc(i32, i32)
declare i32 @cq_template_sext_i7_to_i32(i32)
declare i32 @cq_template_add_i7_hl(i32, i7)
declare void @cq_template_add_i7_hl_unc(i32, i32, i7)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
