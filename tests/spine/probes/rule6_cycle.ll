; /* tests/spine probe (CR rule 6, cq-4wbdf, cq-f725): a cycle that runs through another rail's clean-up. In cyc_arm,
;  * s = sext x + a and then s + u, u a select under the quantum test x & 1: rule 6 would clean sext x against s and s
;  * against s + u, but u's uncompute reads x & 1, which reads sext x. No order frees all three; the clean-up of sext x
;  * gives way to its plain item and s is cleaned against the sum. cyc_mem: cq-f725's program (-O1 makes the same shape). */
; Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I CQ_spec -include CQ.h rule6_cycle.c (this header kept)
; USERCHECK cyc_arm
; USERCHECK cyc_mem
; CHECK-COUNT cyc_arm: call void @cqrt_copy_i32( 1
; ModuleID = 'rule6_cycle.c'
source_filename = "rule6_cycle.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @cyc_arm(i8 noundef signext %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef %1) #3
  %6 = sext i8 %5 to i32
  %7 = and i32 %6, 1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %11, label %9

9:                                                ; preds = %4
  %10 = tail call fastcc i32 @g(i32 noundef %3)
  br label %11

11:                                               ; preds = %9, %4
  %12 = phi i32 [ %10, %9 ], [ 0, %4 ]
  %13 = add i32 %6, %2
  %14 = add i32 %13, %12
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  ret i32 %15
}

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @g(i32 noundef %0) unnamed_addr #2 {
  %2 = mul nsw i32 %0, %0
  %3 = add nuw nsw i32 %2, 1
  ret i32 %3
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @cyc_mem(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #3
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2) #3
  %6 = and i32 %4, 1
  %7 = icmp eq i32 %6, 0
  %8 = shl nsw i32 %5, 1
  %9 = add nsw i32 %5, %4
  %10 = add i32 %8, %4
  %11 = select i1 %7, i32 %10, i32 0
  %12 = mul nsw i32 %9, 3
  %13 = add i32 %12, 7
  %14 = add i32 %13, %11
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14) #4
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

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
