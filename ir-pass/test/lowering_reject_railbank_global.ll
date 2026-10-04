; lowering_reject_railbank_global.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a Increment W1).
;
; clause C1 — a GLOBAL array is not a bounded non-escaping LOCAL object.
;
; `walkPtrOrigin` resolves `@g` to `OriginResult::Global`. A rail bank's cells are
; rails the pass must be able to own for the whole of their lifetime; a global's
; lifetime is the program's and its address is visible to every translation unit.
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
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackL/probes/N3_global_array.c`:
;   /* clause 1 negative: a GLOBAL (not a non-escaping alloca) */
;   #include "CQ.h"
;   bool g[3];
;   int main(void){ int a=5; for(int i=0;i<3;++i){ if(a>=3) cq_theta(&g[i],0.5); if(g[i]) a-=3; } return cq_measure(a); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq rail bank: cell address has no bounded local-array provenance
; CHECK-NOT: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global [3 x i8] zeroinitializer, align 1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  br label %3

1:                                                ; preds = %13
  %2 = tail call i32 @cq_measure_si32(i32 noundef %18) #2
  ret i32 %2

3:                                                ; preds = %0, %13
  %4 = phi i64 [ 0, %0 ], [ %19, %13 ]
  %5 = phi i32 [ 5, %0 ], [ %18, %13 ]
  %6 = icmp sgt i32 %5, 2
  br i1 %6, label %7, label %13

7:                                                ; preds = %3
  %8 = getelementptr inbounds [3 x i8], ptr @g, i64 0, i64 %4
  %9 = load i8, ptr %8, align 1, !tbaa !6, !range !10, !noundef !11
  %10 = trunc nuw i8 %9 to i1
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %10, double noundef 5.000000e-01) #2
  %12 = zext i1 %11 to i8
  store i8 %12, ptr %8, align 1, !tbaa !6
  br label %13

13:                                               ; preds = %7, %3
  %14 = getelementptr inbounds [3 x i8], ptr @g, i64 0, i64 %4
  %15 = load i8, ptr %14, align 1, !tbaa !6, !range !10, !noundef !11
  %16 = trunc nuw i8 %15 to i1
  %17 = add nsw i32 %5, -3
  %18 = select i1 %16, i32 %17, i32 %5
  %19 = add nuw nsw i64 %4, 1
  %20 = icmp eq i64 %19, 3
  br i1 %20, label %1, label %3, !llvm.loop !12
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

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
