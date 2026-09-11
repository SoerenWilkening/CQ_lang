; ModuleID = 'p09_owner_int.c'
source_filename = "p09_owner_int.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %merge, label %arm

arm:                                              ; preds = %entry
  %r1 = mul nsw i32 %b0, 3
  %r2 = add nsw i32 %r1, 1
  %s1 = add nsw i32 %r2, 7
  br label %merge

merge:                                            ; preds = %arm, %entry
  %r = phi i32 [ %r2, %arm ], [ %b0, %entry ]
  %s = phi i32 [ %s1, %arm ], [ 0, %entry ]
  %m0 = tail call i32 @cq_measure_si32(i32 noundef %b0) #2
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %r) #2
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %s) #2
  %t1 = add nsw i32 %m0, %m1
  %t2 = add nsw i32 %t1, %m2
  ret i32 %t2
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
