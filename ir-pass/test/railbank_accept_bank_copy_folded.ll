; railbank_accept_bank_copy_folded.ll — THE MEASUREMENT THAT DELETED D5
; ALLOW-LIST ENTRY (3).  bd `xdu2` / L-1a W1 (Track B, session 2026-09-15).
;
; `SCOPE_B.md` §5.1 designed the D5 allow-list with THREE entries, the third
; being *a further store into a `!cq.railbank` cell* — a bank-to-bank copy of
; the rail NAME, which emits no gate and clones nothing.  It was implemented and
; then measured to have NO REACHABLE SUBJECT AT THE `-O1` FLOOR, so it was
; REMOVED.  This file is the measurement, kept as the tripwire.
;
; THE SOURCE BELOW WRITES TWO ARRAYS.  `clang -O1` forwards the copy and DELETES
; `b1` OUTRIGHT: the module that reaches the pass has exactly ONE `alloca`, one
; `[Bank]` anchor and a measure loop reading `b0` directly.  There is no
; surviving store of a bank load into a bank cell anywhere, in this spelling or
; in any other this track could construct.
;
; ⚠ WHY THE ENTRY WAS REMOVED RATHER THAN LEFT IN.  An allow-list entry with no
; customer is Rule 12 hygiene defect (c) in its purest form — an ACCEPT DOOR in
; a Prime-Directive fence that no fixture can hold open.  Removing it NARROWS
; the accept (a module that somehow did carry a surviving bank-to-bank store now
; declines loudly), which is the safe direction.
;
; ⚠ AND IT TOOK A CUSTOMER OFF AN OPEN P1 WITH IT.  A surviving copy makes TWO
; names denote ONE rail, so measuring both banks emits `cqrt_measure_i1(h0)`
; TWICE on one qubit.  MEASURED ALSO WITHOUT ANY BANK
; (`trackB/probes/d5f_scalar_double_measure.c`: `cq_measure(q) + cq_measure(q)`,
; no array anywhere, compiles to the same double measurement on this binary AND
; on the pre-second-half one) — so that is bd `yiid`'s boundary, not this
; increment's.  This increment neither creates it nor adds to it.
;
; ⚠ THIS FILE IS A TRIPWIRE, NOT A COVERAGE ROW.  If a future `clang` stops
; folding the copy, the surviving second bank's store becomes an unadmitted D5
; reader, the module DECLINES, and this RUN line (which has no `not`) goes RED.
; Re-derive entry (3) THEN, with the bd `yiid` question answered — not before.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `…/trackB/probes/d5d_bank_to_bank_copy.c`:
;   #include "CQ.h"
;   int main(void) {
;       bool b0[3]; bool b1[3]; int s = 0;
;       for (int i = 0; i < 3; ++i) cq_theta(&b0[i], 0.5);
;       for (int i = 0; i < 3; ++i) b1[i] = b0[i];
;       for (int i = 0; i < 3; ++i) s += cq_measure(b1[i]);
;       return s;
;   }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR      --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CALLOC  --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CALLOCA --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS    --input-file=%t.ll %s
; RUN: env CQ_CTRL_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:     > /dev/null 2> %t.dbg
; RUN: %filecheck --check-prefix=CBANK --input-file=%t.dbg %s

; ⚠ ONE WHOLE-FILE PREFIX PER COUNTED SYMBOL.  `-O1` left ONE bank, so there is
; ONE carve anchor and ONE alloca — that is the whole finding.
; CBANK-COUNT-1: CQ_CTRL_DBG: railbank [Bank] cells=3 abi=i8 trips=3 at:
; CALLOCA-COUNT-1: alloca [3 x i32]
; CALLOC-COUNT-1: call i32 @cqrt_alloc_i1(

; IR: alloca [3 x i32], align 4, !cq.railbank
; IR: %h = call i32 @cqrt_alloc_i1(i1 false)
; IR: call i1 @cqrt_measure_i1(i32 %{{.*}})

; PURE NEGATIVES.  A name copy is not a rail copy, and nothing here is one.
; NOTS-NOT: cqrt_copy
; NOTS-NOT: cqrt_cnot
; NOTS-NOT: cq_template_
; NOTS-NOT: cqrt_free

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]
  %4 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 5.000000e-01) #2
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %4, align 1, !tbaa !6
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 3
  br i1 %10, label %12, label %2, !llvm.loop !12

11:                                               ; preds = %12
  ret i32 %20

12:                                               ; preds = %2, %12
  %13 = phi i64 [ %21, %12 ], [ 0, %2 ]
  %14 = phi i32 [ %20, %12 ], [ 0, %2 ]
  %15 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %13
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %17) #2
  %19 = zext i1 %18 to i32
  %20 = add nuw nsw i32 %14, %19
  %21 = add nuw nsw i64 %13, 1
  %22 = icmp eq i64 %21, 3
  br i1 %22, label %11, label %12, !llvm.loop !15
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind }

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
