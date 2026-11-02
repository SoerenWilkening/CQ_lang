; Rule 22 (cq-k65d, f684858: no unroll bound): a quantum length with no range fact into a heap QRAM of run-time
; size: the loop over the cells the bound reaches, each cell's store under n >u (j + 1) - 1 (structural only).
; CHECK lp_qlen: call i32 @cq_template_icmp_ugt_i64_hl(i32 %{{n}}, i64 %{{k}})
; CHECK lp_qlen: call void @cqrt_qram_store_i8_controlled(
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #0

; Function Attrs: nounwind ssp uwtable
define range(i32 -128, 128) i32 @lp_qlen(i32 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #1 {
  %4 = tail call ptr @malloc(i64 noundef %2) #5
  %5 = zext i32 %0 to i64
  %6 = tail call i64 @cq_theta_ul(i64 noundef %5, double noundef %1) #6
  %7 = getelementptr inbounds i8, ptr %4, i64 %6
  store i8 1, ptr %7, align 1, !tbaa !6
  tail call void @llvm.memset.p0.i64(ptr align 1 %4, i8 7, i64 %6, i1 false)
  %8 = load i8, ptr %7, align 1, !tbaa !6
  %9 = tail call signext i8 @cq_measure_c(i8 noundef signext %8) #7
  %10 = sext i8 %9 to i32
  tail call void @free(ptr noundef %4)
  ret i32 %10
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

declare i64 @cq_theta_ul(i64 noundef, double noundef) local_unnamed_addr #3

declare signext i8 @cq_measure_c(i8 noundef signext) local_unnamed_addr #3

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #4

attributes #0 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { allocsize(0) }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
