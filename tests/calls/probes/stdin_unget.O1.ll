; ModuleID = 'stdin_unget.c'
source_filename = "stdin_unget.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdinp = external local_unnamed_addr global ptr, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @stdin_unget(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = alloca [8 x i8], align 8
  %3 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 3.000000e-01) #4
  %4 = tail call i32 @getchar()
  %5 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %6 = tail call i32 @ungetc(i32 noundef 81, ptr noundef %5)
  %7 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %8 = tail call i32 @ungetc(i32 noundef 82, ptr noundef %7)
  %9 = tail call i32 @getchar()
  %10 = sext i8 %3 to i32
  %11 = and i32 %10, 1
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %17, label %13

13:                                               ; preds = %1
  %14 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %15 = tail call i32 @ungetc(i32 noundef 83, ptr noundef %14)
  %16 = mul nsw i32 %15, 11
  br label %17

17:                                               ; preds = %13, %1
  %18 = phi i32 [ %16, %13 ], [ 0, %1 ]
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %2) #5
  store i64 0, ptr %2, align 8
  %19 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %20 = call ptr @fgets(ptr noundef nonnull %2, i32 noundef 5, ptr noundef %19)
  %21 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %22 = call i32 @ungetwc(i32 noundef 84, ptr noundef %21) #5
  %23 = call i32 @getwchar() #5
  %24 = add nsw i32 %18, %10
  %25 = call i32 @cq_measure_si32(i32 noundef %24) #5
  %26 = mul nsw i32 %6, 3
  %27 = mul nsw i32 %8, 5
  %28 = mul nsw i32 %9, 7
  %29 = load i8, ptr %2, align 8, !tbaa !10
  %30 = sext i8 %29 to i32
  %31 = mul nsw i32 %30, 13
  %32 = getelementptr inbounds i8, ptr %2, i64 1
  %33 = load i8, ptr %32, align 1, !tbaa !10
  %34 = sext i8 %33 to i32
  %35 = mul nsw i32 %34, 17
  %36 = getelementptr inbounds i8, ptr %2, i64 3
  %37 = load i8, ptr %36, align 1, !tbaa !10
  %38 = sext i8 %37 to i32
  %39 = mul nsw i32 %38, 19
  %40 = mul nsw i32 %23, 23
  %41 = add i32 %26, %4
  %42 = add i32 %41, %27
  %43 = add i32 %42, %28
  %44 = add i32 %43, %22
  %45 = add i32 %44, %25
  %46 = add i32 %45, %40
  %47 = add i32 %46, %31
  %48 = add i32 %47, %35
  %49 = add i32 %48, %39
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %2) #5
  ret i32 %49
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @getchar() local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef i32 @ungetc(i32 noundef, ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef ptr @fgets(ptr noundef, i32 noundef, ptr nocapture noundef) local_unnamed_addr #3

declare i32 @ungetwc(i32 noundef, ptr noundef) local_unnamed_addr #2

declare i32 @getwchar() local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{!8, !8, i64 0}
