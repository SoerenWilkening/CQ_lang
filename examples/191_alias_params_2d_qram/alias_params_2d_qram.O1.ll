; ModuleID = 'alias_params_2d_qram.c'
source_filename = "alias_params_2d_qram.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @alias_params(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [2 x i32], align 4
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #6
  store i32 %2, ptr %5, align 4, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %3, ptr %7, align 4, !tbaa !6
  %8 = and i32 %6, 1
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds i32, ptr %5, i64 %9
  call fastcc void @addto(ptr noundef nonnull %5, ptr noundef nonnull %10)
  %11 = load i32, ptr %5, align 4, !tbaa !6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #6
  ret i32 %12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @addto(ptr nocapture noundef %0, ptr nocapture noundef readonly %1) unnamed_addr #3 {
  %3 = load i32, ptr %1, align 4, !tbaa !6
  %4 = load i32, ptr %0, align 4, !tbaa !6
  %5 = add nsw i32 %4, %3
  store i32 %5, ptr %0, align 4, !tbaa !6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @qram_2d(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca [4 x [4 x i32]], align 16
  %7 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %2, double noundef %3) #5
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %6) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(64) %6, i8 0, i64 64, i1 false)
  %9 = and i32 %7, 3
  %10 = zext nneg i32 %9 to i64
  %11 = getelementptr inbounds [4 x [4 x i32]], ptr %6, i64 0, i64 %10
  %12 = and i32 %8, 3
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [4 x [4 x i32]], ptr %6, i64 0, i64 %10, i64 %13
  store i32 %4, ptr %14, align 4, !tbaa !6
  %15 = getelementptr inbounds i8, ptr %6, i64 24
  %16 = load i32, ptr %15, align 8, !tbaa !6
  %17 = load i32, ptr %11, align 16, !tbaa !6
  %18 = add nsw i32 %17, %16
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #6
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %6) #6
  ret i32 %19
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
