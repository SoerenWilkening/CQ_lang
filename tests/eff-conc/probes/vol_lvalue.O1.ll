; ModuleID = 'tests/eff-conc/probes/vol_lvalue.c'
source_filename = "tests/eff-conc/probes/vol_lvalue.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g2 = global i32 0, align 4
@g3 = global i32 0, align 4
@gv1 = global i32 0, align 4
@gv5 = internal global i32 3, align 4
@q5 = local_unnamed_addr global ptr null, align 8
@gp = global i32 11, align 4
@gq = global i32 0, align 4
@tab = global [4 x i32] [i32 3, i32 4, i32 5, i32 6], align 16
@gs = global i32 0, align 4

; Function Attrs: nounwind ssp uwtable
define i32 @v1(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #7
  %5 = add nsw i32 %4, 1
  store i32 %5, ptr %3, align 4, !tbaa !6
  %6 = call fastcc i32 @rd(ptr noundef nonnull %3)
  %7 = call i32 @cq_measure_si32(i32 noundef %6) #7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #7
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nofree noinline norecurse nounwind ssp willreturn memory(argmem: readwrite, inaccessiblemem: readwrite) uwtable
define internal fastcc i32 @rd(ptr noundef %0) unnamed_addr #3 {
  %2 = load volatile i32, ptr %0, align 4, !tbaa !6
  ret i32 %2
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nounwind ssp uwtable
define i32 @v2(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  store i32 %3, ptr @g2, align 4, !tbaa !6
  %4 = load volatile i32, ptr @g2, align 4, !tbaa !6
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #7
  ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @v3(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  store i32 %3, ptr @g3, align 4, !tbaa !6
  store volatile i32 5, ptr @g3, align 4, !tbaa !6
  %4 = add nsw i32 %3, 5
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4) #7
  ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @vl1(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  store volatile i32 %3, ptr @gv1, align 4, !tbaa !6
  %4 = load volatile i32, ptr @gv1, align 4, !tbaa !6
  %5 = add nsw i32 %4, 1
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #7
  ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @vl3(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %5)
  %6 = and i32 %2, 1
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, ptr %5, ptr %4
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  store volatile i32 %9, ptr %4, align 4, !tbaa !6
  %10 = add nsw i32 %9, 1
  store volatile i32 %10, ptr %5, align 4, !tbaa !6
  %11 = load volatile i32, ptr %8, align 4, !tbaa !6
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11) #7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %5)
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4)
  ret i32 %12
}

; Function Attrs: nounwind ssp uwtable
define i32 @vl5(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  tail call fastcc void @cap()
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  %4 = load ptr, ptr @q5, align 8, !tbaa !10
  store i32 %3, ptr %4, align 4, !tbaa !6
  %5 = load volatile i32, ptr @gv5, align 4, !tbaa !6
  %6 = add nsw i32 %5, 1
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #7
  ret i32 %7
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc void @cap() unnamed_addr #4 {
  store ptr @gv5, ptr @q5, align 8, !tbaa !10
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @vp_host(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  %5 = icmp sgt i32 %4, %2
  br i1 %5, label %6, label %8

6:                                                ; preds = %3
  %7 = load volatile i32, ptr @gp, align 4, !tbaa !6
  br label %8

8:                                                ; preds = %6, %3
  %9 = phi i32 [ %7, %6 ], [ 7, %3 ]
  %10 = add nsw i32 %9, %4
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #7
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @vp_quantum(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  %5 = add nsw i32 %4, 1
  store i32 %5, ptr @gq, align 4, !tbaa !6
  %6 = icmp sgt i32 %4, %2
  br i1 %6, label %7, label %10

7:                                                ; preds = %3
  %8 = load volatile i32, ptr @gq, align 4, !tbaa !6
  %9 = add nsw i32 %8, 2
  store i32 %9, ptr @gq, align 4, !tbaa !6
  br label %10

10:                                               ; preds = %7, %3
  %11 = phi i32 [ %8, %7 ], [ 7, %3 ]
  %12 = load i32, ptr @gq, align 4, !tbaa !6
  %13 = add nsw i32 %12, %11
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #7
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @vp_ctl(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %8, label %6

6:                                                ; preds = %2
  %7 = tail call fastcc i32 @rdg()
  br label %8

8:                                                ; preds = %6, %2
  %9 = phi i32 [ %7, %6 ], [ 2, %2 ]
  %10 = add nsw i32 %9, %3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #7
  ret i32 %11
}

; Function Attrs: mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none) uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @rdg() unnamed_addr #5 {
  %1 = load volatile i32, ptr @gp, align 4, !tbaa !6
  %2 = add nsw i32 %1, 1
  ret i32 %2
}

; Function Attrs: nounwind ssp uwtable
define i32 @vp_rail(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  %5 = icmp sgt i32 %4, %2
  br i1 %5, label %6, label %12

6:                                                ; preds = %3
  %7 = and i32 %4, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x i32], ptr @tab, i64 0, i64 %8
  %10 = load volatile i32, ptr %9, align 4, !tbaa !6
  %11 = add nsw i32 %10, 1
  store volatile i32 %11, ptr %9, align 4, !tbaa !6
  br label %12

12:                                               ; preds = %6, %3
  %13 = phi i32 [ %10, %6 ], [ 1, %3 ]
  %14 = load volatile i32, ptr @tab, align 16, !tbaa !6
  %15 = add nsw i32 %14, %13
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #7
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @vs_pred(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  store volatile i32 1, ptr @gs, align 4, !tbaa !6
  %5 = icmp sgt i32 %4, %2
  br i1 %5, label %6, label %7

6:                                                ; preds = %3
  store volatile i32 %4, ptr @gs, align 4, !tbaa !6
  br label %7

7:                                                ; preds = %6, %3
  %8 = load volatile i32, ptr @gs, align 4, !tbaa !6
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #7
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define i32 @vc(i32 noundef %0, double noundef %1, ptr noundef readnone %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #7
  store volatile i32 4, ptr %4, align 4, !tbaa !6
  %5 = icmp eq ptr %4, %2
  %6 = zext i1 %5 to i32
  %7 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  store volatile i32 9, ptr %4, align 4, !tbaa !6
  %8 = load volatile i32, ptr %4, align 4, !tbaa !6
  %9 = add i32 %7, %6
  %10 = add i32 %9, %8
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #7
  ret i32 %11
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree noinline norecurse nounwind ssp willreturn memory(argmem: readwrite, inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree noinline norecurse nounwind ssp willreturn memory(readwrite, argmem: none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !8, i64 0}
