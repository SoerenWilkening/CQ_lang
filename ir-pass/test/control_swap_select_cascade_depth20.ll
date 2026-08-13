; control_swap_select_cascade_depth20.ll — ACCEPT (3c6m.14 L6 Inc 1 substrate pin): DEPTH-20 straight-line tainted-select DATA cascade (each select data-feeds the next) — the substrate-depth pin PredMux relies on (PRD-3c6m.14 §2.3, probe p12). No pass change: this lowers TODAY and must keep lowering.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/6bcd983c-9a80-4c97-97bc-997169d91fe1/scratchpad/probes/p12_depth20_data.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/6bcd983c-9a80-4c97-97bc-997169d91fe1/scratchpad/probes/p12_depth20_data.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @probe() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = add nsw i32 %1, 1
  %3 = icmp sgt i32 %1, 0
  %4 = add nsw i32 %1, 2
  %5 = xor i32 %2, 3
  %6 = select i1 %3, i32 %4, i32 %5
  %7 = icmp sgt i32 %1, 1
  %8 = add nsw i32 %6, 2
  %9 = xor i32 %6, 4
  %10 = select i1 %7, i32 %8, i32 %9
  %11 = icmp sgt i32 %1, 2
  %12 = add nsw i32 %10, 3
  %13 = xor i32 %10, 5
  %14 = select i1 %11, i32 %12, i32 %13
  %15 = icmp sgt i32 %1, 3
  %16 = add nsw i32 %14, 4
  %17 = xor i32 %14, 6
  %18 = select i1 %15, i32 %16, i32 %17
  %19 = icmp sgt i32 %1, 4
  %20 = add nsw i32 %18, 5
  %21 = xor i32 %18, 7
  %22 = select i1 %19, i32 %20, i32 %21
  %23 = icmp sgt i32 %1, 5
  %24 = add nsw i32 %22, 6
  %25 = xor i32 %22, 8
  %26 = select i1 %23, i32 %24, i32 %25
  %27 = icmp sgt i32 %1, 6
  %28 = add nsw i32 %26, 7
  %29 = xor i32 %26, 9
  %30 = select i1 %27, i32 %28, i32 %29
  %31 = icmp sgt i32 %1, 7
  %32 = add nsw i32 %30, 8
  %33 = xor i32 %30, 10
  %34 = select i1 %31, i32 %32, i32 %33
  %35 = icmp sgt i32 %1, 8
  %36 = add nsw i32 %34, 9
  %37 = xor i32 %34, 11
  %38 = select i1 %35, i32 %36, i32 %37
  %39 = icmp sgt i32 %1, 9
  %40 = add nsw i32 %38, 10
  %41 = xor i32 %38, 12
  %42 = select i1 %39, i32 %40, i32 %41
  %43 = icmp sgt i32 %1, 10
  %44 = add nsw i32 %42, 11
  %45 = xor i32 %42, 13
  %46 = select i1 %43, i32 %44, i32 %45
  %47 = icmp sgt i32 %1, 11
  %48 = add nsw i32 %46, 12
  %49 = xor i32 %46, 14
  %50 = select i1 %47, i32 %48, i32 %49
  %51 = icmp sgt i32 %1, 12
  %52 = add nsw i32 %50, 13
  %53 = xor i32 %50, 15
  %54 = select i1 %51, i32 %52, i32 %53
  %55 = icmp sgt i32 %1, 13
  %56 = add nsw i32 %54, 14
  %57 = xor i32 %54, 16
  %58 = select i1 %55, i32 %56, i32 %57
  %59 = icmp sgt i32 %1, 14
  %60 = add nsw i32 %58, 15
  %61 = xor i32 %58, 17
  %62 = select i1 %59, i32 %60, i32 %61
  %63 = icmp sgt i32 %1, 15
  %64 = add nsw i32 %62, 16
  %65 = xor i32 %62, 18
  %66 = select i1 %63, i32 %64, i32 %65
  %67 = icmp sgt i32 %1, 16
  %68 = add nsw i32 %66, 17
  %69 = xor i32 %66, 19
  %70 = select i1 %67, i32 %68, i32 %69
  %71 = icmp sgt i32 %1, 17
  %72 = add nsw i32 %70, 18
  %73 = xor i32 %70, 20
  %74 = select i1 %71, i32 %72, i32 %73
  %75 = icmp sgt i32 %1, 18
  %76 = add nsw i32 %74, 19
  %77 = xor i32 %74, 21
  %78 = select i1 %75, i32 %76, i32 %77
  %79 = icmp sgt i32 %1, 19
  %80 = add nsw i32 %78, 20
  %81 = xor i32 %78, 22
  %82 = select i1 %79, i32 %80, i32 %81
  %83 = tail call i32 @cq_measure_si32(i32 noundef %82) #2
  ret i32 %83
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

; 20 selects, each lowering to a 2-copy controlled-XOR merge:
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
