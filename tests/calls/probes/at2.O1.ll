; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv3/at2.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang2/07f95dd4-5e60-4748-8b93-6d87b6b63018/scratchpad/rv3/at2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.B = type { i64, i64, i64 }

@g = global %struct.B zeroinitializer, align 8
@__const.at2.d = private unnamed_addr constant %struct.B { i64 7, i64 8, i64 9 }, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @at2(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = alloca %struct.B, align 8
  %5 = alloca %struct.B, align 8
  %6 = alloca %struct.B, align 8
  %7 = alloca %struct.B, align 8
  %8 = alloca %struct.B, align 8
  %9 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2) #6
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %4) #7
  %10 = sext i32 %9 to i64
  store i64 %10, ptr %4, align 8, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %4, i64 8
  store i64 1, ptr %11, align 8, !tbaa !11
  %12 = getelementptr inbounds i8, ptr %4, i64 16
  store i64 2, ptr %12, align 8, !tbaa !12
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %5) #7
  %13 = sext i32 %1 to i64
  store i64 %13, ptr %5, align 8, !tbaa !6
  %14 = getelementptr inbounds i8, ptr %5, i64 8
  store i64 3, ptr %14, align 8, !tbaa !11
  %15 = getelementptr inbounds i8, ptr %5, i64 16
  store i64 4, ptr %15, align 8, !tbaa !12
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %6) #7
  call void @__atomic_store(i64 noundef 24, ptr noundef nonnull @g, ptr noundef nonnull %5, i32 noundef 5)
  call void @__atomic_exchange(i64 noundef 24, ptr noundef nonnull @g, ptr noundef nonnull %4, ptr noundef nonnull %6, i32 noundef 5)
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %7) #7
  store i64 %10, ptr %7, align 8, !tbaa !6
  %16 = getelementptr inbounds i8, ptr %7, i64 8
  store i64 1, ptr %16, align 8, !tbaa !11
  %17 = getelementptr inbounds i8, ptr %7, i64 16
  store i64 2, ptr %17, align 8, !tbaa !12
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %8) #7
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(24) %8, ptr noundef nonnull align 8 dereferenceable(24) @__const.at2.d, i64 24, i1 false)
  %18 = call zeroext i1 @__atomic_compare_exchange(i64 noundef 24, ptr noundef nonnull @g, ptr noundef nonnull %7, ptr noundef nonnull %8, i32 noundef 5, i32 noundef 5)
  %19 = zext i1 %18 to i32
  %20 = load i64, ptr %6, align 8, !tbaa !6
  %21 = trunc i64 %20 to i32
  %22 = load i64, ptr @g, align 8, !tbaa !6
  %23 = trunc i64 %22 to i32
  %24 = add i32 %21, %19
  %25 = add i32 %24, %23
  %26 = call i32 @cq_measure_si32(i32 noundef %25) #7
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %8) #7
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %7) #7
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %6) #7
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %5) #7
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %4) #7
  ret i32 %26
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nofree nounwind willreturn
declare void @__atomic_store(i64, ptr, ptr, i32) local_unnamed_addr #3

; Function Attrs: mustprogress nounwind willreturn
declare void @__atomic_exchange(i64, ptr, ptr, ptr, i32) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #5

; Function Attrs: mustprogress nounwind willreturn
declare i1 @__atomic_compare_exchange(i64, ptr, ptr, ptr, i32, i32) local_unnamed_addr #4

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nofree nounwind willreturn }
attributes #4 = { mustprogress nounwind willreturn }
attributes #5 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
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
!6 = !{!7, !8, i64 0}
!7 = !{!"B", !8, i64 0, !8, i64 8, !8, i64 16}
!8 = !{!"long", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = !{!7, !8, i64 8}
!12 = !{!7, !8, i64 16}
