; lowering_reject_railbank_tainted_index_in_loop_keeps_qram.ll — DECLINE, AND THE
; STRING IS PHASE 7.5's (bd `test_C_libtooling-xdu2` / L-1a Increment W1, clause C2).
;
; THE AXIS SEPARATOR IN ITS STRONGEST FORM, and the reason there are two of these
; files. Its sibling `lowering_reject_railbank_tainted_index_keeps_qram.ll` is
; STRAIGHT-LINE, so the rail-bank classifier would have refused it at the
; `LI.getLoopFor(SI->getParent())` entry conjunct even with the taint conjunct
; deleted — i.e. that fixture alone does NOT isolate the axis. THIS module has BOTH
; of the rail bank's own structural conditions present (a bounded non-escaping
; `bool b[4] = {0}` alloca AND a classically-bounded enclosing loop) and differs
; from a rail bank in EXACTLY ONE respect: the cell index is quantum-derived.
;
; ⚠ IDENTICAL ON BOTH BINARIES — that is the property. MEASURED: the frozen
; 2026-09-14 ORACLE (`cq-opt` sha256 5c6f7490…) and the subject (bc886235…) both
; print `cq QRAM access: tainted-index memory access inside a loop`, character for
; character. The `--implicit-check-not='cq rail bank:'` is what makes that a CHECK
; rather than a hope.
;
; ⚠ IT ALSO PINS THE ORDER, which is the half a conjunct cannot express. The carve
; asks `qramCarveVerdict` FIRST; here 7.5 answers `Decline` (its own in-loop string)
; rather than `NotQram`, so `railBankCarveVerdict` is never consulted at all. If the
; two switches were ever transposed, this fixture goes red — which is precisely the
; L3-mirror failure (`IMPL_D.md` §15.4, open at P1) that a comment would not catch.
;
; ⚠ A `DS_Error` decline writes ZERO BYTES TO STDOUT (Rule 12 hygiene (b)); the
; property is pinned by the `not` on the RUN line, the exact message and the
; implicit-check-not. `LLVMContext::diagnose` EXITS on the first `DS_Error`
; (bd `br4a`) — ONE diagnostic.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/trackA/probes/A9_tainted_index_in_loop.c`:
;   /* Track A, clause C2 — the AXIS fixture in its strongest form: a TAINTED index
;      INSIDE a classically-bounded loop, i.e. both of the rail bank's own structural
;      conditions present and only the index axis different. Must keep 7.5's string. */
;   #include "CQ.h"
;   int main(void){ int q=cq_theta(0,0.5); bool b[4]={0};
;     for(int i=0;i<4;++i) b[(q+i)&3]=cq_theta(b[(q+i)&3],0.5);
;     return cq_measure(b[0]); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank:'
; CHECK: cq QRAM access: tainted-index memory access inside a loop

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  br label %8

3:                                                ; preds = %8
  %4 = load i8, ptr %1, align 4, !tbaa !6, !range !10, !noundef !11
  %5 = trunc nuw i8 %4 to i1
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #3
  %7 = zext i1 %6 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %7

8:                                                ; preds = %0, %8
  %9 = phi i32 [ 0, %0 ], [ %18, %8 ]
  %10 = add nsw i32 %9, %2
  %11 = and i32 %10, 3
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef 5.000000e-01) #3
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %13, align 1, !tbaa !6
  %18 = add nuw nsw i32 %9, 1
  %19 = icmp eq i32 %18, 4
  br i1 %19, label %3, label %8, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

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
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
