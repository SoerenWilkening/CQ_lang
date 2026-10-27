; HAND-WRITTEN. Rules: 24, 18, 9, 5, 2.
; Checked: r (measured): escaped ? -1 : inner(x, k) + 2.
; Clean: the arm value x*x + 1 + 2, the clone's result and escaped-flag rails (zeroed by the twin, then freed), and every
; rail inside the clone and its twin.
; Kept: the user register x; the merged result rail (measured).
; Rotations: Ry(th) on x.
; A longjmp under a quantum predicate is a MULTI-FRAME PREDICATED EARLY RETURN (rule 24), 24/35's early return carried
; across the call boundary: the callee's clone computes the longjmp arm's predicate as an ESCAPED flag rail beside its
; normal result (the normal arm's pure ops run unguarded, as every arm's do) and returns { result, escaped } (the
; aggregate ABI of 64); at the setjmp site the two continuations are the phi over the diamond, merged by a select on the
; escaped flag: setjmp's second return IS the escaped branch. Nested frames generalise it: every intermediate clone
; between the longjmp and its setjmp returns its own result beside an escaped flag that is the OR of its callees' flags
; and its own longjmp arms, and its continuation after each call is predicated on not-escaped exactly as 35's early
; return predicates the rest of a body. The host _setjmp/longjmp calls are NOT executed: the control transfer is what is
; lowered, and jb is a classical slot never written (the IR carries it as the global @jb). setjmp's return value on the
; escaped path is longjmp's classical argument (1 here; a quantum argument would be a rail selected by the flag); here
; -O1 already folded icmp eq %5, 0 into the diamond, so the flag is the whole of it. Any classical effect inside the
; longjmp arm would be a tape entry (47); this arm has none.
source_filename = "longjmp_quantum.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@jb = internal global [37 x i32] zeroinitializer, align 16    ; IR: @jb  (classical jmp_buf; never written: setjmp/longjmp are not executed)

define i32 @longjmp_quantum(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call fastcc { i32, i32 } @__cq_q_inner_10(i32 %4, i32 %2)    ; IR: %5 = setjmp(@jb) (not executed); %8 = call @inner(%4, %2), clone (arg 0 quantum): { result, escaped }
  %6 = extractvalue { i32, i32 } %5, 0    ; IR: %8  [result rail of the normal continuation]
  %7 = extractvalue { i32, i32 } %5, 1    ; IR: %6 = icmp eq i32 %5, 0 is false iff the callee longjmp'd  [escaped flag rail]
  %8 = call i32 @cq_template_add_i32_hl(i32 %6, i32 2)    ; IR: %9 = add nsw i32 %8, 2  (the normal continuation, unguarded)
  %9 = call i32 @cq_template_select_i32_lh(i32 %7, i32 -1, i32 %8)    ; IR: %11 = phi [%9, %7], [-1, %3]: escaped ? -1 : %9  [result rail]
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %6, i32 2)    ; IR: uncompute %9
  call void @cqrt_free(i32 %8)    ; IR: release the %9 rail (|0>)
  call fastcc void @__cq_q_inner_10_unc(i32 %6, i32 %7, i32 %4, i32 %2)    ; IR: uncompute %8 and the escaped flag (adjoint of the call)
  call void @cqrt_free(i32 %6)    ; IR: release the %8 rail (|0>)
  call void @cqrt_free(i32 %7)    ; IR: release the escaped flag (|0>)
  %10 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %12 = cq_measure_si32(%11)
  ret i32 %10    ; IR: ret i32 %12
}

define internal fastcc { i32, i32 } @__cq_q_inner_10(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %0, i32 %1)    ; IR: %3 = icmp sgt i32 %0, %1  [predicate of block %4: longjmp(@jb, 1) fires iff set; the host call is not executed]
  %4 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)    ; IR: %6 = mul nsw i32 %0, %0  (block %5, unguarded)
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)    ; IR: %7 = add nuw nsw i32 %6, 1
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %7  [result rail of the call]
  call void @cqrt_copy_i32(i32 %5, i32 %6)    ; IR: ret i32 %7  [copy the result out]
  %7 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: block %4 taken  [escaped flag rail of the call]
  call void @cqrt_copy_i1(i32 %3, i32 %7)    ; IR: copy the escaped flag out
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %4, i32 1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %5)    ; IR: release the %7 rail (|0>)
  call void @cq_template_mul_i32_unc(i32 %4, i32 %0, i32 %0)    ; IR: uncompute %6
  call void @cqrt_free(i32 %4)    ; IR: release the %6 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %3, i32 %0, i32 %1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  %8 = insertvalue { i32, i32 } poison, i32 %6, 0    ; IR: ret i32 %7: the result handle
  %9 = insertvalue { i32, i32 } %8, i32 %7, 1    ; IR: the escaped-flag handle (setjmp's second return)
  ret { i32, i32 } %9    ; IR: ret i32 %7
}

define internal fastcc void @__cq_q_inner_10_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 %3)    ; IR: recompute %3
  %6 = call i32 @cq_template_mul_i32(i32 %2, i32 %2)    ; IR: recompute %6
  %7 = call i32 @cq_template_add_i32_hl(i32 %6, i32 1)    ; IR: recompute %7
  call void @cqrt_copy_i32(i32 %7, i32 %0)    ; IR: ret i32 %7  [xor the result out of %out]
  call void @cqrt_copy_i1(i32 %5, i32 %1)    ; IR: xor the escaped flag out of %oesc
  call void @cq_template_add_i32_hl_unc(i32 %7, i32 %6, i32 1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  call void @cq_template_mul_i32_unc(i32 %6, i32 %2, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %6)    ; IR: release the %6 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %5, i32 %2, i32 %3)    ; IR: uncompute %3
  call void @cqrt_free(i32 %5)    ; IR: release the %3 rail (|0>)
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_copy_i1(i32, i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
