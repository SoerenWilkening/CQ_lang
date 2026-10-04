; lowering_railbank_bankraw_cond_store.ll — the `BankRaw` VERDICT ANCHOR, clause
; C7(b) IN ISOLATION (bd `test_C_libtooling-de8n`, P1, closed 2026-09-15).
;
; ⚠ WHAT THIS FIXTURE IS FOR. `Bank` is the ACCEPT PREDICATE OF RECORD — the L8
; retirement trigger at `TaintPropagation.cpp` says the `Bank` arm "stops breaking
; and becomes a `continue`" when the L-1a taint rule + type rewrite + D5 allow-list
; land. Before clause C7 there was ONE accept-shaped verdict and it was STRICTLY
; WEAKER than the shape the type rewrite can serve. THIS MODULE IS THE PROOF:
;
;   for (i = 0; i < 3; ++i) { if (n > 0) { b[i] = z; cq_theta(&b[i], 0.5); } }
;   ...  s += cq_measure(b[i]);            // every cell, after the loop
;
; The store sits in a CONDITIONAL arm (block %6), so a trip whose condition is
; false VISITS cell `i` and writes NOTHING. C6 proves the index visits cells 0…N-1
; exactly once; it does NOT prove they are written — trip count is not write count.
; After the deferred `[3 x i8]` → `[3 x i32]` rewrite an unwritten cell reads as
; handle `0`, and `h0` is a LIVE RAIL in this runtime (`cqrt_alloc_i1(0) -> h0`),
; so that read is a live-qubit alias and the measure loop below would measure it.
;
; ⚠ C6's OWN COMMENT USED TO CLAIM THE WRITE. It ended *"cells 0…N-1 are each
; written exactly once"* — true of the PROMOTED shape (one unconditional store at
; the latch) and FALSE of the raw one, which is the owner's own program's shape.
; Corrected in `QramLowering.cpp` in the same change (L7-with-a-twist: a record
; correction that is not applied to the source is not a correction).
;
; ⚠ THE PROMOTER DOES NOT SAVE THIS MODULE, WHICH IS WHY THE CARVE MUST. There is
; no in-loop READ here, so `RailBankPromote`'s B8 ("nothing to forward") leaves the
; module byte-untouched — MEASURED `promo=0` on both binaries. A hazard nothing
; else refuses is the Prime Directive's own case.
;
; MEASURED, ORACLE vs SUBJECT, on the SAME stage-1 file
; (`trackA/probes/p1_cond_store_no_read.c`, `clang -O1`, verbatim below):
;   ORACLE   cq-opt 0e280fc6…  ->  carve=[Bank]     promo=0     <-- THE DEFECT
;   SUBJECT  cq-opt b6554935…  ->  carve=[BankRaw]  promo=0
; and the ISOLATION control `trackA/probes/p2_uncond_store_no_read.c` — the same
; program with the store UNCONDITIONAL — measures `[Bank]` on BOTH, so this file
; pins C7(b) and not "a bank with no in-loop read".
;
; ⚠ THIS IS STILL A DECLINE AND THE DECLINE DID NOT MOVE. `BankRaw` is NOT a
; reject: every clause C1–C6 held, `outMsg` stays null, and the module takes the
; same generic `cq taint escape: tainted value stored to memory` it took on the
; ORACLE. The ONLY observable is the env-gated `CQ_CTRL_DBG` anchor, which is why
; this fixture is written against it — Rule 12 hygiene defect (c), "a fixture that
; goes green because its subject no longer exists", is the live hazard for every
; verdict on this path. The `--implicit-check-not` closes the other direction: the
; string `railbank [Bank]` must NOT appear (note `[BankRaw]` does not contain it).
;
; ⚠ L8 RETIREMENT TRIGGER, character-for-character as the thing that will fire:
;   "When the L-1a taint rule + type rewrite + D5 allow-list land, the `Bank`
;   verdict stops falling through to `kMsgStore`. THIS FILE DOES NOT BECOME AN
;   ACCEPT — it is `BankRaw`, and `BankRaw` must keep declining in every future
;   half. If a later increment wants this program to compile, it must give the
;   promoter a normalisation that produces a TOTAL per-trip write (an X-bracketed
;   copy of the seed on the false edge, say) so the carve calls it `Bank` — never
;   by adding an accepting arm for `BankRaw` at the consumer."
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackA/probes/p1_cond_store_no_read.c`.
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='railbank [Bank]' --implicit-check-not='cq rail bank:'
; CHECK: CQ_CTRL_DBG: railbank [BankRaw] cells=3 abi=i8 trips=3 at:
; CHECK: cq taint escape: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %2) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %2, i8 0, i64 3, i1 false)
  %3 = icmp sgt i32 %0, 0
  br label %4

4:                                                ; preds = %1, %10
  %5 = phi i64 [ 0, %1 ], [ %11, %10 ]
  br i1 %3, label %6, label %10

6:                                                ; preds = %4
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %8 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %5
  %9 = zext i1 %7 to i8
  store i8 %9, ptr %8, align 1, !tbaa !6
  br label %10

10:                                               ; preds = %4, %6
  %11 = add nuw nsw i64 %5, 1
  %12 = icmp eq i64 %11, 3
  br i1 %12, label %14, label %4, !llvm.loop !10

13:                                               ; preds = %14
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %2) #4
  ret i32 %22

14:                                               ; preds = %10, %14
  %15 = phi i64 [ %23, %14 ], [ 0, %10 ]
  %16 = phi i32 [ %22, %14 ], [ 0, %10 ]
  %17 = getelementptr inbounds [3 x i8], ptr %2, i64 0, i64 %15
  %18 = load i8, ptr %17, align 1, !tbaa !6, !range !13, !noundef !14
  %19 = trunc nuw i8 %18 to i1
  %20 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %19) #4
  %21 = zext i1 %20 to i32
  %22 = add nuw nsw i32 %16, %21
  %23 = add nuw nsw i64 %15, 1
  %24 = icmp eq i64 %23, 3
  br i1 %24, label %13, label %14, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %2

2:                                                ; preds = %2, %0
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %5 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %3
  %6 = zext i1 %4 to i8
  store i8 %6, ptr %5, align 1, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 3
  br i1 %8, label %9, label %2, !llvm.loop !10

9:                                                ; preds = %2, %9
  %10 = phi i64 [ %18, %9 ], [ 0, %2 ]
  %11 = phi i32 [ %17, %9 ], [ 0, %2 ]
  %12 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %10
  %13 = load i8, ptr %12, align 1, !tbaa !6, !range !13, !noundef !14
  %14 = trunc nuw i8 %13 to i1
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %14) #4
  %16 = zext i1 %15 to i32
  %17 = add nuw nsw i32 %11, %16
  %18 = add nuw nsw i64 %10, 1
  %19 = icmp eq i64 %18, 3
  br i1 %19, label %20, label %9, !llvm.loop !15

20:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %17
}

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
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = !{i8 0, i8 2}
!14 = !{}
!15 = distinct !{!15, !11, !12}
