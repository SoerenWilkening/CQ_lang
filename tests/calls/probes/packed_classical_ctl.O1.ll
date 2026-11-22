; ModuleID = 'packed_classical_ctl.c'
source_filename = "packed_classical_ctl.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@out = local_unnamed_addr global [4 x i8] zeroinitializer, align 1

; Function Attrs: nounwind ssp uwtable
define i32 @e(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 0, double noundef 5.000000e-01) #3
  %3 = and i8 %2, 1
  %4 = icmp eq i8 %3, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %1
  %6 = trunc i32 %0 to i16
  tail call fastcc void @g(i16 %6)
  br label %7

7:                                                ; preds = %5, %1
  %8 = zext i8 %2 to i16
  %9 = mul nuw i16 %8, 257
  tail call fastcc void @g(i16 %9)
  %10 = load i8, ptr @out, align 1, !tbaa !6
  %11 = zext i8 %10 to i32
  %12 = load i8, ptr getelementptr inbounds (i8, ptr @out, i64 1), align 1, !tbaa !6
  %13 = zext i8 %12 to i32
  %14 = add nuw nsw i32 %13, %11
  %15 = load i8, ptr getelementptr inbounds (i8, ptr @out, i64 2), align 1, !tbaa !6
  %16 = zext i8 %15 to i32
  %17 = add nuw nsw i32 %14, %16
  %18 = load i8, ptr getelementptr inbounds (i8, ptr @out, i64 3), align 1, !tbaa !6
  %19 = zext i8 %18 to i32
  %20 = add nuw nsw i32 %17, %19
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #4
  ret i32 %21
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc void @g(i16 %0) unnamed_addr #2 {
  %2 = trunc i16 %0 to i8
  %3 = lshr i16 %0, 8
  %4 = and i16 %3, 3
  %5 = zext nneg i16 %4 to i64
  %6 = getelementptr inbounds [4 x i8], ptr @out, i64 0, i64 %5
  store i8 %2, ptr %6, align 1, !tbaa !6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
