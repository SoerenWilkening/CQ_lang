; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_2iter.c'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/tests/e2e/slice_control_grover_2iter.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@off = global i32 3, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = load volatile i32, ptr @off, align 4, !tbaa !6
  %3 = add nsw i32 %2, %1
  %4 = icmp eq i32 %3, 5
  br i1 %4, label %5, label %6

5:                                                ; preds = %0
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %6

6:                                                ; preds = %5, %0
  %7 = load volatile i32, ptr @off, align 4, !tbaa !6
  %8 = sub nsw i32 %3, %7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef -5.000000e-01) #2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %12

11:                                               ; preds = %6
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %12

12:                                               ; preds = %11, %6
  %13 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 5.000000e-01) #2
  %14 = load volatile i32, ptr @off, align 4, !tbaa !6
  %15 = add nsw i32 %14, %13
  %16 = icmp eq i32 %15, 5
  br i1 %16, label %17, label %18

17:                                               ; preds = %12
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %18

18:                                               ; preds = %17, %12
  %19 = load volatile i32, ptr @off, align 4, !tbaa !6
  %20 = sub nsw i32 %15, %19
  %21 = tail call i32 @cq_theta_si32(i32 noundef %20, double noundef -5.000000e-01) #2
  %22 = icmp eq i32 %21, 0
  br i1 %22, label %23, label %24

23:                                               ; preds = %18
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #2
  br label %24

24:                                               ; preds = %23, %18
  %25 = tail call i32 @cq_theta_si32(i32 noundef %21, double noundef 5.000000e-01) #2
  %26 = load volatile i32, ptr @off, align 4, !tbaa !6
  %27 = add nsw i32 %26, %25
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #2
  ret i32 %28
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @slice()
  ret i32 0
}

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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
