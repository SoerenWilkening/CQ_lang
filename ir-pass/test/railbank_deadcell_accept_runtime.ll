; railbank_deadcell_accept_runtime.ll — ACCEPT (bd test_C_libtooling-xdu2.9).
;
; SOURCE: tests/e2e/railbank_deadcell_matrix.c CASE_DEAD_RUNTIME at clang -O1: the
; RUNTIME-sized, UNINITIALISED `int c[n]` form of railbank_deadcell_accept_fixed.ll.
; Owner ruling D1 reads the cell as 0 (the promoter's seed), so `c[i] != 0` is the
; same constant and PASS H resolves the merge to the seed. The relocated store of
; `0` is NOT a no-op here and must NOT be deleted: the VLA has no initializer, and
; it is that store which makes the measure loop read the 0 D1 says the cell holds.
; Byte-identical to the array-free rolled twin (matrix CASE 17) at n = 3.
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
; CHECK:      %[[C:[0-9]+]] = alloca i32, i64 %{{[0-9]+}}, align 16{{$}}
; CHECK:      %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %h)
; CHECK:      %cq.bank.addr = getelementptr inbounds i32, ptr %[[C]], i64 %{{[0-9]+}}
; CHECK-NEXT: store i32 0, ptr %cq.bank.addr
; NEG-NOT: !cq.railbank
; NEG-NOT: cq.bank.seed
; NEG-NOT: select
; NEG-NOT: cqrt_measure
; DBG: CQ_RAILBANK_DBG: promote bank % in @slice header % cells=runtime({{.*}}) cell=i32 seed=zero loads=1 stores=1
; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; DBG: store i32 0, ptr %cq.bank.addr
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
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %30, label %3

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  %5 = tail call ptr @llvm.stacksave.p0()
  %6 = alloca i32, i64 %4, align 16
  %7 = zext nneg i32 %0 to i64
  br label %10

8:                                                ; preds = %17
  %9 = zext nneg i32 %0 to i64
  br label %21

10:                                               ; preds = %3, %17
  %11 = phi i64 [ 0, %3 ], [ %18, %17 ]
  %12 = getelementptr inbounds i32, ptr %6, i64 %11
  %13 = load i32, ptr %12, align 4, !tbaa !6
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 2.500000e-01) #4
  %15 = icmp eq i32 %13, 0
  br i1 %15, label %17, label %16

16:                                               ; preds = %10
  store i32 %14, ptr %12, align 4, !tbaa !6
  br label %17

17:                                               ; preds = %16, %10
  %18 = add nuw nsw i64 %11, 1
  %19 = icmp eq i64 %18, %7
  br i1 %19, label %8, label %10, !llvm.loop !10

20:                                               ; preds = %21
  tail call void @llvm.stackrestore.p0(ptr %5)
  br label %30

21:                                               ; preds = %8, %21
  %22 = phi i64 [ 0, %8 ], [ %28, %21 ]
  %23 = phi i32 [ 0, %8 ], [ %27, %21 ]
  %24 = getelementptr inbounds i32, ptr %6, i64 %22
  %25 = load i32, ptr %24, align 4, !tbaa !6
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #4
  %27 = add nsw i32 %26, %23
  %28 = add nuw nsw i64 %22, 1
  %29 = icmp eq i64 %28, %9
  br i1 %29, label %20, label %21, !llvm.loop !13

30:                                               ; preds = %1, %20
  %31 = phi i32 [ %27, %20 ], [ 0, %1 ]
  ret i32 %31
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

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
