; control_swap_select_cascade_conddepth10.ll — ACCEPT (3c6m.14 L6 Inc 1 substrate pin): DEPTH-10 tainted-select CONDITION cascade (each select result feeds the NEXT select's compare — the onward-control round-2 fixpoint path) — the substrate-depth pin PredMux relies on (PRD-3c6m.14 §2.3, probe p13). No pass change: lowers TODAY.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/6bcd983c-9a80-4c97-97bc-997169d91fe1/scratchpad/probes/p13_depth10_cond.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/6bcd983c-9a80-4c97-97bc-997169d91fe1/scratchpad/probes/p13_depth10_cond.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @probe() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = icmp sgt i32 %1, 2
  %3 = add nsw i32 %1, 1
  %4 = xor i32 %1, 3
  %5 = select i1 %2, i32 %3, i32 %4
  %6 = icmp sgt i32 %5, 3
  %7 = add nsw i32 %5, 1
  %8 = xor i32 %5, 3
  %9 = select i1 %6, i32 %7, i32 %8
  %10 = icmp sgt i32 %9, 4
  %11 = add nsw i32 %9, 1
  %12 = xor i32 %9, 3
  %13 = select i1 %10, i32 %11, i32 %12
  %14 = icmp sgt i32 %13, 5
  %15 = add nsw i32 %13, 1
  %16 = xor i32 %13, 3
  %17 = select i1 %14, i32 %15, i32 %16
  %18 = icmp sgt i32 %17, 6
  %19 = add nsw i32 %17, 1
  %20 = xor i32 %17, 3
  %21 = select i1 %18, i32 %19, i32 %20
  %22 = icmp sgt i32 %21, 7
  %23 = add nsw i32 %21, 1
  %24 = xor i32 %21, 3
  %25 = select i1 %22, i32 %23, i32 %24
  %26 = icmp sgt i32 %25, 8
  %27 = add nsw i32 %25, 1
  %28 = xor i32 %25, 3
  %29 = select i1 %26, i32 %27, i32 %28
  %30 = icmp sgt i32 %29, 9
  %31 = add nsw i32 %29, 1
  %32 = xor i32 %29, 3
  %33 = select i1 %30, i32 %31, i32 %32
  %34 = icmp sgt i32 %33, 10
  %35 = add nsw i32 %33, 1
  %36 = xor i32 %33, 3
  %37 = select i1 %34, i32 %35, i32 %36
  %38 = icmp sgt i32 %37, 11
  %39 = add nsw i32 %37, 1
  %40 = xor i32 %37, 3
  %41 = select i1 %38, i32 %39, i32 %40
  %42 = tail call i32 @cq_measure_si32(i32 noundef %41) #2
  ret i32 %42
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}

; 10 selects, each lowering to a 2-copy controlled-XOR merge:
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call i32 @cqrt_measure_i32(
; CHECK-NOT: select i1
