; railbank_reject_measure_width_pun.ll — A BANK CELL MEASURED AT A DIFFERENT
; WIDTH FROM THE RAIL THE BANK PARKED.  bd `xdu2` / L-1a W1, second half, Track
; B, session 2026-09-15.
;
; ⚠ THIS FIXTURE EXISTS BECAUSE THE INCREMENT SHIPPED THE OVER-ACCEPT FIRST AND
; ITS OWN SELF-REVIEW FOUND IT.  Before the width conjunct, this module compiled:
;
;     cqrt_alloc_i32(0) -> h0
;     cqrt_ry_i32(h0, 0x1p-1)          ... x3
;     cqrt_measure_i16(h0) -> 0        <-- an i32 rail measured at i16
;
; — the TRUNCATION GATE DROPPED ENTIRELY.  The register spelling of the same
; program (`trackB/probes/d5h_scalar_width_pun.c`: `int q; cq_theta(&q, .5);
; cq_measure((short) q);`, NO ARRAY ANYWHERE) emits
;
;     cq_template_trunc_i32_to_i16(h0) -> h1
;     cqrt_measure_i16(h1) -> 0
;
; on this binary AND on the ORACLE — a real reversible gate minting a NEW rail,
; which is then what is measured.  **A BANK MUST NEVER LOSE A GATE THE REGISTER
; SPELLING EMITS**, and nothing else in the tree would have seen it: `opt` exit
; 0, verify-clean, STRICT stage 2b `0 violation(s), 0 unproven`, a plausible
; nine-line trace.  It is the same family as the shipped PUN FENCE
; (`QramLowering.cpp`, `StoreVal->getType() != CellTy`): *a sub-width type-punned
; access would resolve the ABI width from the ORIGIN and mint a wrong-width gate
; stream — verify-clean and wrong.*
;
; THE FENCE, in two spellings that must move together (and say so at both sites):
;   * the D5 allow-list admits a storage TRUNCATION only to the RAIL type, and a
;     DIRECT measure of the load only when the cell type IS the rail type;
;   * the type rewrite's PASS 5 erases only a `trunc` TO THE RAIL TYPE.
; The rail width is carried in the `!cq.railbank` record itself, because after
; `lowerRotations`' cross-type RAUW the store's extension cast reads
; `zext i32 %h to i8` and its original source type is UNRECOVERABLE.
;
; ⚠ A `DS_Error` decline writes 0 BYTES TO STDOUT, so an IR-text `CHECK-NOT` here
; would be VACUOUS (Rule 12 hygiene defect (b)).  The property is pinned by the
; `not` INVERSION on the RUN line plus the character-for-character string.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `…/trackB/probes/d5g_width_pun_measure.c`:
;   #include "CQ.h"
;   int main(void) {
;       int b0[3]; int s = 0;
;       for (int i = 0; i < 3; ++i) cq_theta(&b0[i], 0.5);
;       for (int i = 0; i < 3; ++i) s += cq_measure((short) b0[i]);
;       return s;
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq rail bank: unsupported reader of a rail-bank cell

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %1) #3
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %3
  %5 = load i32, ptr %4, align 4, !tbaa !6
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #3
  store i32 %6, ptr %4, align 4, !tbaa !6
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 3
  br i1 %8, label %10, label %2, !llvm.loop !10

9:                                                ; preds = %10
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %1) #3
  ret i32 %18

10:                                               ; preds = %2, %10
  %11 = phi i64 [ %19, %10 ], [ 0, %2 ]
  %12 = phi i32 [ %18, %10 ], [ 0, %2 ]
  %13 = getelementptr inbounds [3 x i32], ptr %1, i64 0, i64 %11
  %14 = load i32, ptr %13, align 4, !tbaa !6
  %15 = trunc i32 %14 to i16
  %16 = tail call signext i16 @cq_measure_si16(i16 noundef signext %15) #3
  %17 = sext i16 %16 to i32
  %18 = add nsw i32 %12, %17
  %19 = add nuw nsw i64 %11, 1
  %20 = icmp eq i64 %19, 3
  br i1 %20, label %9, label %10, !llvm.loop !13
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #2

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
