; ModuleID = 'teleport.c'
source_filename = "teleport.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @teleport(double noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %0) #2
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FF921FB54442D18) #2
  %4 = xor i1 %2, %3
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %2, double noundef 0xBFF921FB54442D18) #2
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %4) #3
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #3
  %8 = xor i1 %3, %6
  %9 = select i1 %7, i1 %8, i1 false
  br i1 %9, label %10, label %11

10:                                               ; preds = %1
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #3
  br label %11

11:                                               ; preds = %1, %10
  %12 = fneg double %0
  %13 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef %12) #2
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %13) #3
  %15 = zext i1 %14 to i32
  ret i32 %15
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
