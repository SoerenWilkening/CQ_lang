; railbank_reject_load_as_branch_cond.ll — a bank cell read as a BRANCH
; CONDITION outside the writing loop.
;
; bd `xdu2` / L-1a Increment W1's PIECE 3 — THE D5 CONSUMER ALLOW-LIST (Track B,
; session 2026-09-15).  A rail parked in a bank cell is INVISIBLE to every
; SSA-shaped fence in the tree: `railWireClosure` has no memory hop (and MUST
; NOT be taught one — that trips `f2SeedPinnedByLiveRegister`'s retirement
; trigger and forces a from-scratch re-derivation of the F2 narrowing), and the
; rail/wire/uncompute machinery is MEMORY-BLIND by construction
; (`SCOPE_L1a.md` §4.1).  So the refusal is a POSITIVE ENUMERATION of admitted
; consumers and every other consumer declines:
;   (1) a `@cq_measure_<sfx>` call taking the load as its operand,
;   (2) that load's single-use storage-TRUNCATION cast whose one user is (1),
;   (3) a further store into a rail-bank cell.
;
; ⚠ A `DS_Error` DECLINE WRITES 0 BYTES TO STDOUT, so an IR-text `CHECK-NOT`
; here would be VACUOUS (Rule 12 hygiene defect (b)).  The property is pinned by
; the `not` INVERSION on the RUN line plus the character-for-character string.
;
; ⚠ RED ON THE PRE-SECOND-HALF BINARY, MEASURED, NOT ASSERTED: on
; `railbank-blockers` tip (`cq-opt` `b6554935…`) this module declines
; `cq taint escape: tainted value stored to memory` — a DIFFERENT string — so
; this fixture fails there.  That is the red half of its red-green.
;
; ⚠ WHY IT IS NOT MERELY UNIMPLEMENTED.  `hasTaintedCondBranch` reads the
; branch's SSA condition; with piece 1 in place that condition IS tainted, so
; control detection would CLAIM the region and route a rail it cannot see the
; wire of — and without piece 1 the arm simply runs as classical code over a
; live qubit's label.  Neither is a circuit anyone proved.  Declining is the
; Prime Directive answer and the widening is a separate, costed question.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `…/trackB/probes/d5a_load_as_branch_cond.c`:
;   #include "CQ.h"
;   int main(void) {
;       bool b0[3]; int a = 0;
;       for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
;       if (b0[0]) a = 1;
;       return a + cq_measure(b0[1]);
;   }
; (with `-g` the diagnostic is source-located at `d5a…:7:9`, the `if`.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq rail bank: unsupported reader of a rail-bank cell

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #3
  br label %11

2:                                                ; preds = %11
  %3 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %4 = zext nneg i8 %3 to i32
  %5 = getelementptr inbounds i8, ptr %1, i64 1
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = trunc nuw i8 %6 to i1
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #3
  %9 = zext i1 %8 to i32
  %10 = add nuw nsw i32 %9, %4
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #3
  ret i32 %10

11:                                               ; preds = %0, %11
  %12 = phi i64 [ 0, %0 ], [ %18, %11 ]
  %13 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef 5.000000e-01) #3
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %13, align 1, !tbaa !6
  %18 = add nuw nsw i64 %12, 1
  %19 = icmp eq i64 %18, 3
  br i1 %19, label %2, label %11, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

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
