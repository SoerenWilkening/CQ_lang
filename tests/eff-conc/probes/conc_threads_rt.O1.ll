; ModuleID = 'tests/eff-conc/probes/conc_threads_rt.c'
source_filename = "tests/eff-conc/probes/conc_threads_rt.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.box = type { i32, i32 }

@jtab = local_unnamed_addr global [2 x ptr] [ptr @j1, ptr @j2], align 16
@gt = global ptr null, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @p_thr_plain(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca %struct.box, align 4
  %4 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #6
  store i32 %0, ptr %3, align 4, !tbaa !6
  %5 = getelementptr inbounds i8, ptr %3, i64 4
  store i32 0, ptr %5, align 4, !tbaa !11
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  store i32 %6, ptr %3, align 4, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #6
  %7 = call i32 @pthread_create(ptr noundef nonnull %4, ptr noundef null, ptr noundef nonnull @boxjob, ptr noundef nonnull %3) #6
  %8 = load ptr, ptr %4, align 8, !tbaa !12
  %9 = call i32 @"\01_pthread_join"(ptr noundef %8, ptr noundef null) #6
  %10 = load i32, ptr %5, align 4, !tbaa !11
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #6
  ret i32 %11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @pthread_create(ptr noundef, ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal noalias noundef ptr @boxjob(ptr nocapture noundef %0) #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !6
  %3 = mul nsw i32 %2, 3
  %4 = add nsw i32 %3, 1
  %5 = getelementptr inbounds i8, ptr %0, i64 4
  store i32 %4, ptr %5, align 4, !tbaa !11
  ret ptr null
}

declare i32 @"\01_pthread_join"(ptr noundef, ptr noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_thr_qresult(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #6
  store i32 %0, ptr %3, align 4, !tbaa !14
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  store i32 %6, ptr %3, align 4, !tbaa !14
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #6
  %7 = call i32 @pthread_create(ptr noundef nonnull %4, ptr noundef null, ptr noundef nonnull @qret, ptr noundef nonnull %3) #6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #6
  %8 = load ptr, ptr %4, align 8, !tbaa !12
  %9 = call i32 @"\01_pthread_join"(ptr noundef %8, ptr noundef nonnull %5) #6
  %10 = load ptr, ptr %5, align 8, !tbaa !12
  %11 = ptrtoint ptr %10 to i64
  %12 = trunc i64 %11 to i32
  %13 = call i32 @cq_measure_si32(i32 noundef %12) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #6
  ret i32 %13
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal ptr @qret(ptr nocapture noundef readonly %0) #4 {
  %2 = load i32, ptr %0, align 4, !tbaa !14
  %3 = mul nsw i32 %2, 5
  %4 = add nsw i32 %3, 2
  %5 = sext i32 %4 to i64
  %6 = inttoptr i64 %5 to ptr
  ret ptr %6
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal noalias noundef ptr @j1(ptr nocapture noundef %0) #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !14
  %3 = add nsw i32 %2, 7
  store i32 %3, ptr %0, align 4, !tbaa !14
  ret ptr null
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal noalias noundef ptr @j2(ptr nocapture noundef %0) #3 {
  %2 = load i32, ptr %0, align 4, !tbaa !14
  %3 = xor i32 %2, 5
  store i32 %3, ptr %0, align 4, !tbaa !14
  ret ptr null
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_thr_table(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #6
  store i32 %0, ptr %4, align 4, !tbaa !14
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  store i32 %6, ptr %4, align 4, !tbaa !14
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #6
  %7 = and i32 %2, 1
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [2 x ptr], ptr @jtab, i64 0, i64 %8
  %10 = load ptr, ptr %9, align 8, !tbaa !12
  %11 = call i32 @pthread_create(ptr noundef nonnull %5, ptr noundef null, ptr noundef %10, ptr noundef nonnull %4) #6
  %12 = load ptr, ptr %5, align 8, !tbaa !12
  %13 = call i32 @"\01_pthread_join"(ptr noundef %12, ptr noundef null) #6
  %14 = load i32, ptr %4, align 4, !tbaa !14
  %15 = call i32 @cq_measure_si32(i32 noundef %14) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #6
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_thr_qsel(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #6
  store i32 %0, ptr %3, align 4, !tbaa !14
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  store i32 %5, ptr %3, align 4, !tbaa !14
  %6 = and i32 %5, 2
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, ptr @j2, ptr @j1
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #6
  %9 = call i32 @pthread_create(ptr noundef nonnull %4, ptr noundef null, ptr noundef nonnull %8, ptr noundef nonnull %3) #6
  %10 = load ptr, ptr %4, align 8, !tbaa !12
  %11 = call i32 @"\01_pthread_join"(ptr noundef %10, ptr noundef null) #6
  %12 = load i32, ptr %3, align 4, !tbaa !14
  %13 = call i32 @cq_measure_si32(i32 noundef %12) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #6
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_thr_ext(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #6
  store i32 %0, ptr %3, align 4, !tbaa !14
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  store i32 %6, ptr %3, align 4, !tbaa !14
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #6
  %7 = call i32 @pthread_create(ptr noundef nonnull %4, ptr noundef null, ptr noundef nonnull @ext_job, ptr noundef nonnull %3) #6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #6
  %8 = load ptr, ptr %4, align 8, !tbaa !12
  %9 = call i32 @"\01_pthread_join"(ptr noundef %8, ptr noundef nonnull %5) #6
  %10 = load i32, ptr %3, align 4, !tbaa !14
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #6
  %12 = load ptr, ptr %5, align 8, !tbaa !12
  %13 = icmp ne ptr %12, null
  %14 = zext i1 %13 to i32
  %15 = add nsw i32 %11, %14
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #6
  ret i32 %15
}

declare ptr @ext_job(ptr noundef) #2

; Function Attrs: noinline nounwind ssp uwtable
define void @p_thr_start(ptr noundef %0) local_unnamed_addr #5 {
  %2 = tail call i32 @pthread_create(ptr noundef nonnull @gt, ptr noundef null, ptr noundef nonnull @cjob, ptr noundef %0) #6
  ret void
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal ptr @cjob(ptr nocapture noundef readonly %0) #4 {
  %2 = load i32, ptr %0, align 4, !tbaa !14
  %3 = shl nsw i32 %2, 1
  %4 = add nsw i32 %3, 42
  %5 = sext i32 %4 to i64
  %6 = inttoptr i64 %5 to ptr
  ret ptr %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_thr_global(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #6
  store i32 %2, ptr %4, align 4, !tbaa !14
  call void @p_thr_start(ptr noundef nonnull %4)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #6
  %7 = load ptr, ptr @gt, align 8, !tbaa !12
  %8 = call i32 @"\01_pthread_join"(ptr noundef %7, ptr noundef nonnull %5) #6
  %9 = call i32 @cq_measure_si32(i32 noundef %6) #6
  %10 = load ptr, ptr %5, align 8, !tbaa !12
  %11 = ptrtoint ptr %10 to i64
  %12 = trunc i64 %11 to i32
  %13 = add nsw i32 %9, %12
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #6
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_thr_nullres(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #6
  store i32 %0, ptr %4, align 4, !tbaa !14
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #7
  store i32 %7, ptr %4, align 4, !tbaa !14
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #6
  %8 = call i32 @pthread_create(ptr noundef nonnull %5, ptr noundef null, ptr noundef nonnull @qret, ptr noundef nonnull %4) #6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #6
  store ptr null, ptr %6, align 8, !tbaa !12
  %9 = and i32 %2, 1
  %10 = icmp eq i32 %9, 0
  %11 = select i1 %10, ptr null, ptr %6
  %12 = load ptr, ptr %5, align 8, !tbaa !12
  %13 = call i32 @"\01_pthread_join"(ptr noundef %12, ptr noundef %11) #6
  %14 = load ptr, ptr %6, align 8, !tbaa !12
  %15 = ptrtoint ptr %14 to i64
  %16 = trunc i64 %15 to i32
  %17 = call i32 @cq_measure_si32(i32 noundef %16) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #6
  ret i32 %17
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !8, i64 0}
!7 = !{!"box", !8, i64 0, !8, i64 4}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 4}
!12 = !{!13, !13, i64 0}
!13 = !{!"any pointer", !9, i64 0}
!14 = !{!8, !8, i64 0}
