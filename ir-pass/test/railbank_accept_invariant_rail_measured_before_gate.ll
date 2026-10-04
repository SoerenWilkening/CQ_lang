; railbank_accept_invariant_rail_measured_before_gate.ll — THE GREEN HALF.
;
; bd `xdu2` / L-1a W1, Rule-13 review F-1 (session 2026-09-15).  This module is
; `railbank_reject_measure_after_nondiagonal_on_parked_rail.ll` WITH ONE LINE
; MOVED: the measure loop runs BEFORE the second rotation instead of after.  It
; must keep ACCEPTING, and it is the fixture that proves the memory-hop fence
; separated **ORDERING** rather than banning the shape.
;
; ⚠ WHY THE DISTINCTION IS LOAD-BEARING.  Both modules park ONE LOOP-INVARIANT
; rail's name into all three cells, so both are equally "aliased".  If the
; refusal had been put on ALIASING / no-cloning grounds (N cells holding one
; handle) this module would decline too — and it is a VALID CIRCUIT whose
; emitted stream is BYTE-IDENTICAL to its array-free register twin
; (`bfix/probes/f07_register_legit_order.c`), a program the ORACLE `0e280fc6`
; ACCEPTS.  Declining it would be an over-decline of a valid circuit, which the
; owner's 2026-09-11 ruling calls a defect, not a margin.  The refusal is
; therefore the bd `3d8q` ORDERING question — *is a rail-relabelling gate
; scheduled between the park and the read?* — asked through
; `railBankParkedRails`.
;
; MEASURED, both directions, on the fix binary: this module ACCEPTS with the
; seven-line trace
;   cqrt_alloc_i32(1) -> h0 ; cqrt_ry_i32(h0, 0x1p-1) ; cqrt_measure_i32(h0) x3
;   ; cqrt_ry_i32(h0, 0x1.6666666666666p-1) ; cqrt_measure_i32(h0)
; which is BYTE-IDENTICAL (`diff` empty) to the ORACLE's trace for the register
; twin; and the one-line-later spelling DECLINES.
;
; ⚠ THE `cqrt_ry_i32(h0, 0.7)` BELOW IS A NON-DIAGONAL GATE THAT THE FENCE SEES
; AND RULES HARMLESS.  It is not invisible to the walk — it is returned as a
; candidate and `gateIsHarmless`' leg 1 proves it unreachable from the read.  A
; fixture whose accept came from the fence never looking would pin nothing, so
; the `CHECK` below pins that the gate IS EMITTED and the measures precede it.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `…/session-2026-09-15-orchestrator/bfix/probes/f06_bank_legit_order.c`:
;   int slice(int seed) {
;     int q = seed; cq_theta(&q, 0.5);
;     int b0[3]; int s = 0;
;     for (int i = 0; i < 3; ++i) b0[i] = q;
;     for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
;     cq_theta(&q, 0.7);
;     return s + cq_measure(q);
;   }
;   int main(void) { return slice(1); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR     --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CALLOC --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS  --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CRY    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS   --input-file=%t.ll %s

; The object is retyped to runtime handles and carries the membership record;
; the parked handle is stored, loaded back and MEASURED — and the 0.7 rotation
; is emitted AFTER that measurement, in `@main`'s source order.
; IR: alloca [3 x i32], align 4, !cq.railbank
; IR: %h = call i32 @cqrt_alloc_i32(i32 1)
; IR: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; IR: store i32 %h, ptr %{{.*}}, align 4
; IR: load i32, ptr %{{.*}}, align 4
; IR: call i32 @cqrt_measure_i32(
; IR: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; IR: call i32 @cqrt_measure_i32(i32 %h)

; ⚠ ONE WHOLE-FILE PREFIX PER COUNTED SYMBOL.  A positive count inside a
; NEGATIVE prefix WINDOWS every negative after it (Rule 12 hygiene defect (a),
; reproduced by four tracks in this session alone), and two counts in ONE prefix
; would be ORDERED and so would depend on block layout.  TWO functions survive
; (`@slice` and `@main`), each with one rolled write loop and one rolled measure
; loop, so the module-wide counts are 2 / 4 / 4.
; CALLOC-COUNT-2: call i32 @cqrt_alloc_i32(
; CMEAS-COUNT-4: call i32 @cqrt_measure_i32(
; CRY-COUNT-4: call void @cqrt_ry_i32(

; PURE NEGATIVES.  No rail is freed (both are Measured — Rule 6 leaves them
; allocated), no template is minted on a bank load, and the cells are handles.
; NOTS-NOT: cqrt_free
; NOTS-NOT: cq_template
; NOTS-NOT: cq_theta_
; NOTS-NOT: cq_measure_
;
; ⚠ ONE OF THESE NEGATIVES WAS **VACUOUS** AND WAS REPLACED, RECORDED HERE
; RATHER THAN QUIETLY FIXED (Rule 12 hygiene defect (c); CLAUDE.md L10 — an
; instrument's failure mode is to report a pass).  The first draft carried
; `NOTS-NOT: 3 x i8`, copied from the `_Bool`-bank fixtures where it pins the
; type rewrite.  THIS bank has `int` cells: `3 x i8` does not occur in this
; module's IR at ALL, before or after lowering, so the check could never have
; fired.  MEASURED (comments stripped): 0 occurrences in the input body, 0 in
; the lowered output.  The replacements are non-vacuous by the same
; measurement — `cq_theta_` / `cq_measure_` occur on 10 and 7 body lines of
; the INPUT respectively and on ZERO lines of the output, so they pin the
; pass's postcondition (`declineSurvivingIntrinsicCalls`: no
; `@cq_{theta,phi,measure}_<sfx>` may remain) on a module where a failure to
; lower the bank read is exactly how that postcondition would break.

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [3 x i32], align 4
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %2) #3
  br label %4

4:                                                ; preds = %1, %4
  %5 = phi i64 [ 0, %1 ], [ %7, %4 ]
  %6 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %5
  store i32 %3, ptr %6, align 4, !tbaa !6
  %7 = add nuw nsw i64 %5, 1
  %8 = icmp eq i64 %7, 3
  br i1 %8, label %13, label %4, !llvm.loop !10

9:                                                ; preds = %13
  %10 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  %12 = add nsw i32 %11, %19
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %2) #3
  ret i32 %12

13:                                               ; preds = %4, %13
  %14 = phi i64 [ %20, %13 ], [ 0, %4 ]
  %15 = phi i32 [ %19, %13 ], [ 0, %4 ]
  %16 = getelementptr inbounds [3 x i32], ptr %2, i64 0, i64 %14
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #3
  %19 = add nsw i32 %18, %15
  %20 = add nuw nsw i64 %14, 1
  %21 = icmp eq i64 %20, 3
  br i1 %21, label %9, label %13, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i32], align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %1) #3
  br label %3

3:                                                ; preds = %3, %0
  %4 = phi i64 [ 0, %0 ], [ %6, %3 ]
  %5 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %4
  store i32 %2, ptr %5, align 4, !tbaa !6
  %6 = add nuw nsw i64 %4, 1
  %7 = icmp eq i64 %6, 3
  br i1 %7, label %8, label %3, !llvm.loop !10

8:                                                ; preds = %3, %8
  %9 = phi i64 [ %15, %8 ], [ 0, %3 ]
  %10 = phi i32 [ %14, %8 ], [ 0, %3 ]
  %11 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %9
  %12 = load i32, ptr %11, align 4, !tbaa !6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #3
  %14 = add nsw i32 %13, %10
  %15 = add nuw nsw i64 %9, 1
  %16 = icmp eq i64 %15, 3
  br i1 %16, label %17, label %8, !llvm.loop !13

17:                                               ; preds = %8
  %18 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666) #3
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #3
  %20 = add nsw i32 %19, %14
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %1) #3
  ret i32 %20
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

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
