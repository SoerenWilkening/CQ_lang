; ModuleID = 'keptstore.c'
source_filename = "keptstore.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @ks_phi(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3, i32 noundef %4, i32 noundef %5) local_unnamed_addr #0 {
  %7 = alloca [4 x i32], align 16
  %8 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #3
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %3) #3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %7) #4
  store i32 %4, ptr %7, align 16, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %7, i64 4
  %11 = add i32 %4, 1
  store i32 %11, ptr %10, align 4, !tbaa !6
  %12 = getelementptr inbounds i8, ptr %7, i64 8
  %13 = add i32 %4, 2
  store i32 %13, ptr %12, align 8, !tbaa !6
  %14 = getelementptr inbounds i8, ptr %7, i64 12
  store i32 %5, ptr %14, align 4, !tbaa !6
  %15 = and i32 %4, 1
  %16 = icmp eq i32 %15, 0
  br i1 %16, label %26, label %17

17:                                               ; preds = %6
  %18 = and i32 %8, 3
  %19 = zext nneg i32 %18 to i64
  %20 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %19
  store i32 %9, ptr %20, align 4, !tbaa !6
  %21 = add i32 %8, 1
  %22 = and i32 %21, 3
  %23 = zext nneg i32 %22 to i64
  %24 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %23
  %25 = load i32, ptr %24, align 4, !tbaa !6
  br label %36

26:                                               ; preds = %6
  %27 = mul i32 %9, 3
  %28 = and i32 %8, 3
  %29 = xor i32 %28, 2
  %30 = zext nneg i32 %29 to i64
  %31 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %30
  store i32 %27, ptr %31, align 4, !tbaa !6
  %32 = zext nneg i32 %28 to i64
  %33 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %32
  %34 = load i32, ptr %33, align 4, !tbaa !6
  %35 = add i32 %34, 1
  br label %36

36:                                               ; preds = %26, %17
  %37 = phi i32 [ %25, %17 ], [ %35, %26 ]
  %38 = and i32 %5, 2
  %39 = icmp eq i32 %38, 0
  br i1 %39, label %45, label %40

40:                                               ; preds = %36
  %41 = add i32 %8, 3
  %42 = and i32 %41, 3
  %43 = zext nneg i32 %42 to i64
  %44 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %43
  store i32 %37, ptr %44, align 4, !tbaa !6
  br label %45

45:                                               ; preds = %40, %36
  %46 = add i32 %8, 1
  %47 = and i32 %46, 3
  %48 = zext nneg i32 %47 to i64
  %49 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %48
  %50 = load i32, ptr %49, align 4, !tbaa !6
  %51 = and i32 %5, 3
  %52 = zext nneg i32 %51 to i64
  %53 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %52
  %54 = load i32, ptr %53, align 4, !tbaa !6
  %55 = xor i32 %54, %50
  %56 = tail call i32 @cq_measure_ui32(i32 noundef %55) #4
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %7) #4
  ret i32 %56
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
