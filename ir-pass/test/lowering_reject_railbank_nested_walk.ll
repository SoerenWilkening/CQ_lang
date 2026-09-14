; lowering_reject_railbank_nested_walk.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a W1).
;
; clause C2′, ONE ACTIVATION LEVEL UP — the bank's cell walk is RE-EXECUTED by an
; enclosing loop, so every cell is written once per OUTER trip and the second outer
; trip's SEED load reads a previously-stored HANDLE.
;
; ⚠ THIS FIXTURE EXISTS BECAUSE THE CLASSIFIER GOT IT WRONG, AND IT WAS FOUND BY
; THE INCREMENT'S OWN ADVERSARIAL SELF-ATTACK RATHER THAN BY ANY GREEN SUITE.
; MEASURED: on the FIRST subject binary (`cq-opt` sha256 53d1a4b6…) this module
; classified `Bank` — `CQ_CTRL_DBG: railbank [Bank] cells=3 abi=i8 trips=3` — with
; all 18 rail-bank fixtures green and the whole `ir-pass/test` corpus unmoved. The
; conjunct `L->getParentLoop()` was added in response, and the second subject
; (bc886235…) declines with the string below.
;
; THE LESSON IS L2's, and it is the reason this file is worth more than its verdict:
; *"when you WIDEN a set, ask what OTHER set was computed over the same closure."*
; Everything C2′ proves — `{0,+,1}`, start 0, step 1, a constant trip count equal to
; N — is a statement about ONE ACTIVATION of the walk loop. It says nothing at all
; about how many times that loop RUNS. The proof was complete and the closure it was
; proven over was not the one that mattered.
;
; ⚠ IT ALSO SUBSUMES A SECOND SELF-ATTACK. `H13_alloca_in_loop.c` declares the array
; INSIDE the outer loop body — a different C program, meant to reach the separate
; `isStaticAlloca()` conjunct — and `clang -O1` HOISTS the alloca to the entry block,
; so at the `-O1` floor the two programs are THE SAME IR SHAPE and both land here.
; The `isStaticAlloca()` conjunct is therefore pinned by hand IR instead
; (`lowering_reject_railbank_dynamic_object.ll`); it is not dead, it is off the floor.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY — TWICE. On the frozen 2026-09-14 ORACLE
; (5c6f7490…) this module declines the GENERIC `cq taint escape: tainted value stored
; to memory`; on the first subject (53d1a4b6…) it classified `Bank` and still printed
; that generic string; on the shipped subject (bc886235…) it declines below.
;
; ⚠ A `DS_Error` decline writes ZERO BYTES TO STDOUT (Rule 12 hygiene (b)); the
; property is pinned by the `not` on the RUN line plus the exact message, and by the
; `--implicit-check-not` proving the `Bank` anchor is GONE. `LLVMContext::diagnose`
; EXITS on the first `DS_Error` (bd `br4a`) — ONE diagnostic.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackA/probes/H1_nested_outer_rewrite.c`:
;   /* SELF-ATTACK H-1: the bank's walk loop is NESTED inside an outer loop, so every
;      cell is written TWICE and a later OUTER trip's seed load reads a stored HANDLE —
;      exactly the hazard C2' exists to prevent, one activation level up. */
;   #include "CQ.h"
;   int main(void){ bool b[3]={0};
;     for(int k=0;k<2;++k) for(int i=0;i<3;++i) b[i]=cq_theta(b[i],0.5);
;     int s=0; for(int i=0;i<3;++i) s+=cq_measure(b[i]); return s; }
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='railbank [Bank]'
; CHECK: cq rail bank: the cell walk is re-executed by an enclosing loop
; CHECK-NOT: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %2

2:                                                ; preds = %0, %4
  %3 = phi i32 [ 0, %0 ], [ %5, %4 ]
  br label %7

4:                                                ; preds = %7
  %5 = add nuw nsw i32 %3, 1
  %6 = icmp eq i32 %3, 0
  br i1 %6, label %2, label %17, !llvm.loop !6

7:                                                ; preds = %2, %7
  %8 = phi i64 [ 0, %2 ], [ %14, %7 ]
  %9 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %8
  %10 = load i8, ptr %9, align 1, !tbaa !9, !range !13, !noundef !14
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 5.000000e-01) #4
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %9, align 1, !tbaa !9
  %14 = add nuw nsw i64 %8, 1
  %15 = icmp eq i64 %14, 3
  br i1 %15, label %4, label %7, !llvm.loop !15

16:                                               ; preds = %17
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %25

17:                                               ; preds = %4, %17
  %18 = phi i64 [ %26, %17 ], [ 0, %4 ]
  %19 = phi i32 [ %25, %17 ], [ 0, %4 ]
  %20 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %18
  %21 = load i8, ptr %20, align 1, !tbaa !9, !range !13, !noundef !14
  %22 = trunc nuw i8 %21 to i1
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %22) #4
  %24 = zext i1 %23 to i32
  %25 = add nuw nsw i32 %19, %24
  %26 = add nuw nsw i64 %18, 1
  %27 = icmp eq i64 %26, 3
  br i1 %27, label %16, label %17, !llvm.loop !16
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
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
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = !{!10, !10, i64 0}
!10 = !{!"_Bool", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !7, !8}
!16 = distinct !{!16, !7, !8}
