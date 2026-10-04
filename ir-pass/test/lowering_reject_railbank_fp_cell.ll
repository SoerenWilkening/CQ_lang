; lowering_reject_railbank_fp_cell.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a Increment W1).
;
; clause C3 — a `double` cell HAS an ABI width and has NO reversible copy.
;
; ⚠ THE `.empty()` TRAP, pinned. `abiWidthFromType(double)` returns "f64" — non-empty —
; so a width test spelled `abiWidthFromType(T).empty()` would ACCEPT this bank and then
; have no `cqrt_copy_f64` to merge its cells with. The clause is
; `widthHasReversibleCopy`, which is `{i1,i8,i16,i32,i64}` and nothing else
; (`OpcodeSupport.h` says the same of i128 in writing). The other half of the axis —
; a cell with NO width at all — is `lowering_reject_railbank_nowidth_cell.ll`.
;
; FILED, not hidden: an fp-cell bank is a legitimate C program and this is an
; OVER-DECLINE by the owner's 2026-09-11 ruling. It is out of W1's scope because the
; deferred type rewrite has no fp copy to build a merge on; see `IMPL_A.md` §9.
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
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackA/probes/A2_fp_cells.c`:
;   /* Track A, clause C3 negative: DOUBLE cells. abiWidthFromType gives "f64", which
;      widthHasReversibleCopy REFUSES (no cqrt_copy_f64) — the `.empty()` trap. */
;   #include "CQ.h"
;   int main(void){ double b[3]={0,0,0};
;     for(int i=0;i<3;++i) cq_theta(&b[i],0.5);
;     int s=0; for(int i=0;i<3;++i) s+=(int)cq_measure(b[i]); return s; }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq rail bank: array element is not a reversible rail cell
; CHECK-NOT: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x double], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %1) #4
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(24) %1, i8 0, i64 24, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = getelementptr inbounds [3 x double], ptr %1, i64 0, i64 %3
  %5 = load double, ptr %4, align 8, !tbaa !6
  %6 = tail call double @cq_theta_f64(double noundef %5, double noundef 5.000000e-01) #4
  store double %6, ptr %4, align 8, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 3
  br i1 %8, label %10, label %2, !llvm.loop !10

9:                                                ; preds = %10
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %1) #4
  ret i32 %17

10:                                               ; preds = %2, %10
  %11 = phi i64 [ %18, %10 ], [ 0, %2 ]
  %12 = phi i32 [ %17, %10 ], [ 0, %2 ]
  %13 = getelementptr inbounds [3 x double], ptr %1, i64 0, i64 %11
  %14 = load double, ptr %13, align 8, !tbaa !6
  %15 = tail call double @cq_measure_f64(double noundef %14) #4
  %16 = fptosi double %15 to i32
  %17 = add nsw i32 %12, %16
  %18 = add nuw nsw i64 %11, 1
  %19 = icmp eq i64 %18, 3
  br i1 %19, label %9, label %10, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare double @cq_measure_f64(double noundef) local_unnamed_addr #3

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
!7 = !{!"double", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
