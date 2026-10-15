; railbank_promote_reject_inloop_hoisted_read.ll — bd `xdu2` / L-1a clause B4′ (the
; store-move licence) IN THE SPELLING `clang -O1` ACTUALLY EMITS.
; bd `test_C_libtooling-n74d`, P1, fixed 2026-09-15.
;
; ⚠ THE DEFECT THIS FILE EXISTS FOR. The clause that LICENSES MOVING THE STORE —
; "nothing non-rewritable may live inside `L`" — was keyed on the ADDRESS:
;     for (Instruction *I : NonRewritable)
;       if (Plan.L->contains(I->getParent())) return false;
; and `NonRewritable` receives the GEP of a constant-offset read, never that gep's
; LOADS. `-O1` LICM hoists a loop-invariant cell address to the preheader and
; LEAVES THE LOAD IN THE LOOP, so on the validated floor those are different
; blocks. MEASURED VERBATIM in the module below (`trackA/probes/
; c1_readcell1_inloop.c`, `clang -O1`):
;
;   %2 = getelementptr inbounds i8, ptr %1, i64 1     ; ENTRY block  -> NonRewritable
;   br label %6
;   6:                                                ; the loop
;     store i8 %13, ptr %9, align 1
;     %14 = load i8, ptr %2, align 1                  ; IN `L`, and never examined
;
; The predecessor fixture `railbank_promote_reject_inloop_other_read.ll` pins the
; DIRECT spelling (`%r0 = load i8, ptr %b`), where the instruction in
; `NonRewritable` IS the observation point — the one shape the clause did catch. So
; the `-O1` spelling had NEVER been tested. Rule 9 verbatim: *stock LLVM IR is not
; stable; never assume instruction placement* — and Rule 12's hygiene defect in its
; most expensive form, a green negative pinning a shape the validated floor does
; not emit.
;
; THE HAZARD, and it is CLASSICAL, which is why it is easy to miss: the promotion
; moves the activation's write to the activation's END. Here the body also reads
; `b[1]`. On the trip that writes cell 1 the source reads it AFTER the store; after
; the move it reads it BEFORE. `opt -verify` cannot see that, the value is not even
; quantum, and no rail fence in the tree looks at memory at all (`SCOPE_L1a.md`
; §4.1).
;
; ⚠⚠ WHAT THIS FIXTURE PINS, AND WHAT IT DOES NOT — READ THIS BEFORE TRUSTING IT
; GREEN. Today the carve refuses this module FIRST, at C6's in-loop-read-of-another-
; cell test (`cq rail bank: array has cells no iteration writes`), so `planBank`
; never reaches B4′ and the promoter would not fire even with the defect present.
; **This file therefore pins the `-O1` SHAPE and the promoter's non-firing; it does
; NOT isolate B4′.** The clause is isolated only under a MUTANT — delete C6's
; in-loop-read conjunct (`QramLowering.cpp`, the `SE.getSCEV(LIdx) != IdxS` arm) and
; rebuild — and that measurement was taken and is recorded in
; `…/session-2026-09-15-orchestrator/trackA/IMPL_A.md` §4 with both binaries' hashes:
; mutant + UNFIXED promoter fires and MOVES THE STORE PAST THE READ; mutant + FIXED
; promoter refuses. That is the M12-style mutant bd `n74d` asks a fix agent to take,
; and it is the red-green of record for this clause.
;
; ⚠ RETIREMENT TRIGGER, and it is the whole reason the clause was worth fixing
; while it is defence-in-depth: the first widening anyone will want here is letting
; the body read an ALREADY-WRITTEN cell (`if (b[i-1]) …`), which relaxes exactly
; C6's in-loop-read test. The day that lands, C6 stops refusing this module, B4′
; becomes the SOLE defence, and THIS FILE BECOMES AN ISOLATING NEGATIVE — change
; its DECLINE line then, and do not delete the DBG/NOTS prefixes.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackA/probes/c1_readcell1_inloop.c`.
;
;
; ⚠ bd `test_C_libtooling-01po.19` S1-S3 (2026-10-15, owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15` and
; `owner-ruling-01po19-rolled-design-2026-10-15`): the rolled WINDOW model
; (RailWindow.h) now claims this array, because it is a well-formed quantum array
; the one-store rail bank does not own. The rail-bank clause this file used to
; decline on protects the one-store model only; the window model replaces it, and
; until S4-S7 land the array declines with the list of steps it still needs
; (DECLINE -> DECLINE; the message below is mirrored character-for-character).
; RETIREMENT TRIGGER: each of S4-S7 that lands drops its name from the list; when
; the list empties this file becomes an ACCEPT with an analytic trace check.
; RUN: env CQ_RAILBANK_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:     -S %s > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=DBG     --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=NOTS    --input-file=%t.dbg %s
; RUN: %filecheck --check-prefix=DECLINE --input-file=%t.dbg %s

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  %2 = getelementptr inbounds i8, ptr %1, i64 1
  br label %6

3:                                                ; preds = %6
  %4 = tail call i32 @cq_measure_si32(i32 noundef 5) #4
  %5 = add nsw i32 %4, %16
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %5

6:                                                ; preds = %0, %6
  %7 = phi i64 [ 0, %0 ], [ %17, %6 ]
  %8 = phi i32 [ 0, %0 ], [ %16, %6 ]
  %9 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %7
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 5.000000e-01) #4
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %9, align 1, !tbaa !6
  %14 = load i8, ptr %2, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = zext nneg i8 %14 to i32
  %16 = add nuw nsw i32 %8, %15
  %17 = add nuw nsw i64 %7, 1
  %18 = icmp eq i64 %17, 3
  br i1 %18, label %3, label %6, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  %2 = getelementptr inbounds i8, ptr %1, i64 1
  br label %3

3:                                                ; preds = %3, %0
  %4 = phi i64 [ 0, %0 ], [ %14, %3 ]
  %5 = phi i32 [ 0, %0 ], [ %13, %3 ]
  %6 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %4
  %7 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = trunc nuw i8 %7 to i1
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 5.000000e-01) #4
  %10 = zext i1 %9 to i8
  store i8 %10, ptr %6, align 1, !tbaa !6
  %11 = load i8, ptr %2, align 1, !tbaa !6, !range !10, !noundef !11
  %12 = zext nneg i8 %11 to i32
  %13 = add nuw nsw i32 %5, %12
  %14 = add nuw nsw i64 %4, 1
  %15 = icmp eq i64 %14, 3
  br i1 %15, label %16, label %3, !llvm.loop !12

16:                                               ; preds = %3
  %17 = tail call i32 @cq_measure_si32(i32 noundef 5) #4
  %18 = add nsw i32 %17, %13
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %18
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
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}

; The promoter RAN (so the negatives below are not vacuous) and left the module
; byte-untouched: the hoisted address is still in the entry block and the in-loop
; observer still reads through it, AFTER the store, in SOURCE order.
; DBG: === CQ_RAILBANK_DBG: module after promoteRailBankCells fixpoint ===
; DBG:        %2 = getelementptr inbounds i8, ptr %1, i64 1
; DBG:        store i8 %13, ptr %9, align 1
; DBG-NEXT:   %14 = load i8, ptr %2, align 1

; NOTS-NOT: CQ_RAILBANK_DBG: promote bank
; NOTS-NOT: %cq.bank
; ⚠ `!cq.railbank` is deliberately NOT checked: this stage refuses this module, so
; a re-added metadata mint could never fire on it and the negative would be VACUOUS
; (Rule 12 hygiene defect (b)). It is checked on the ACCEPT fixtures instead.

; ⚠ THIS STRING IS THE CARVE'S, NOT THE PROMOTER'S — see the warning above.
; DECLINE: cq rail window: quantum array not lowered yet (bd 01po.19), needs S7 index alias versioning
