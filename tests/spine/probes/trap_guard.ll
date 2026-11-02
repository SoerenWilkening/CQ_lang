; cq-nzlq (owner ruling 2026-11-02, CR rules 9, 14, 18): a classical integer division or remainder the
; lowering computes where the C program may not run it gets a safe divisor (select of 1 where the divisor
; is 0 or, signed, the pair is MIN / -1), so the host never traps on an input where C never divides:
; s3 a quantum arm (rule 9), s2b a case-3 masked trip, s4 the K trips of a quantum-exit loop, s5 a clone
; called unconditionally from a quantum arm (and its twin), s6 the MIN / -1 guard. s7 runs its divisions
; exactly where C does (the entry block, a case-1 loop): no guard. Every sdiv/srem below must read a
; %cq.safediv select: the counts of all divisions and of guarded ones are equal.
; CHECK-COUNT s3: sdiv i32 1
; CHECK-COUNT s3: sdiv i32 1000, %cq.safediv 1
; CHECK-COUNT s2b: sdiv i32 1
; CHECK-COUNT s2b: sdiv i32 1000, %cq.safediv 1
; CHECK-COUNT s4: sdiv i32 4
; CHECK-COUNT s4: sdiv i32 1000, %cq.safediv 4
; CHECK-COUNT __cq_q_g5_10: srem i32 1
; CHECK-COUNT __cq_q_g5_10: srem i32 1000, %cq.safediv 1
; CHECK-COUNT __cq_q_g5_10_unc: srem i32 1
; CHECK-COUNT __cq_q_g5_10_unc: srem i32 1000, %cq.safediv 1
; CHECK s6: %cq.divovf = and i1
; CHECK-COUNT s6: sdiv i32 1
; CHECK-COUNT s6: sdiv i32 %2, %cq.safediv 1
; CHECK-COUNT s7: cq.safediv 0
; CHECK-COUNT s7: sdiv i32 2
; USERCHECK s3
; USERCHECK s2b
; USERCHECK s4
; USERCHECK s5
; USERCHECK s6
; USERCHECK s7
source_filename = "tg.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @s3(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %3
  %8 = sdiv i32 1000, %2
  %9 = add nsw i32 %8, %4
  br label %10

10:                                               ; preds = %7, %3
  %11 = phi i32 [ %9, %7 ], [ 3, %3 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @s2b(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %2, 7
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %19, label %7

7:                                                ; preds = %3, %13
  %8 = phi i32 [ %17, %13 ], [ 0, %3 ]
  %9 = phi i32 [ %16, %13 ], [ 1, %3 ]
  %10 = shl nuw i32 1, %8
  %11 = and i32 %10, %4
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %19

13:                                               ; preds = %7
  %14 = sub nsw i32 3, %8
  %15 = sdiv i32 1000, %14
  %16 = add nsw i32 %15, %9
  %17 = add nuw nsw i32 %8, 1
  %18 = icmp eq i32 %17, %5
  br i1 %18, label %19, label %7, !llvm.loop !6

19:                                               ; preds = %13, %7, %3
  %20 = phi i32 [ 1, %3 ], [ %16, %13 ], [ %9, %7 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #4
  ret i32 %21
}

; Function Attrs: nounwind ssp uwtable
define i32 @s4(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %18, label %7

7:                                                ; preds = %3, %7
  %8 = phi i32 [ %15, %7 ], [ 0, %3 ]
  %9 = phi i32 [ %13, %7 ], [ 0, %3 ]
  %10 = phi i32 [ %14, %7 ], [ %4, %3 ]
  %11 = sub nsw i32 %2, %8
  %12 = sdiv i32 1000, %11
  %13 = add nsw i32 %12, %9
  %14 = ashr i32 %10, 1
  %15 = add nuw nsw i32 %8, 1
  %16 = and i32 %10, 2
  %17 = icmp eq i32 %16, 0
  br i1 %17, label %18, label %7, !llvm.loop !9

18:                                               ; preds = %7, %3
  %19 = phi i32 [ 0, %3 ], [ %13, %7 ]
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @s5(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %3
  %8 = tail call fastcc i32 @g5(i32 noundef %4, i32 noundef %2)
  br label %9

9:                                                ; preds = %7, %3
  %10 = phi i32 [ %8, %7 ], [ 3, %3 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #4
  ret i32 %11
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc i32 @g5(i32 noundef %0, i32 noundef %1) unnamed_addr #2 {
  %3 = srem i32 1000, %1
  %4 = add nsw i32 %3, %0
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define i32 @s6(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %4
  %9 = sdiv i32 %2, %3
  %10 = add nsw i32 %9, %5
  br label %11

11:                                               ; preds = %8, %4
  %12 = phi i32 [ %10, %8 ], [ 3, %4 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @s7(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  %6 = sdiv i32 1000, %2
  %7 = add nsw i32 %6, %5
  %8 = and i32 %3, 3
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %13

10:                                               ; preds = %13, %4
  %11 = phi i32 [ %7, %4 ], [ %18, %13 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  ret i32 %12

13:                                               ; preds = %4, %13
  %14 = phi i32 [ %19, %13 ], [ 0, %4 ]
  %15 = phi i32 [ %18, %13 ], [ %7, %4 ]
  %16 = add nsw i32 %14, %2
  %17 = sdiv i32 100, %16
  %18 = add nsw i32 %17, %15
  %19 = add nuw nsw i32 %14, 1
  %20 = icmp eq i32 %19, %8
  br i1 %20, label %10, label %13, !llvm.loop !10
}

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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
!10 = distinct !{!10, !7, !8}
