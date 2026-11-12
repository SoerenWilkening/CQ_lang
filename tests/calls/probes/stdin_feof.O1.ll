; ModuleID = 'stdin_feof.c'
source_filename = "stdin_feof.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdinp = external local_unnamed_addr global ptr, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @stdin_feof(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  %3 = alloca [64 x i8], align 16
  %4 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 3.000000e-01) #5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #6
  store i32 0, ptr %2, align 4
  %5 = call i64 @"\01_pread"(i32 noundef 0, ptr noundef nonnull %2, i64 noundef 3, i64 noundef 2) #6
  %6 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %7 = call i32 @getw(ptr noundef %6) #6
  %8 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %9 = call i32 @feof(ptr noundef %8)
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %3) #6
  %10 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %11 = call i64 @fread(ptr noundef nonnull %3, i64 noundef 1, i64 noundef 64, ptr noundef %10)
  %12 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %13 = call i32 @feof(ptr noundef %12)
  %14 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %15 = call i32 @ferror(ptr noundef %14)
  call void @clearerr(ptr noundef %14)
  %16 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %17 = call i32 @feof(ptr noundef %16)
  %18 = sext i8 %4 to i32
  %19 = and i32 %18, 1
  %20 = icmp eq i32 %19, 0
  br i1 %20, label %23, label %21

21:                                               ; preds = %1
  %22 = call i32 @getchar()
  br label %23

23:                                               ; preds = %21, %1
  %24 = phi i32 [ %22, %21 ], [ 0, %1 ]
  %25 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %26 = call i32 @feof(ptr noundef %25)
  %27 = trunc i64 %5 to i32
  %28 = load i8, ptr %2, align 4, !tbaa !10
  %29 = sext i8 %28 to i32
  %30 = mul nsw i32 %29, 3
  %31 = getelementptr inbounds i8, ptr %2, i64 2
  %32 = load i8, ptr %31, align 2, !tbaa !10
  %33 = sext i8 %32 to i32
  %34 = mul nsw i32 %33, 5
  %35 = mul nsw i32 %9, 7
  %36 = trunc i64 %11 to i32
  %37 = mul nsw i32 %36, 11
  %38 = mul nsw i32 %13, 13
  %39 = mul nsw i32 %15, 17
  %40 = mul nsw i32 %17, 19
  %41 = mul nsw i32 %26, 23
  %42 = add i32 %27, %18
  %43 = add i32 %42, %7
  %44 = add i32 %43, %35
  %45 = add i32 %44, %37
  %46 = add i32 %45, %38
  %47 = add i32 %46, %39
  %48 = add i32 %47, %40
  %49 = add i32 %48, %24
  %50 = add i32 %49, %41
  %51 = add i32 %50, %30
  %52 = add i32 %51, %34
  %53 = call i32 @cq_measure_si32(i32 noundef %52) #6
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %3) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #6
  ret i32 %53
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

declare i64 @"\01_pread"(i32 noundef, ptr noundef, i64 noundef, i64 noundef) local_unnamed_addr #2

declare i32 @getw(ptr noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @feof(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef i64 @fread(ptr nocapture noundef, i64 noundef, i64 noundef, ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: nofree nounwind memory(read)
declare noundef i32 @ferror(ptr nocapture noundef) local_unnamed_addr #4

; Function Attrs: nofree nounwind
declare void @clearerr(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef i32 @getchar() local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree nounwind memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = !{!8, !8, i64 0}
