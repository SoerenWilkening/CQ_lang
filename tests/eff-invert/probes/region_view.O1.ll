; ModuleID = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-af56e43ef3a3c5c8e/tests/eff-invert/probes/region_view.c'
source_filename = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-af56e43ef3a3c5c8e/tests/eff-invert/probes/region_view.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define zeroext i8 @p_view(i8 noundef zeroext %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef 0.000000e+00) #3
  %3 = icmp ugt i8 %2, 4
  br i1 %3, label %4, label %7

4:                                                ; preds = %1
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x4000C152382D7365) #3
  %6 = zext i1 %5 to i8
  br label %7

7:                                                ; preds = %4, %1
  %8 = phi i8 [ %6, %4 ], [ 0, %1 ]
  tail call void @__cq_invert_begin() #4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !6
  br i1 %3, label %9, label %13

9:                                                ; preds = %7
  %10 = trunc nuw i8 %8 to i1
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %10, double noundef 0x4000C152382D7365) #3
  %12 = zext i1 %11 to i8
  br label %13

13:                                               ; preds = %9, %7
  %14 = phi i8 [ %12, %9 ], [ %8, %7 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #5, !srcloc !7
  tail call void @__cq_invert_end() #4
  br i1 %3, label %15, label %19

15:                                               ; preds = %13
  %16 = trunc nuw i8 %14 to i1
  %17 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %16, double noundef 0x4000C152382D7365) #3
  %18 = zext i1 %17 to i8
  br label %19

19:                                               ; preds = %15, %13
  %20 = phi i8 [ %18, %15 ], [ %14, %13 ]
  %21 = and i8 %14, 1
  %22 = add nuw nsw i8 %21, %8
  %23 = trunc nuw i8 %20 to i1
  %24 = and i8 %20, 1
  %25 = add nuw nsw i8 %22, %24
  %26 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %25) #5
  %27 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %23) #5
  %28 = zext i1 %27 to i8
  %29 = add i8 %26, %28
  ret i8 %29
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: noduplicate
declare void @__cq_invert_begin() local_unnamed_addr #2

; Function Attrs: noduplicate
declare void @__cq_invert_end() local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noduplicate "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { noduplicate nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{i64 2147512051}
!7 = !{i64 2147513138}
