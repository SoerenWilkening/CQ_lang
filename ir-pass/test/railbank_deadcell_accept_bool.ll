; railbank_deadcell_accept_bool.ll — ACCEPT (bd test_C_libtooling-xdu2.9).
;
; SOURCE: tests/e2e/railbank_deadcell_matrix.c CASE_DEAD_BOOL at clang -O1:
;   bool c[3] = {0}; for (i<3) { bool t = c[i]; cq_theta(&t, .25); if (c[i]) c[i] = t; }
; The `_Bool` spelling: PASS G narrows the merge φ to the i1 rail type and sinks the
; storage `zext` to the relocated store, THEN PASS H resolves the (now i1) φ to the
; seed `false`. The store parks a classical `zext i1 false`, the object is not a
; bank, the measure loop is classical. Byte-identical to the array-free rolled twin
; (matrix CASE 20).
; Pre-fix: DECLINED `cq taint escape: tainted value muxed by a classical-condition
; select` (d0720cb1 oracle).
;
; RUN: env CQ_RAILBANK_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s -o %t.out.ll 2> %t.dbg
; RUN: %filecheck                      --input-file=%t.out.ll %s
; RUN: %filecheck --check-prefix=NEG   --input-file=%t.out.ll %s
; RUN: %filecheck --check-prefix=DBG   --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NODBG --input-file=%t.dbg %s
;
; CHECK:      = alloca [3 x i8], align 1{{$}}
; CHECK:      %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %h, double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %h, double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %h)
; NEG-NOT: !cq.railbank
; NEG-NOT: select
; NEG-NOT: cqrt_measure
; DBG: CQ_RAILBANK_DBG: promote bank % in @slice header % cells=3 cell=i8 seed=zero loads=1 stores=1
; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; NODBG-NOT: select
; NODBG-NOT: mark bank

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @slice(i32 noundef %0)
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %2, i8 0, i64 3, i1 false)
  br label %3

3:                                                ; preds = %1, %11
  %4 = phi i64 [ 0, %1 ], [ %12, %11 ]
  %5 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %4
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = trunc nuw i8 %6 to i1
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef 2.500000e-01) #5
  br i1 %7, label %9, label %11

9:                                                ; preds = %3
  %10 = zext i1 %8 to i8
  store i8 %10, ptr %5, align 1, !tbaa !6
  br label %11

11:                                               ; preds = %9, %3
  %12 = add nuw nsw i64 %4, 1
  %13 = icmp eq i64 %12, 3
  br i1 %13, label %15, label %3, !llvm.loop !12

14:                                               ; preds = %15
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %2) #5
  ret i32 %23

15:                                               ; preds = %11, %15
  %16 = phi i64 [ %24, %15 ], [ 0, %11 ]
  %17 = phi i32 [ %23, %15 ], [ %0, %11 ]
  %18 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %16
  %19 = load i8, ptr %18, align 1, !tbaa !6, !range !10, !noundef !11
  %20 = trunc nuw i8 %19 to i1
  %21 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %20) #5
  %22 = zext i1 %21 to i32
  %23 = add nsw i32 %17, %22
  %24 = add nuw nsw i64 %16, 1
  %25 = icmp eq i64 %24, 3
  br i1 %25, label %14, label %15, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #4

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
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
