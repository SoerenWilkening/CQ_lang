; HAND-WRITTEN. Rules: 2, 4, 5, 9, 13, 18, 19, 20.
; Checked: fps[x & 1](c + x) (the select's result %11 -> %12).
; Clean: the index rail x & 1 (%5), the callee tag (%6, a QROM read), the argument c + x (%7), the dbl flag (%8), both
; clones' result rails (%9, %10, zeroed by their _unc twins), all freed; inside each clone its chain.
; Kept: x (%4, the rotated register) and the result (%11, measured).
; Rotations: (Ry, x, th, 1).
; A FUNCTION POINTER LOADED AT A QUANTUM INDEX: a pointer to a function is a fat pointer whose object is the function (84:
; tag = the function's number in the module's address-taken set, dbl = 1, sq = 2; idx = 0 always), so the constant table
; @fps becomes a derived constant table of tags (@fps.cqtag) and the load is a QROM (29) yielding the callee tag as a rail;
; its index is the logical index rail x & 1 (i32; -O1's zext to i64 and the gep scaling are address arithmetic and are not
; emitted, rule 20). The call is quantum-controlled callee selection, the switch over clones of 22: an equality flag per
; candidate on the tag, each candidate's clone called unguarded with the quantum argument (a value computed under a false
; flag is read by nothing), the results merged by select (rule 9). The tag is a QROM read of a table holding only the tags
; {1, 2}, so there is no other case: like a switch with an unreachable default (rule 13) the last candidate, sq, gets no
; flag and is the complement, the innermost select arm (131, 135). Both clones' results, the flag, the tag and the index
; are uncomputed in reverse; the clone results through their _unc twins (07).
source_filename = "quantum_fnptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@fps = internal unnamed_addr constant [2 x ptr] [ptr @dbl, ptr @sq], align 16    ; IR: @fps  (classical original)
@fps.cqtag = private unnamed_addr constant [2 x i32] [i32 1, i32 2], align 16    ; IR: @fps as callee tags: dbl = 1, sq = 2

define i32 @quantum_fnptr(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 1)    ; IR: %5 = and i32 %4, 1
  %6 = call i32 @cq_template_qrom_load_i32(ptr @fps.cqtag, i64 2, i32 %5)    ; IR: %6 = zext %5; %7 = getelementptr @fps, 0, %6; %8 = load ptr, ptr %7  [the callee's tag, a QROM over the tag table, index = the logical-i32 rail %5]
  %7 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %2)    ; IR: %9 = add nsw i32 %4, %2
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 1)    ; IR: %10 = call %8(%9): candidate dbl iff tag == 1 (sq, the last candidate, needs no flag: the tag is one of {1, 2}, rule 13)
  %9 = call fastcc i32 @__cq_q_dbl_1(i32 %7)    ; IR: %10 = call @dbl(%9), quantum clone of dbl (arg 0 quantum), unguarded
  %10 = call fastcc i32 @__cq_q_sq_1(i32 %7)    ; IR: %10 = call @sq(%9), quantum clone of sq (arg 0 quantum), unguarded
  %11 = call i32 @cq_template_select_i32(i32 %8, i32 %9, i32 %10)    ; IR: %10: dbl's result, else sq's (the complement arm, innermost)  [result rail]
  call fastcc void @__cq_q_sq_1_unc(i32 %10, i32 %7)    ; IR: uncompute sq's result (adjoint of the call)
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call fastcc void @__cq_q_dbl_1_unc(i32 %9, i32 %7)    ; IR: uncompute dbl's result (adjoint of the call)
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %6, i32 1)    ; IR: uncompute the dbl flag
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %7, i32 %4, i32 %2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %7)    ; IR: release the %9 rail (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %6, ptr @fps.cqtag, i64 2, i32 %5)    ; IR: uncompute the callee tag %8
  call void @cqrt_free(i32 %6)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %12 = call i32 @cqrt_measure_i32(i32 %11)    ; IR: %11 = cq_measure_si32(%10)
  ret i32 %12    ; IR: ret i32 %11
}

define internal i32 @dbl(i32 noundef %0) {
  %2 = shl nsw i32 %0, 1    ; IR: %2 = shl nsw i32 %0, 1  (classical original, referenced by @fps)
  ret i32 %2    ; IR: ret i32 %2
}

define internal i32 @sq(i32 noundef %0) {
  %2 = mul nsw i32 %0, %0    ; IR: %2 = mul nsw i32 %0, %0  (classical original, referenced by @fps)
  ret i32 %2    ; IR: ret i32 %2
}

define internal fastcc i32 @__cq_q_dbl_1(i32 %0) {
  %2 = call i32 @cq_template_shl_i32_hl(i32 %0, i32 1)    ; IR: %2 = shl nsw i32 %0, 1
  %3 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %2  [result rail of the call]
  call void @cqrt_copy_i32(i32 %2, i32 %3)    ; IR: ret i32 %2  [copy the result out]
  call void @cq_template_shl_i32_hl_unc(i32 %2, i32 %0, i32 1)    ; IR: uncompute %2
  call void @cqrt_free(i32 %2)    ; IR: release the %2 rail (|0>)
  ret i32 %3    ; IR: ret i32 %2
}

define internal fastcc void @__cq_q_dbl_1_unc(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_shl_i32_hl(i32 %1, i32 1)    ; IR: recompute %2
  call void @cqrt_copy_i32(i32 %3, i32 %0)    ; IR: ret i32 %2  [xor the result out of %out]
  call void @cq_template_shl_i32_hl_unc(i32 %3, i32 %1, i32 1)    ; IR: uncompute %2
  call void @cqrt_free(i32 %3)    ; IR: release the %2 rail (|0>)
  ret void
}

define internal fastcc i32 @__cq_q_sq_1(i32 %0) {
  %2 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)    ; IR: %2 = mul nsw i32 %0, %0
  %3 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %2  [result rail of the call]
  call void @cqrt_copy_i32(i32 %2, i32 %3)    ; IR: ret i32 %2  [copy the result out]
  call void @cq_template_mul_i32_unc(i32 %2, i32 %0, i32 %0)    ; IR: uncompute %2
  call void @cqrt_free(i32 %2)    ; IR: release the %2 rail (|0>)
  ret i32 %3    ; IR: ret i32 %2
}

define internal fastcc void @__cq_q_sq_1_unc(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_mul_i32(i32 %1, i32 %1)    ; IR: recompute %2
  call void @cqrt_copy_i32(i32 %3, i32 %0)    ; IR: ret i32 %2  [xor the result out of %out]
  call void @cq_template_mul_i32_unc(i32 %3, i32 %1, i32 %1)    ; IR: uncompute %2
  call void @cqrt_free(i32 %3)    ; IR: release the %2 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cq_template_qrom_load_i32_unc(i32, ptr, i64, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}
!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
