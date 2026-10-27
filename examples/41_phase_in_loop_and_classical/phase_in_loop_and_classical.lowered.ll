; HAND-WRITTEN. Rules: 12, 8, 2.
; Checked: x (measured) in all three functions: phase_in_loop %5 -> %8, phase_under_classical %5 -> %9,
; phase_uncontrolled %4 -> %5.
; Clean: phase_in_loop's per-trip equality flag x == i (%11, uncomputed and freed every trip). The other two functions
; allocate no garbage rail.
; Kept: x in each function (the rotated register, measured).
; Rotations: phase_in_loop: (Ry, x, th, 1); then per trip i = 0..n-1: (P, flag, phi, x == i). phase_under_classical:
; (Ry, x, th, 1); the cq_phi is deleted. phase_uncontrolled: (Ry, x, th, 1); the cq_phi is deleted.
; Rule 12 (phase deletion is scope-dependent). phase_in_loop: a kickback rz_i1(flag, phi) per trip of the classical
; loop, the flag being the quantum predicate x == i of that trip. phase_under_classical and phase_uncontrolled: the
; cq_phi sits at top level with NO quantum predicate in scope at any call depth (only a classical condition, or none),
; so it is a global phase and is deleted (the classical branch stays, empty). The deletion is a property of the scope,
; not of the call: the same cq_phi inside a _ctl clone, or in a callee reached from a quantum arm, is rz_i1(pred, theta)
; on the enclosing quantum predicate (the callee witness is a new example, CONSTRUCTION_RULES 8 item 3).
source_filename = "phase_in_loop_and_classical.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @phase_in_loop(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = icmp sgt i32 %2, 0    ; IR: %6 = icmp sgt i32 %2, 0  (classical)
  br i1 %6, label %9, label %7    ; IR: br i1 %6

7:
  %8 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %8 = cq_measure_si32(%5)
  ret i32 %8    ; IR: ret i32 %8

9:
  %10 = phi i32 [ %12, %9 ], [ 0, %4 ]    ; IR: %10 = phi (classical trip counter)
  %11 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 %10)    ; IR: %11 = icmp eq i32 %5, %10
  call void @cqrt_rz_i1(i32 %11, double %3), !cq.branchphase !6    ; IR: block %12 under br i1 %11: cq_phi(%3)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %11, i32 %5, i32 %10)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  %12 = add nuw nsw i32 %10, 1    ; IR: %14 (classical)
  %13 = icmp eq i32 %12, %2    ; IR: %15 (classical)
  br i1 %13, label %7, label %9, !llvm.loop !7    ; IR: br i1 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @phase_under_classical(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %6 = icmp eq i32 %2, 0    ; IR: %6 (classical)
  br i1 %6, label %8, label %7    ; IR: br i1 %6

7:
  br label %8    ; IR: block %7: cq_phi(%3) under a classical condition is a global phase, deleted

8:
  %9 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %9 = cq_measure_si32(%5)
  ret i32 %9    ; IR: ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define i32 @phase_uncontrolled(i32 noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]; the unconditional cq_phi(%2) is a global phase, deleted
  %5 = call i32 @cqrt_measure_i32(i32 %4)    ; IR: %5 = cq_measure_si32(%4)
  ret i32 %5    ; IR: ret i32 %5
}

declare void @cqrt_rz_i1(i32, double)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare void @cqrt_not_i1(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{}
!7 = distinct !{!7, !8, !9}
!8 = !{!"llvm.loop.mustprogress"}
!9 = !{!"llvm.loop.unroll.disable"}
