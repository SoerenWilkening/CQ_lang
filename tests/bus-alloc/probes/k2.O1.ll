; ModuleID = 'tests/bus-alloc/probes/k2.c'
source_filename = "tests/bus-alloc/probes/k2.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_k2_k_used = internal constant i64 32, align 8
@llvm.used = appending global [1 x ptr] [ptr @__cq_k2_k_used], section "llvm.metadata"

; Function Attrs: nounwind uwtable
define i32 @k_used(i64 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef %1) #6
  %4 = tail call ptr @malloc(i64 noundef %3) #7
  store i32 1, ptr %4, align 4, !tbaa !6
  %5 = and i64 %3, 1
  %6 = getelementptr inbounds i32, ptr %4, i64 %5
  %7 = load i32, ptr %6, align 4, !tbaa !6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #8
  ret i32 %8
}

declare i64 @cq_theta_ul(i64 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind uwtable
define i32 @k_plain(i64 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef %1) #6
  %4 = tail call ptr @malloc(i64 noundef %3) #7
  store i32 1, ptr %4, align 4, !tbaa !6
  %5 = and i64 %3, 1
  %6 = getelementptr inbounds i32, ptr %4, i64 %5
  %7 = load i32, ptr %6, align 4, !tbaa !6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #8
  ret i32 %8
}

; Function Attrs: nounwind uwtable
define range(i32 0, 256) i32 @k_len(i64 noundef %0, double noundef %1, ptr nocapture noundef %2, ptr nocapture noundef readonly %3) local_unnamed_addr #0 {
  %5 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef %1) #6
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %2, ptr align 1 %3, i64 %5, i1 false)
  %6 = load i8, ptr %2, align 1, !tbaa !10
  %7 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %6) #8
  %8 = zext i8 %7 to i32
  ret i32 %8
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind uwtable
define range(i32 0, 256) i32 @k_len_bound(i64 noundef %0, double noundef %1, ptr nocapture noundef %2, ptr nocapture noundef readonly %3) local_unnamed_addr #0 {
  %5 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef %1) #6
  %6 = and i64 %5, 7
  tail call void @llvm.memcpy.p0.p0.i64(ptr align 1 %2, ptr align 1 %3, i64 %6, i1 false)
  %7 = load i8, ptr %2, align 1, !tbaa !10
  %8 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %7) #8
  %9 = zext i8 %8 to i32
  ret i32 %9
}

; Function Attrs: nounwind uwtable
define i32 @k_align(i64 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i64 @cq_theta_ul(i64 noundef %0, double noundef %1) #6
  %4 = tail call dereferenceable_or_null(64) ptr @aligned_alloc(i64 noundef %3, i64 noundef 64) #9
  call void @llvm.assume(i1 true) [ "align"(ptr %4, i64 %3) ]
  store i32 1, ptr %4, align 4, !tbaa !6
  %5 = and i64 %3, 1
  %6 = getelementptr inbounds i32, ptr %4, i64 %5
  %7 = load i32, ptr %6, align 4, !tbaa !6
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #8
  ret i32 %8
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized,aligned") allocsize(1) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @aligned_alloc(i64 allocalign noundef, i64 noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #5

attributes #0 = { nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized,aligned") allocsize(1) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #6 = { nomerge nounwind }
attributes #7 = { allocsize(0) }
attributes #8 = { nounwind }
attributes #9 = { allocsize(1) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 2]}
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
