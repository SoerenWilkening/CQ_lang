; ModuleID = 'tests/loops-cutoff/probes/lane_switch.c'
source_filename = "tests/loops-cutoff/probes/lane_switch.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define float @ls_lane(float noundef %0, float noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call float @cq_theta_f32(float noundef %0, double noundef %2) #6
  %5 = insertelement <2 x float> poison, float %4, i64 0
  %6 = insertelement <2 x float> %5, float %1, i64 1
  %7 = tail call fastcc <2 x float> @rot(<2 x float> noundef %6)
  %8 = extractelement <2 x float> %7, i64 1
  %9 = tail call float @cq_measure_f32(float noundef %8) #7
  ret float %9
}

declare float @cq_theta_f32(float noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal fastcc <2 x float> @rot(<2 x float> noundef %0) unnamed_addr #3 {
  %2 = extractelement <2 x float> %0, i64 1
  %3 = bitcast float %2 to i32
  %4 = icmp slt i32 %3, 0
  %5 = extractelement <2 x float> %0, i64 0
  %6 = fneg float %5
  %7 = tail call float @llvm.fabs.f32(float %2)
  %8 = fneg float %7
  %9 = select i1 %4, float %6, float %5
  %10 = insertelement <2 x float> poison, float %8, i64 0
  %11 = insertelement <2 x float> %10, float %9, i64 1
  ret <2 x float> %11
}

declare float @cq_measure_f32(float noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nounwind ssp uwtable
define i32 @ls_switch(ptr nocapture noundef readnone %0, i64 noundef %1, double noundef %2) local_unnamed_addr #4 {
  %4 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #7
  store i64 506097505737310721, ptr %4, align 8
  %5 = trunc i64 %1 to i8
  store i8 %5, ptr %4, align 8, !tbaa !6
  %6 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %5, double noundef %2) #6
  store i8 %6, ptr %4, align 8, !tbaa !6
  br label %7

7:                                                ; preds = %3, %11
  %8 = phi i64 [ 0, %3 ], [ %12, %11 ]
  %9 = getelementptr inbounds [8 x i8], ptr %4, i64 0, i64 %8
  %10 = load i8, ptr %9, align 1, !tbaa !6
  switch i8 %10, label %11 [
    i8 0, label %14
    i8 47, label %14
  ]

11:                                               ; preds = %7
  %12 = add nuw nsw i64 %8, 1
  %13 = icmp eq i64 %12, 6
  br i1 %13, label %14, label %7, !llvm.loop !9

14:                                               ; preds = %11, %7, %7
  %15 = phi i64 [ 6, %11 ], [ %8, %7 ], [ %8, %7 ]
  %16 = trunc i64 %15 to i32
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #7
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #7
  ret i32 %17
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare float @llvm.fabs.f32(float) #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="64" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }

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
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
