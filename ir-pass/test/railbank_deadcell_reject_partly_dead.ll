; railbank_deadcell_reject_partly_dead.ll — DECLINE (bd test_C_libtooling-xdu2.9 neighbour).
;
; SOURCE: tests/e2e/railbank_deadcell_matrix.c CASE_PARTLY_DEAD at clang -O1:
;   int c[3] = {0}; for (i<3) { int t = cq_theta(c[i], .25); if (c[i] != 0 || i == 1) c[i] = t; }
; PARTLY dead: c[1]'s store fires, c[0]/c[2]'s never do. After forwarding the
; condition is `i == 1`, not a constant, so the fold must NOT fire and the per-trip
; classical-condition mux keeps its decline. ⚠ This is a residual OVER-DECLINE (the
; flat twin compiles: c1 = t1, c0 = c2 = 0), deliberately out of xdu2.9's scope —
; realizing it needs a per-trip classical specialisation, not a constant fold.
;
; ⚠ A DS_Error decline writes 0 bytes to stdout; the property is pinned by the `not`
; inversion and the mirrored diagnostic (Rule 12 (b)). The DBG prefix reads the
; PROMOTER'S OUTPUT (CQ_RAILBANK_DBG dumps it before any decline) and pins that the
; constant fold did NOT fire: the merge is still a `select` on a non-constant condition.
; RUN: env CQ_RAILBANK_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DECLINE --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=DBG     --input-file=%t.dbg %s
;
; DECLINE: cq taint escape: tainted value muxed by a classical-condition select
; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; DBG: = select i1 %{{[0-9a-z.]+}}, i32 %{{[0-9a-z.]+}}, i32 0

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @slice(i32 noundef %0)
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [3 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(12) %2, i8 0, i64 12, i1 false)
  br label %3

3:                                                ; preds = %1, %12
  %4 = phi i64 [ 0, %1 ], [ %13, %12 ]
  %5 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4, !tbaa !6
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01) #5
  %8 = icmp ne i32 %6, 0
  %9 = icmp eq i64 %4, 1
  %10 = or i1 %9, %8
  br i1 %10, label %11, label %12

11:                                               ; preds = %3
  store i32 %7, ptr %5, align 4, !tbaa !6
  br label %12

12:                                               ; preds = %3, %11
  %13 = add nuw nsw i64 %4, 1
  %14 = icmp eq i64 %13, 3
  br i1 %14, label %16, label %3, !llvm.loop !10

15:                                               ; preds = %16
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %2) #5
  ret i32 %22

16:                                               ; preds = %12, %16
  %17 = phi i64 [ %23, %16 ], [ 0, %12 ]
  %18 = phi i32 [ %22, %16 ], [ %0, %12 ]
  %19 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %17
  %20 = load i32, ptr %19, align 4, !tbaa !6
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #5
  %22 = add nsw i32 %21, %18
  %23 = add nuw nsw i64 %17, 1
  %24 = icmp eq i64 %23, 3
  br i1 %24, label %15, label %16, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
