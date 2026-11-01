; ModuleID = 'read_only_ptr.c'
source_filename = "read_only_ptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ro_bump(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) local_unnamed_addr #0 {
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %7) #6
  store i32 %0, ptr %7, align 4, !tbaa !6
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  store i32 %9, ptr %7, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %8) #6
  store i32 %3, ptr %8, align 4, !tbaa !6
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %4) #7
  store i32 %10, ptr %8, align 4, !tbaa !6
  %11 = mul nsw i32 %10, %2
  call fastcc void @bump(ptr noundef nonnull %8, ptr noundef nonnull %7)
  %12 = icmp sgt i32 %11, 3
  br i1 %12, label %13, label %14

13:                                               ; preds = %6
  tail call void @cq_phi(double noundef %5) #6
  br label %14

14:                                               ; preds = %13, %6
  %15 = tail call i32 @cq_measure_si32(i32 noundef %9) #6
  %16 = load i32, ptr %8, align 4, !tbaa !6
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #6
  %18 = add nsw i32 %17, %15
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %8) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %7) #6
  ret i32 %18
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal fastcc void @bump(ptr nocapture noundef %0, ptr nocapture noundef readonly %1) unnamed_addr #3 {
  %3 = load i32, ptr %1, align 4, !tbaa !6
  %4 = load i32, ptr %0, align 4, !tbaa !6
  %5 = add nsw i32 %4, %3
  store i32 %5, ptr %0, align 4, !tbaa !6
  ret void
}

declare void @cq_phi(double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @ro_phase(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = alloca i32, align 4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #6
  %7 = add nsw i32 %6, %2
  store i32 %7, ptr %5, align 4, !tbaa !6
  call fastcc void @use(ptr noundef nonnull %5, double noundef %3)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #6
  ret i32 %8
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @use(ptr nocapture noundef readonly %0, double noundef %1) unnamed_addr #4 {
  %3 = load i32, ptr %0, align 4, !tbaa !6
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %6

5:                                                ; preds = %2
  tail call void @cq_phi(double noundef %1) #6
  br label %6

6:                                                ; preds = %5, %2
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @ro_result(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #6
  store i32 %0, ptr %4, align 4, !tbaa !6
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  store i32 %6, ptr %4, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #6
  %7 = add nsw i32 %6, %2
  store i32 %7, ptr %5, align 4, !tbaa !6
  %8 = call fastcc i32 @rd(ptr noundef nonnull %4, ptr noundef nonnull %5)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #6
  ret i32 %9
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal fastcc i32 @rd(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1) unnamed_addr #5 {
  %3 = load i32, ptr %0, align 4, !tbaa !6
  %4 = load i32, ptr %1, align 4, !tbaa !6
  %5 = add nsw i32 %4, %3
  ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @ro_old(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca i32, align 4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5) #6
  store i32 %6, ptr %5, align 4, !tbaa !6
  %7 = add nsw i32 %6, %2
  %8 = call fastcc i32 @rdm(ptr noundef nonnull %5, i32 noundef %3)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #6
  %10 = tail call i32 @cq_measure_si32(i32 noundef %7) #6
  %11 = add nsw i32 %10, %9
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5) #6
  ret i32 %11
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal fastcc i32 @rdm(ptr nocapture noundef readonly %0, i32 noundef %1) unnamed_addr #5 {
  %3 = load i32, ptr %0, align 4, !tbaa !6
  %4 = mul nsw i32 %3, %1
  ret i32 %4
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }

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
