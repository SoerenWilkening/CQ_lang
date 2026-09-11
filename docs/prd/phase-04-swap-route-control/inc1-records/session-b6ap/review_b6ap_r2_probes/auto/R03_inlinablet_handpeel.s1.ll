; ModuleID = 'R03_inlinable.c'
source_filename = "R03_inlinable.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
entryblk:
  %v1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #3
  %v2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01) #3
  %v3 = icmp eq i32 %v1, 5
  br i1 %v3, label %b4, label %b6

b4:                                                ; preds = %entryblk
  %v5 = tail call i32 @cq_theta_si32(i32 noundef %v2, double noundef 9.000000e-01) #3
  br label %b6

b6:                                                ; preds = %b4, %entryblk
  %v8 = phi i32 [ %v5, %b4 ], [ %v2, %entryblk ]
  %cq.peel.cond = icmp eq i32 %v1, 5
  %v7 = select i1 %cq.peel.cond, i32 8, i32 6
  %v9 = tail call i32 @cq_measure_si32(i32 noundef %v8) #3
  %v10 = tail call i32 @cq_measure_si32(i32 noundef %v7) #3
  %v11 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %v9, i32 noundef %v10)
  ret i32 0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
