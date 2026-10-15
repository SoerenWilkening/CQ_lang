; lowering_reject_railbank_nonzero_init.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a Increment W1).
;
; clause C1 — a NON-ZERO array initializer the rail model cannot represent.
;
; `-O1` spells `bool b[3] = {1,1,1}` as `llvm.memset(ptr %1, i8 1, i64 3)`. The rail
; model seeds every cell |0⟩; a non-zero fill seeds classical contents no rail
; carries, so a read of an un-overwritten cell would be 0 in the model and the fill
; in truth — the `processShadowAlloca` §2.6 argument in its rail form.
;
; ⚠ The COMPLEMENT of this fixture is OWNER RULING D1 (2026-09-14): an alloca with
; NO initializer at all IS admitted, composing with bd `z9t1`. That accept side is
; `lowering_railbank_bank_anchor_uninit.ll`; read the two together.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY. MEASURED: on the frozen 2026-09-14
; ORACLE (`cq-opt` sha256 5c6f7490…, from `c8007c37`) this exact module declines the
; GENERIC `cq taint escape: tainted value stored to memory`; on the subject
; (bc886235…) it declines the per-clause string below. BOTH ARE DECLINES — bd
; `xdu2` Increment W1 is a decline→decline STRING change and never an accept.
;
; ⚠ WHY THERE ARE NO IR-TEXT `CHECK-NOT`s. A `DS_Error` decline writes ZERO BYTES
; TO STDOUT, so an IR-text negative here would be VACUOUS (Rule 12 hygiene defect
; (b)): the property is pinned by the `not` inversion on the RUN line plus the
; character-for-character message match. And `LLVMContext::diagnose` EXITS on the
; first `DS_Error` (bd `br4a`), so this fixture pins exactly ONE diagnostic — the
; `CHECK-NOT` below is a stderr-text check that the GENERIC string did not fire,
; which is the whole delta against the ORACLE.
;
; ⚠ L8 RETIREMENT TRIGGER, character-for-character as the thing that will fire:
;   "When the L-1a taint rule + type rewrite + D5 allow-list land (bd `xdu2`, the
;   second half), the `Bank` verdict stops falling through to `kMsgStore`. THIS
;   file is a REJECT and is unaffected by that — but if its clause is ever
;   relaxed, its RUN line becomes an ACCEPT whose emitted stream is the per-trip
;   `cqrt_alloc_<W>` / `cqrt_ry_<W>` cascade. Re-derive it then; do NOT delete it."
;
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackA/probes/A1_nonzero_init.c`:
;   /* Track A, clause C1 negative: a NON-ZERO array initializer. The rail model seeds
;      every cell |0>; a non-zero fill seeds classical contents no rail can represent. */
;   #include "CQ.h"
;   int main(void){ int a=5; bool b[3]={1,1,1};
;     for(int i=0;i<3;++i){ if(a>=3) cq_theta(&b[i],0.5); if(b[i]) a-=3; }
;     int s=cq_measure(a); for(int i=0;i<3;++i) s+=cq_measure(b[i]); return s; }
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; (bd 01po.19 S6, 2026-10-15: S6 is built and leaves the needs list; this
; array now reaches the control chain, which refuses it loudly as below —
; the loop-carried `a >= 3` compare's wire gains the cell-controlled
; value arm `a -= 3`; over-decline bd 01po.19.20.)
; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
; CHECK-NOT: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 1, i64 3, i1 false)
  br label %4

2:                                                ; preds = %14
  %3 = tail call i32 @cq_measure_si32(i32 noundef %19) #4
  br label %23

4:                                                ; preds = %0, %14
  %5 = phi i64 [ 0, %0 ], [ %20, %14 ]
  %6 = phi i32 [ 5, %0 ], [ %19, %14 ]
  %7 = icmp sgt i32 %6, 2
  br i1 %7, label %8, label %14

8:                                                ; preds = %4
  %9 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef 5.000000e-01) #4
  %13 = zext i1 %12 to i8
  store i8 %13, ptr %9, align 1, !tbaa !6
  br label %14

14:                                               ; preds = %8, %4
  %15 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %5
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = add nsw i32 %6, -3
  %19 = select i1 %17, i32 %18, i32 %6
  %20 = add nuw nsw i64 %5, 1
  %21 = icmp eq i64 %20, 3
  br i1 %21, label %2, label %4, !llvm.loop !12

22:                                               ; preds = %23
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4
  ret i32 %31

23:                                               ; preds = %2, %23
  %24 = phi i64 [ 0, %2 ], [ %32, %23 ]
  %25 = phi i32 [ %3, %2 ], [ %31, %23 ]
  %26 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %24
  %27 = load i8, ptr %26, align 1, !tbaa !6, !range !10, !noundef !11
  %28 = trunc nuw i8 %27 to i1
  %29 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %28) #4
  %30 = zext i1 %29 to i32
  %31 = add nsw i32 %25, %30
  %32 = add nuw nsw i64 %24, 1
  %33 = icmp eq i64 %32, 3
  br i1 %33, label %22, label %23, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }
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
!15 = distinct !{!15, !13, !14}
