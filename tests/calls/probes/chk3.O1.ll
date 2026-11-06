; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv3/chk3.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv3/chk3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

@keep = local_unnamed_addr global [2 x ptr] [ptr @sprintf, ptr @strcpy], align 16
@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn uwtable
define internal noundef i32 @sprintf(ptr nocapture noundef writeonly %0, ptr nocapture noundef readonly %1, ...) #0 {
  %3 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %3) #7
  call void @llvm.va_start.p0(ptr nonnull %3)
  %4 = load i32, ptr %3, align 16
  %5 = icmp ult i32 %4, 41
  br i1 %5, label %6, label %12

6:                                                ; preds = %2
  %7 = getelementptr inbounds i8, ptr %3, i64 16
  %8 = load ptr, ptr %7, align 16
  %9 = zext nneg i32 %4 to i64
  %10 = getelementptr i8, ptr %8, i64 %9
  %11 = add nuw nsw i32 %4, 8
  store i32 %11, ptr %3, align 16
  br label %16

12:                                               ; preds = %2
  %13 = getelementptr inbounds i8, ptr %3, i64 8
  %14 = load ptr, ptr %13, align 8
  %15 = getelementptr i8, ptr %14, i64 8
  store ptr %15, ptr %13, align 8
  br label %16

16:                                               ; preds = %12, %6
  %17 = phi ptr [ %10, %6 ], [ %14, %12 ]
  %18 = load i32, ptr %17, align 4, !tbaa !6
  call void @llvm.va_end.p0(ptr %3)
  %19 = load i8, ptr %1, align 1, !tbaa !10
  store i8 %19, ptr %0, align 1, !tbaa !10
  %20 = trunc i32 %18 to i8
  %21 = getelementptr inbounds i8, ptr %0, i64 1
  store i8 %20, ptr %21, align 1, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %3) #7
  ret i32 2
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal noundef ptr @strcpy(ptr noundef returned writeonly %0, ptr nocapture noundef readonly %1) #1 {
  %3 = load i8, ptr %1, align 1, !tbaa !10
  store i8 %3, ptr %0, align 1, !tbaa !10
  %4 = getelementptr inbounds i8, ptr %1, i64 1
  %5 = load i8, ptr %4, align 1, !tbaa !10
  %6 = getelementptr inbounds i8, ptr %0, i64 1
  store i8 %5, ptr %6, align 1, !tbaa !10
  ret ptr %0
}

; Function Attrs: nounwind ssp uwtable
define i32 @chk3(i32 noundef %0, double noundef %1) local_unnamed_addr #2 {
  %3 = alloca [16 x i8], align 16
  %4 = alloca [16 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #7
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #7
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #8
  %6 = and i32 %5, 7
  %7 = call i32 (ptr, i32, i64, ptr, ...) @__sprintf_chk(ptr noundef nonnull %3, i32 noundef 0, i64 noundef 16, ptr noundef nonnull @.str, i32 noundef %6) #7
  %8 = call ptr @__strcpy_chk(ptr noundef nonnull %4, ptr noundef nonnull %3, i64 noundef 16) #7
  %9 = getelementptr inbounds i8, ptr %3, i64 1
  %10 = load i8, ptr %9, align 1, !tbaa !10
  %11 = sext i8 %10 to i32
  %12 = getelementptr inbounds i8, ptr %4, i64 1
  %13 = load i8, ptr %12, align 1, !tbaa !10
  %14 = sext i8 %13 to i32
  %15 = add i32 %7, %11
  %16 = add i32 %15, %14
  %17 = call i32 @cq_measure_si32(i32 noundef %16) #7
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #7
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #7
  ret i32 %17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

; Function Attrs: nofree
declare i32 @__sprintf_chk(ptr noundef, i32 noundef, i64 noundef, ptr noundef, ...) local_unnamed_addr #5

; Function Attrs: nofree
declare ptr @__strcpy_chk(ptr noundef, ptr noundef, i64 noundef) local_unnamed_addr #5

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #6

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #6

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #7 = { nounwind }
attributes #8 = { nomerge nounwind }

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
!10 = !{!8, !8, i64 0}
