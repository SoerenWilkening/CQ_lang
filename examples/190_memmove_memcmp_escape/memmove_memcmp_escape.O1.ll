; ModuleID = 'memmove_memcmp_escape.c'
source_filename = "memmove_memcmp_escape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @memmove_overlap(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) local_unnamed_addr #0 {
  %6 = alloca [4 x i32], align 16
  %7 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %8 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #5
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %6) #6
  store i32 %7, ptr %6, align 16, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %6, i64 4
  store i32 %8, ptr %9, align 4, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %6, i64 8
  store i32 5, ptr %10, align 8, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %6, i64 12
  store i32 6, ptr %11, align 4, !tbaa !6
  call void @llvm.memmove.p0.p0.i64(ptr noundef nonnull align 4 dereferenceable(12) %9, ptr noundef nonnull align 16 dereferenceable(12) %6, i64 12, i1 false)
  %12 = and i32 %4, 3
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %13
  %15 = load i32, ptr %14, align 4, !tbaa !6
  %16 = add nsw i32 %15, 1
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16) #6
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %6) #6
  ret i32 %17
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i1 immarg) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @memcmp_qlen(i32 noundef %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, i8 noundef zeroext %4, double noundef %5) local_unnamed_addr #0 {
  %7 = alloca [3 x i8], align 1
  %8 = alloca [3 x i8], align 1
  %9 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #5
  %10 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %2, double noundef %3) #5
  %11 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %4, double noundef %5) #5
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %7) #6
  store i8 %10, ptr %7, align 1, !tbaa !10
  %12 = getelementptr inbounds i8, ptr %7, i64 1
  store i8 %11, ptr %12, align 1, !tbaa !10
  %13 = getelementptr inbounds i8, ptr %7, i64 2
  store i8 %10, ptr %13, align 1, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %8) #6
  store i8 %10, ptr %8, align 1, !tbaa !10
  %14 = getelementptr inbounds i8, ptr %8, i64 1
  store i8 %10, ptr %14, align 1, !tbaa !10
  %15 = getelementptr inbounds i8, ptr %8, i64 2
  store i8 %11, ptr %15, align 1, !tbaa !10
  %16 = and i32 %9, 3
  %17 = zext nneg i32 %16 to i64
  %18 = call i32 @memcmp(ptr noundef nonnull %7, ptr noundef nonnull %8, i64 noundef %17)
  %19 = ashr i32 %18, 31
  %20 = icmp ne i32 %18, 0
  %21 = zext i1 %20 to i32
  %22 = or i32 %19, %21
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22) #6
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %8) #6
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %7) #6
  ret i32 %23
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree nounwind willreturn memory(argmem: read)
declare i32 @memcmp(ptr nocapture noundef, ptr nocapture noundef, i64 noundef) local_unnamed_addr #4

; Function Attrs: nounwind ssp uwtable
define i32 @escape(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = alloca [2 x i32], align 4
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3) #6
  store i32 %4, ptr %3, align 4, !tbaa !6
  %5 = getelementptr inbounds i8, ptr %3, i64 4
  %6 = add nsw i32 %4, 1
  store i32 %6, ptr %5, align 4, !tbaa !6
  call void @ext_sink(ptr noundef nonnull %3, i32 noundef 2) #6
  %7 = load i32, ptr %3, align 4, !tbaa !6
  %8 = call i32 @cq_measure_si32(i32 noundef %7) #6
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3) #6
  ret i32 %8
}

declare void @ext_sink(ptr noundef, i32 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { mustprogress nofree nounwind willreturn memory(argmem: read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!8, !8, i64 0}
