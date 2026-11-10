; ModuleID = 'rp_arg.c'
source_filename = "rp_arg.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@cell = global [8 x i8] c"\01\02\03\04\05\06\07\08", align 1

; Function Attrs: noinline nounwind optnone ssp uwtable
define ptr @where() local_unnamed_addr #0 {
  ret ptr @cell
}

; Function Attrs: noinline nounwind ssp uwtable
define weak void @put(i32 noundef %0, i8 noundef signext %1) local_unnamed_addr #1 {
  %3 = tail call ptr @where()
  %4 = sext i32 %0 to i64
  %5 = getelementptr i8, ptr @cell, i64 %4
  %6 = getelementptr i8, ptr %5, i64 1
  %7 = load i8, ptr %6, align 1, !tbaa !6
  %8 = add i8 %7, %1
  store i8 %8, ptr %5, align 1, !tbaa !6
  ret void
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -256, 255) i32 @rp_arg(i32 noundef %0, double noundef %1) local_unnamed_addr #2 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  %4 = icmp sgt i32 %3, 1
  br i1 %4, label %5, label %6

5:                                                ; preds = %2
  tail call void @put(i32 noundef 2, i8 noundef signext 5)
  br label %6

6:                                                ; preds = %5, %2
  %7 = icmp sgt i32 %3, 2
  br i1 %7, label %8, label %9

8:                                                ; preds = %6
  tail call void @put(i32 noundef 2, i8 noundef signext 5)
  br label %9

9:                                                ; preds = %8, %6
  %10 = icmp sgt i32 %3, 3
  br i1 %10, label %11, label %12

11:                                               ; preds = %9
  tail call void @put(i32 noundef 2, i8 noundef signext 5)
  br label %12

12:                                               ; preds = %11, %9
  %13 = icmp sgt i32 %3, 4
  br i1 %13, label %14, label %15

14:                                               ; preds = %12
  tail call void @put(i32 noundef 2, i8 noundef signext 5)
  br label %15

15:                                               ; preds = %14, %12
  %16 = load i8, ptr getelementptr inbounds (i8, ptr @cell, i64 2), align 1, !tbaa !6
  %17 = tail call signext i8 @cq_measure_c(i8 noundef signext %16) #5
  %18 = sext i8 %17 to i32
  %19 = load i8, ptr getelementptr inbounds (i8, ptr @cell, i64 1), align 1, !tbaa !6
  %20 = tail call signext i8 @cq_measure_c(i8 noundef signext %19) #5
  %21 = sext i8 %20 to i32
  %22 = add nsw i32 %21, %18
  ret i32 %22
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #3

attributes #0 = { noinline nounwind optnone ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
