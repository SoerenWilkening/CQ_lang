; railbank_deadcell_accept_fixed.ll — ACCEPT (bd test_C_libtooling-xdu2.9).
;
; SOURCE: tests/e2e/railbank_deadcell_matrix.c CASE_DEAD_FIXED at clang -O1:
;   int c[3] = {0};
;   for (i<3) { int t = c[i]; cq_theta(&t, .25); if (c[i] != 0) c[i] = t; }
;   for (i<3) s += cq_measure(c[i]);
; The zero seed makes `c[i] != 0` CONSTANT FALSE. The promoter's own forwarding
; (PASS B) and fold (PASS F) turn the branch condition into `i1 true` (the -O1
; polarity is `icmp eq`, arm on the FALSE edge), and PASS H now resolves the merge
; φ to the SKIP edge's value — the seed literal — instead of minting
; `select true, 0, t`. The relocated store is CLASSICAL, the carve answers NotBank,
; no `!cq.railbank` is minted, and the measure loop reads classical memory
; (a never-quantum cq_measure lowers to its operand: no symbol, no trace line).
; The dead preparation still runs, per trip: alloc, Ry(θ), and the spine's
; Ry(−θ)+free — byte-identical to the ARRAY-FREE rolled twin (matrix CASE 16).
; Pre-fix: DECLINED `cq taint escape: tainted value muxed by a classical-condition
; select` (measured on the d0720cb1 oracle, cq-opt c6f61f80a5d524c6).
;
; RUN: env CQ_RAILBANK_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s -o %t.out.ll 2> %t.dbg
; RUN: %filecheck                      --input-file=%t.out.ll %s
; RUN: %filecheck --check-prefix=NEG   --input-file=%t.out.ll %s
; RUN: %filecheck --check-prefix=DBG   --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NODBG --input-file=%t.dbg %s
;
; CHECK:      %[[C:[0-9]+]] = alloca [3 x i32], align 4{{$}}
; CHECK:      %h = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %h)
; CHECK:      %cq.bank.addr = getelementptr inbounds [3 x i32], ptr %[[C]], i64 0, i64 %{{[0-9]+}}
; CHECK-NEXT: store i32 0, ptr %cq.bank.addr
; NEG-NOT: !cq.railbank
; NEG-NOT: select
; NEG-NOT: cqrt_measure
; DBG: CQ_RAILBANK_DBG: promote bank % in @slice header % cells=3 cell=i32 seed=zero loads=1 stores=1
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
  %2 = alloca [3 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %2) #5
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(12) %2, i8 0, i64 12, i1 false)
  br label %3

3:                                                ; preds = %1, %10
  %4 = phi i64 [ 0, %1 ], [ %11, %10 ]
  %5 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4, !tbaa !6
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01) #5
  %8 = icmp eq i32 %6, 0
  br i1 %8, label %10, label %9

9:                                                ; preds = %3
  store i32 %7, ptr %5, align 4, !tbaa !6
  br label %10

10:                                               ; preds = %9, %3
  %11 = add nuw nsw i64 %4, 1
  %12 = icmp eq i64 %11, 3
  br i1 %12, label %14, label %3, !llvm.loop !10

13:                                               ; preds = %14
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %2) #5
  ret i32 %20

14:                                               ; preds = %10, %14
  %15 = phi i64 [ %21, %14 ], [ 0, %10 ]
  %16 = phi i32 [ %20, %14 ], [ %0, %10 ]
  %17 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %15
  %18 = load i32, ptr %17, align 4, !tbaa !6
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #5
  %20 = add nsw i32 %19, %16
  %21 = add nuw nsw i64 %15, 1
  %22 = icmp eq i64 %21, 3
  br i1 %22, label %13, label %14, !llvm.loop !13
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
