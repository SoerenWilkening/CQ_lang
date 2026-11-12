; ModuleID = 'stdin_getline.c'
source_filename = "stdin_getline.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdinp = external local_unnamed_addr global ptr, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @stdin_getline(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i64, align 8
  %4 = alloca i64, align 8
  %5 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 3.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #5
  store ptr null, ptr %2, align 8, !tbaa !6
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #5
  store i64 0, ptr %3, align 8, !tbaa !10
  %6 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %7 = call i64 @getline(ptr noundef nonnull %2, ptr noundef nonnull %3, ptr noundef %6) #5
  %8 = load ptr, ptr %2, align 8, !tbaa !6
  %9 = load i8, ptr %8, align 1, !tbaa !12
  %10 = sext i8 %5 to i32
  %11 = and i32 %10, 1
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %18, label %13

13:                                               ; preds = %1
  %14 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %15 = call i64 @getline(ptr noundef nonnull %2, ptr noundef nonnull %3, ptr noundef %14) #5
  %16 = trunc i64 %15 to i32
  %17 = mul nsw i32 %16, 3
  br label %18

18:                                               ; preds = %13, %1
  %19 = phi i32 [ %17, %13 ], [ 0, %1 ]
  %20 = load ptr, ptr %2, align 8, !tbaa !6
  %21 = getelementptr inbounds i8, ptr %20, i64 1
  %22 = load i8, ptr %21, align 1, !tbaa !12
  %23 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %24 = call i64 @getdelim(ptr noundef nonnull %2, ptr noundef nonnull %3, i32 noundef 32, ptr noundef %23) #5
  %25 = load ptr, ptr %2, align 8, !tbaa !6
  %26 = load i8, ptr %25, align 1, !tbaa !12
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #5
  store i64 0, ptr %4, align 8, !tbaa !10
  %27 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %28 = call ptr @fgetln(ptr noundef %27, ptr noundef nonnull %4) #5
  %29 = icmp eq ptr %28, null
  br i1 %29, label %34, label %30

30:                                               ; preds = %18
  %31 = load i8, ptr %28, align 1, !tbaa !12
  %32 = sext i8 %31 to i32
  %33 = mul nsw i32 %32, 17
  br label %34

34:                                               ; preds = %18, %30
  %35 = phi i32 [ %33, %30 ], [ -17, %18 ]
  %36 = sext i8 %26 to i32
  %37 = sext i8 %22 to i32
  %38 = sext i8 %9 to i32
  %39 = load ptr, ptr %2, align 8, !tbaa !6
  call void @free(ptr noundef %39)
  %40 = trunc i64 %7 to i32
  %41 = trunc i64 %24 to i32
  %42 = mul nsw i32 %41, 5
  %43 = mul nsw i32 %38, 7
  %44 = mul nsw i32 %37, 11
  %45 = mul nsw i32 %36, 13
  %46 = load i64, ptr %4, align 8, !tbaa !10
  %47 = trunc i64 %46 to i32
  %48 = mul nsw i32 %47, 19
  %49 = add i32 %40, %10
  %50 = add i32 %49, %43
  %51 = add i32 %50, %19
  %52 = add i32 %51, %44
  %53 = add i32 %52, %42
  %54 = add i32 %53, %45
  %55 = add i32 %54, %35
  %56 = add i32 %55, %48
  %57 = call i32 @cq_measure_si32(i32 noundef %56) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #5
  ret i32 %57
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

declare i64 @getline(ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #2

declare i64 @getdelim(ptr noundef, ptr noundef, i32 noundef, ptr noundef) local_unnamed_addr #2

declare ptr @fgetln(ptr noundef, ptr noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

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
!11 = !{!"long", !8, i64 0}
!12 = !{!8, !8, i64 0}
