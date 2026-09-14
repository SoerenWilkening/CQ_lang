; lowering_railbank_bank_anchor_promoted.ll — the `Bank` VERDICT ANCHOR (bd `test_C_libtooling-xdu2` / L-1a W1).
; STILL A DECLINE: `Bank` falls through to `kMsgStore` this increment.
;
; THE POST-PROMOTION SHAPE — what the carve sees once Track B's promoter lands.
;
; ⚠ THIS MODULE IS NOT A HAND CONSTRUCTION. It is `clang -O1` output for the
; equivalent C source, and that is the whole point (SCOPE_L1a §0 H3): the target form
; the per-activation promoter (clause C5) must produce is the STOCK `-O1` shape of
; the same program — exactly ONE store per trip, of the region's merge φ, at the
; trip's end, with the cell address having exactly ONE use.
;
; It is pinned HERE, on Track A's branch, so that the carve's verdict on the shape
; Track B will hand it is a MEASURED fact before the two branches ever meet — and so
; that a `clang` bump which changes that shape is visible as a red fixture rather
; than as a silent divergence between two tracks.
;
; ⚠ THIS IS THE `Bank`-VERDICT ANCHOR, AND IT EXISTS BECAUSE THE VERDICT'S
; OBSERVABLE BEHAVIOUR IS TODAY IDENTICAL TO DOING NOTHING AT ALL. Rule 12 hygiene
; defect (c) — "a decline fixture that goes green because its subject no longer
; exists pins nothing" — is the live hazard for this path: the module still declines
; `cq taint escape: tainted value stored to memory`, exactly as it does on the
; ORACLE, so a fixture checking only that string would pin NOTHING. What makes it
; non-vacuous is the env-gated `CQ_CTRL_DBG` line, which is byte-ABSENT on the
; ORACLE (`cq-opt` sha256 5c6f7490…) and present on the subject (bc886235…). MEASURED both
; ways; the `--implicit-check-not` on the RUN line closes the other direction.
;
; ⚠ THE `Bank` VERDICT STILL DECLINES, AND THAT IS A CORRECTNESS REQUIREMENT, NOT A
; SCOPE PREFERENCE. The taint rule (a `load` from a bank cell is tainted), the
; `[N x i1]` → `[N x i32]` type rewrite and the D5 consumer allow-list are the
; second half of L-1a. Until they land, an ACCEPTED bank is a SILENT MISCOMPILE by a
; named mechanism (`SCOPE_L1a.md` §4.4(D)): `cq_measure(b[i])` on an UNTAINTED load
; takes `MeasureLowering`'s classical split and emits no gate, no symbol and NO TRACE
; LINE — and the golden byte-diff cannot see a measurement that was never emitted.
; This is a STAGED LANDING of one capability, not Rule 17's punt.
;
; ⚠ L8 RETIREMENT TRIGGER, character-for-character as the thing that will fire:
;   "When the L-1a taint rule + type rewrite + D5 allow-list land (bd `xdu2`, the
;   second half), the `Bank` verdict stops falling through to `kMsgStore` and this
;   file's RUN line becomes an ACCEPT whose emitted stream is the per-trip
;   `cqrt_alloc_<W>` / `cqrt_ry_<W>` cascade with one `cqrt_measure_<W>` per cell.
;   Re-derive it then; do NOT delete it."
;
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackL/probes/L1_promoted_store.c`:
;   /* L1_promoted_store.c — Track L, 2026-09-14. READ-ONLY probe on ORACLE f7b65d8c (59ac5b7).
;      The post-promotion shape as SOURCE: exactly ONE store per trip, of the merge value,
;      at the trip's end — the shape the L-1a carve produces before the type rewrite. */
;   #include "CQ.h"
;   int main(void) {
;       int a = 5;
;       bool b[3] = {0};
;       for (int i = 0; i < 3; ++i) {
;           bool t = 0;
;           if (a >= 3) t = cq_theta(t, 0.5);
;           if (t) a -= 3;
;           b[i] = t;
;       }
;       int s = cq_measure(a);
;       for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
;       return s;
;   }
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank:'
; CHECK: CQ_CTRL_DBG: railbank [Bank] cells=3 abi=i8 trips=3 at:
; CHECK: cq taint escape: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)
  br label %4

2:                                                ; preds = %10
  %3 = tail call i32 @cq_measure_si32(i32 noundef %13) #4
  br label %19

4:                                                ; preds = %0, %10
  %5 = phi i64 [ 0, %0 ], [ %16, %10 ]
  %6 = phi i32 [ 5, %0 ], [ %13, %10 ]
  %7 = icmp sgt i32 %6, 2
  br i1 %7, label %8, label %10

8:                                                ; preds = %4
  %9 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  br label %10

10:                                               ; preds = %8, %4
  %11 = phi i1 [ %9, %8 ], [ false, %4 ]
  %12 = add nsw i32 %6, -3
  %13 = select i1 %11, i32 %12, i32 %6
  %14 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5
  %15 = zext i1 %11 to i8
  store i8 %15, ptr %14, align 1, !tbaa !6
  %16 = add nuw nsw i64 %5, 1
  %17 = icmp eq i64 %16, 3
  br i1 %17, label %2, label %4, !llvm.loop !10

18:                                               ; preds = %19
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %27

19:                                               ; preds = %2, %19
  %20 = phi i64 [ 0, %2 ], [ %28, %19 ]
  %21 = phi i32 [ %3, %2 ], [ %27, %19 ]
  %22 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %20
  %23 = load i8, ptr %22, align 1, !tbaa !6, !range !13, !noundef !14
  %24 = trunc nuw i8 %23 to i1
  %25 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %24) #4
  %26 = zext i1 %25 to i32
  %27 = add nsw i32 %21, %26
  %28 = add nuw nsw i64 %20, 1
  %29 = icmp eq i64 %28, 3
  br i1 %29, label %18, label %19, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

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
