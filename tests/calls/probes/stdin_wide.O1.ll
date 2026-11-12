; ModuleID = 'stdin_wide.c'
source_filename = "stdin_wide.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdinp = external local_unnamed_addr global ptr, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @stdin_wide(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = alloca [8 x i32], align 16
  %3 = alloca [32 x i8], align 16
  %4 = alloca [32 x i8], align 16
  %5 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 3.000000e-01) #5
  %6 = sext i8 %5 to i32
  %7 = and i32 %6, 1
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %13, label %9

9:                                                ; preds = %1
  %10 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %11 = tail call i32 @fgetwc(ptr noundef %10) #6
  %12 = mul nsw i32 %11, 7
  br label %13

13:                                               ; preds = %9, %1
  %14 = phi i32 [ %12, %9 ], [ 0, %1 ]
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %15 = and i32 %6, 3
  %16 = add nuw nsw i32 %15, 2
  %17 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %18 = call ptr @fgetws(ptr noundef nonnull %2, i32 noundef %16, ptr noundef %17) #6
  %19 = call i32 @getwchar() #6
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %20 = call ptr @gets(ptr noundef nonnull %3)
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %4, i8 0, i64 32, i1 false)
  %21 = call ptr @gets(ptr noundef nonnull %4)
  %22 = call ptr @gets(ptr noundef nonnull %4)
  %23 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %24 = call i32 @getwc(ptr noundef %23) #6
  %25 = load i32, ptr %2, align 16, !tbaa !10
  %26 = mul nsw i32 %25, 3
  %27 = getelementptr inbounds i8, ptr %2, i64 8
  %28 = load i32, ptr %27, align 8, !tbaa !10
  %29 = mul nsw i32 %28, 5
  %30 = mul nsw i32 %19, 11
  %31 = load i8, ptr %3, align 16, !tbaa !12
  %32 = sext i8 %31 to i32
  %33 = getelementptr inbounds i8, ptr %3, i64 2
  %34 = load i8, ptr %33, align 2, !tbaa !12
  %35 = sext i8 %34 to i32
  %36 = mul nsw i32 %35, 13
  %37 = load i8, ptr %4, align 16, !tbaa !12
  %38 = sext i8 %37 to i32
  %39 = mul nsw i32 %38, 17
  %40 = icmp eq ptr %22, null
  %41 = select i1 %40, i32 0, i32 19
  %42 = add i32 %14, %6
  %43 = add i32 %42, %30
  %44 = add i32 %43, %41
  %45 = add i32 %44, %24
  %46 = add i32 %45, %26
  %47 = add i32 %46, %29
  %48 = add i32 %47, %32
  %49 = add i32 %48, %36
  %50 = add i32 %49, %39
  %51 = call i32 @cq_measure_si32(i32 noundef %50) #6
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #6
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3) #6
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #6
  ret i32 %51
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

declare i32 @fgetwc(ptr noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare ptr @fgetws(ptr noundef, i32 noundef, ptr noundef) local_unnamed_addr #2

declare i32 @getwchar() local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef ptr @gets(ptr noundef) local_unnamed_addr #4

declare i32 @getwc(ptr noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
!12 = !{!8, !8, i64 0}
