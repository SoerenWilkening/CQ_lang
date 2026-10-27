; HAND-WRITTEN. Rules: 19, 18, 4, 5, 2.
; Checked: fp(x) with fp = which ? dbl : sq (measured).
; Clean: inside whichever clone runs: its arm value (copied out, then uncomputed).
; Kept: the user register x; the clone's copied-out result rail (measured).
; Rotations: Ry(th) on x.
; An INDIRECT CALL through a classical function pointer with a quantum argument (rule 19): the callee is not known
; until run time, but the SET of callees is static (the address-taken functions of that type in the module; clang's
; !callees metadata names them here). The call becomes a classical chain of pointer-equality tests over that set, each
; arm calling that callee's clone (06, rule 18) with the quantum argument; the result handle is merged by a classical
; phi (a handle is classical data, the slot-of-handles discipline of 31). A pointer outside the set is the program's
; UB and reaches unreachable. The classical originals stay for the classical select that picks the pointer. Each
; callee gets the clone for the mask the call needs.
source_filename = "indirect_call.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @indirect_call(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = icmp eq i32 %2, 0    ; IR: %5 = icmp eq i32 %2, 0  (classical)
  %6 = select i1 %5, ptr @sq, ptr @dbl    ; IR: %6 = select i1 %5, ptr @sq, ptr @dbl  (classical function pointer)
  %7 = icmp eq ptr %6, @sq    ; IR: %7 = call %6(%4): callee set {sq, dbl} from !callees; is it sq?
  br i1 %7, label %8, label %10    ; IR: %7: classical dispatch over the callee set
8:
  %9 = call fastcc i32 @__cq_q_sq_1(i32 %4)    ; IR: %7 = call @sq(%4), quantum clone of sq (arg 0 quantum)
  br label %15    ; IR: %7
10:
  %11 = icmp eq ptr %6, @dbl    ; IR: %7: is it dbl?
  br i1 %11, label %12, label %14    ; IR: %7: classical dispatch
12:
  %13 = call fastcc i32 @__cq_q_dbl_1(i32 %4)    ; IR: %7 = call @dbl(%4), quantum clone of dbl (arg 0 quantum)
  br label %15    ; IR: %7
14:
  unreachable    ; IR: %7: a pointer outside the callee set is the program's UB
15:
  %16 = phi i32 [ %9, %8 ], [ %13, %12 ]    ; IR: %7  [result handle, classical phi of handles]
  %17 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %17    ; IR: ret i32 %8
}

define internal i32 @dbl(i32 noundef %0) {
  %2 = shl nsw i32 %0, 1    ; IR: %2 = shl nsw i32 %0, 1  (classical original, kept for the classical pointer)
  ret i32 %2    ; IR: ret i32 %2
}

define internal i32 @sq(i32 noundef %0) {
  %2 = mul nsw i32 %0, %0    ; IR: %2 = mul nsw i32 %0, %0  (classical original, kept for the classical pointer)
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

define internal fastcc i32 @__cq_q_sq_1(i32 %0) {
  %2 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)    ; IR: %2 = mul nsw i32 %0, %0
  %3 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %2  [result rail of the call]
  call void @cqrt_copy_i32(i32 %2, i32 %3)    ; IR: ret i32 %2  [copy the result out]
  call void @cq_template_mul_i32_unc(i32 %2, i32 %0, i32 %0)    ; IR: uncompute %2
  call void @cqrt_free(i32 %2)    ; IR: release the %2 rail (|0>)
  ret i32 %3    ; IR: ret i32 %2
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
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
