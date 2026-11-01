; P1/U3/U6 (cq-w2a-mem-qram phase 4): a lifted clone reading a caller's QRAM through two rule 21 triples.
; From C: static noinline int rd(int *p, int *q) { return *q + *p; }  a[x & 1] = 7; r = rd(a, &a[x & 1]);
; CHECK triple_load: call fastcc i32 @__cq_q_rd_0001(i32 %{{a}}, i32 1, i32 0, i32 %{{a}}, i32 1, i32 %{{i}})
; CHECK __cq_q_rd_0001: call i32 @cqrt_qram_load_i32(i32 %{{b}}, i32 %{{i}})
; CHECK __cq_q_rd_0001: call i32 @cqrt_qram_load_i32_hl(i32 %{{b}}, i32 %{{j}})
; CHECK-COUNT __cq_q_rd_0001: cqrt_qram_store 0
; CHECK triple_load: call void @cqrt_qram_store_i32_unc
; ModuleID = 't.O1.ll'
source_filename = "t.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @triple_load(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = alloca [2 x i32], align 4
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #5
  store i32 %2, ptr %5, align 4, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %3, ptr %7, align 4, !tbaa !6
  %8 = and i32 %6, 1
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [2 x i32], ptr %5, i64 0, i64 %9
  store i32 7, ptr %10, align 4, !tbaa !6
  %11 = call fastcc i32 @rd(ptr noundef nonnull %5, ptr noundef nonnull %10)
  %12 = load i32, ptr %5, align 4, !tbaa !6
  %13 = add nsw i32 %12, %11
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #5
  ret i32 %14
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define hidden fastcc i32 @rd(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1) unnamed_addr #3 {
  %3 = load i32, ptr %1, align 4, !tbaa !6
  %4 = load i32, ptr %0, align 4, !tbaa !6
  %5 = add nsw i32 %4, %3
  ret i32 %5
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
