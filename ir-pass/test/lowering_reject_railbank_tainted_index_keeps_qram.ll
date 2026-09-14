; lowering_reject_railbank_tainted_index_keeps_qram.ll — DECLINE, AND THE STRING IS
; PHASE 7.5's (bd `test_C_libtooling-xdu2` / L-1a Increment W1, clause C2).
;
; THE AXIS SEPARATOR, pinned as a NON-REGRESSION. Phase 7.5 QRAM owns a TAINTED
; index over classical memory; bd `xdu2`'s rail bank owns a CLASSICAL index over
; quantum cells. They are ORTHOGONAL and they must stay so: a tainted-index store
; must keep 7.5's OWN decline, not acquire a rail-bank one.
;
; ⚠ THIS FIXTURE'S VERDICT IS IDENTICAL ON BOTH BINARIES — that is the property.
; MEASURED: the frozen 2026-09-14 ORACLE (`cq-opt` sha256 5c6f7490…) and the subject
; (f2a9c0a4…) both print `cq QRAM access: array address has aliasing fan-out`,
; character for character. The `--implicit-check-not='cq rail bank:'` on the RUN line
; is what makes that a CHECK rather than a hope: if the rail-bank classifier ever
; claimed this input, the fixture goes red rather than silently re-owning 7.5's
; population.
;
; HOW THE SEPARATION IS ENFORCED, in two places on purpose:
;   (1) BY ORDER — `declineTaintEscapes` consults `railBankCarveVerdict` only after
;       `qramCarveVerdict` has answered `NotQram`, and for a STORE that answer
;       requires an UNTAINTED pointer operand;
;   (2) BY CONJUNCT — `railBankCarveVerdictImpl` additionally refuses a tainted
;       address gep and a tainted trailing index, calling `matchAddressGep` with
;       `requireTaintedIndex=false` and then requiring the NEGATION.
; (2) is redundant with (1) TODAY, and it is deliberate: L3's mirror is that a shared
; ordering premise which holds "for the callers it then had" is exactly what stops
; holding when a caller moves (`IMPL_D.md` §15.4, open at P1). The conjunct survives
; a reordering; the comment would not.
;
; ⚠ A `DS_Error` decline writes ZERO BYTES TO STDOUT (Rule 12 hygiene (b)); the
; property is pinned by the `not` on the RUN line, the exact message, and the
; implicit-check-not. `LLVMContext::diagnose` EXITS on the first `DS_Error`
; (bd `br4a`) — ONE diagnostic.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackL/probes/N4_tainted_index.c`:
;   /* clause 2 negative: a TAINTED index — 7.5's axis must keep its own decline */
;   #include "CQ.h"
;   int main(void){ int q=cq_theta(0,0.5); bool b[4]={0}; b[q&3]=cq_theta(b[q&3],0.5); return cq_measure(b[0]); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='cq rail bank:'
; CHECK: cq QRAM access: array address has aliasing fan-out

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  %3 = and i32 %2, 3
  %4 = zext nneg i32 %3 to i64
  %5 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %4
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = trunc nuw i8 %6 to i1
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef 5.000000e-01) #3
  %9 = zext i1 %8 to i8
  store i8 %9, ptr %5, align 1, !tbaa !6
  %10 = load i8, ptr %1, align 4, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #3
  %13 = zext i1 %12 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

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
