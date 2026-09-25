; ModuleID = 'p/k04C.s1.ll'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %arg, ptr nocapture noundef readonly %arg1) local_unnamed_addr #0 {
bb:
  %i = getelementptr inbounds i8, ptr %arg1, i64 8
  %i2 = load ptr, ptr %i, align 8, !tbaa !6
  %i3 = tail call i32 @atoi(ptr nocapture noundef %i2)
  %i4 = tail call i32 @cq_theta_si32(i32 noundef %i3, double noundef 5.000000e-01) #4
  %i5 = tail call i32 @h(i32 noundef %i4, i32 noundef %i3) #4
  %i6 = icmp sgt i32 %i3, 3
  br i1 %i6, label %bb7, label %bb9

bb14:                                             ; preds = %bb12, %bb9
  %i15 = phi i32 [ %i13, %bb12 ], [ %i10, %bb9 ]
  %i16 = tail call i32 @cq_measure_si32(i32 noundef %i15) #4
  ret i32 %i16
bb12:                                             ; preds = %bb9
  %i13 = tail call i32 @cq_theta_si32(i32 noundef %i10, double noundef 4.000000e-01) #4
  br label %bb14

bb9:                                              ; preds = %bb7, %bb
  %i10 = phi i32 [ %i8, %bb7 ], [ %i5, %bb ]
  %i11 = icmp sgt i32 %i3, 7
  br i1 %i11, label %bb12, label %bb14

bb7:                                              ; preds = %bb
  %i8 = tail call i32 @cq_theta_si32(i32 noundef %i5, double noundef 2.000000e-01) #4
  br label %bb9

}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %arg, i32 noundef %arg1) local_unnamed_addr #3 {
bb:
  %i = add nsw i32 %arg1, 1
  ret i32 %i
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
