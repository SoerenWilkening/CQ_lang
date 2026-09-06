; lowering_reject_inplace_rail_stale_w1_xor_bareout.ll — DECLINE. bd
; test_C_libtooling-eqpx (P1). W1 (`emitBreakForward`, `LoopLowering.cpp:1698`) x
; the BARE 6.5 `%out` — the (writer x immediate-class) cell that shows the E1
; growth event (`lowerControlRegions`, `CQLoweringPass.cpp:376`) reaches the break
; path too, with no derivation anywhere in the program.
;
;     int ext_f(int a);                        /* a second TU: `return a+100;` */
;     __attribute__((noinline))
;     int run(int seed, int pseed, int n) {
;         int p = cq_theta(pseed, 0.5);
;         int y = 5; if (p > 5) y = ext_f(7);  /* 6.5 CLASSICAL-CALL ARM -> %out */
;         int q = cq_theta(seed, 0.25);
;         for (int i = 0; i < n; i++) { q = q ^ y; if ((q & 1) == 0) break; }
;         return cq_measure(q) + cq_measure(y); }
;
; `clang -O1`, two TUs `llvm-link`ed, `@main` dropped. `!llvm.loop` VERBATIM.
;
; MEASURED on frozen `main`@16b15b3 (byte-identical on the oracle 52d7764):
;     %out = call i32 @cqrt_alloc_i32(i32 0)
;     call void @cqrt_xorc_i32(i32 %h2, i32 %out)   ; forward      <- RAIL IN IMM
;     call void @cqrt_xorc_i32(i32 %h2, i32 %out)   ; reverse-play <- RAIL IN IMM
; `opt` exit 0, verify-clean, 222 trace lines.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: in-place rail op no longer provable at lowering

; CHECK-NOT: cqrt_xorc_i32
; CHECK-NOT: cq_template_xor_i32

; ⭐ MEASURED, AND THIS IS THE CELL'S POINT: EXACTLY ONE diagnostic — ours — and
; `opt` rc 1. `lowerBreakReversePlay` (`CQLoweringPass.cpp:543`) still walks this
; module AFTER our Phase-1 `continue` left the marked `xor` un-lowered, and it
; prints NOTHING; there is no crash and no `LLVM ERROR`. A second diagnostic after
; ours would be acceptable (the module lowers nothing either way); these three
; negatives exist so that if one ever starts firing, a human is told rather than
; the change passing as green.
; CHECK-NOT: break reverse-play could not re-derive the lowered body
; CHECK-NOT: break reverse-play cannot invert a lowered body gate
; CHECK-NOT: break reverse-play cannot re-emit an uncollected body value

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @run(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #4
  %5 = icmp sgt i32 %4, 5
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  %7 = tail call i32 @ext_f(i32 noundef 7) #4
  br label %8

8:                                                ; preds = %6, %3
  %9 = phi i32 [ %7, %6 ], [ 5, %3 ]
  %10 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #4
  %11 = icmp sgt i32 %2, 0
  br i1 %11, label %12, label %21

12:                                               ; preds = %12, %8
  %13 = phi i32 [ %18, %12 ], [ 0, %8 ]
  %14 = phi i32 [ %15, %12 ], [ %10, %8 ]
  %15 = xor i32 %14, %9
  %16 = and i32 %15, 1
  %17 = icmp eq i32 %16, 0
  %18 = add nuw nsw i32 %13, 1
  %19 = icmp eq i32 %18, %2
  %20 = select i1 %17, i1 true, i1 %19
  br i1 %20, label %21, label %12, !llvm.loop !6

21:                                               ; preds = %12, %8
  %22 = phi i32 [ %10, %8 ], [ %15, %12 ]
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #4
  %24 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %25 = add nsw i32 %24, %23
  ret i32 %25
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #3 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
