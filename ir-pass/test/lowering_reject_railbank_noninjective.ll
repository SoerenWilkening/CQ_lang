; lowering_reject_railbank_noninjective.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a Increment W1).
;
; clause C2′ — a VARIABLE but NON-INJECTIVE cell index (`b[i>>1]`, four trips over two cells).
;
; THE PRIME-DIRECTIVE CLAUSE. `SE.getSCEV(%21)` for `zext(lshr %16, 1)` is not an
; affine `{0,+,1}` add-recurrence of the loop, so two activations can write one cell —
; and then a later trip's SEED load reads a previously-stored HANDLE and the
; promotion (C5) forwards the wrong value.
;
; ⚠ `N5_double_write.c` (a CONSTANT index) is DEGENERATE for this clause and must not
; be used for it: `-O1` SROAs it into the scalar spelling and it takes the §3c clobber
; decline (bd `x5fp`) before the bank is ever seen. MEASURED on both binaries.
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
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackL/probes/N5b_noninjective_var_index.c`:
;   /* clause 2' negative, the REAL one: a VARIABLE but NON-INJECTIVE index (i>>1 hits
;      each cell twice), so a later trip's seed load is a previously-stored HANDLE. */
;   #include "CQ.h"
;   int main(void){ int a=5; bool b[2]={0}; for(int i=0;i<4;++i){ if(a>=3) b[i>>1]=cq_theta(b[i>>1],0.5); if(b[i>>1]) a-=3; } return cq_measure(a)+cq_measure(b[0])+cq_measure(b[1]); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq rail bank: cell index is not an injective per-iteration index
; CHECK-NOT: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [2 x i8], align 2
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %1) #3
  store i16 0, ptr %1, align 2
  br label %15

2:                                                ; preds = %27
  %3 = tail call i32 @cq_measure_si32(i32 noundef %34) #3
  %4 = load i8, ptr %1, align 2, !tbaa !6, !range !10, !noundef !11
  %5 = trunc nuw i8 %4 to i1
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #3
  %7 = zext i1 %6 to i32
  %8 = add nsw i32 %3, %7
  %9 = getelementptr inbounds i8, ptr %1, i64 1
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #3
  %13 = zext i1 %12 to i32
  %14 = add nsw i32 %8, %13
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %1) #3
  ret i32 %14

15:                                               ; preds = %0, %27
  %16 = phi i32 [ 0, %0 ], [ %35, %27 ]
  %17 = phi i32 [ 5, %0 ], [ %34, %27 ]
  %18 = icmp sgt i32 %17, 2
  br i1 %18, label %19, label %27

19:                                               ; preds = %15
  %20 = lshr i32 %16, 1
  %21 = zext nneg i32 %20 to i64
  %22 = getelementptr inbounds [2 x i8], ptr %1, i64 0, i64 %21
  %23 = load i8, ptr %22, align 1, !tbaa !6, !range !10, !noundef !11
  %24 = trunc nuw i8 %23 to i1
  %25 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %24, double noundef 5.000000e-01) #3
  %26 = zext i1 %25 to i8
  store i8 %26, ptr %22, align 1, !tbaa !6
  br label %27

27:                                               ; preds = %19, %15
  %28 = lshr i32 %16, 1
  %29 = zext nneg i32 %28 to i64
  %30 = getelementptr inbounds [2 x i8], ptr %1, i64 0, i64 %29
  %31 = load i8, ptr %30, align 1, !tbaa !6, !range !10, !noundef !11
  %32 = trunc nuw i8 %31 to i1
  %33 = add nsw i32 %17, -3
  %34 = select i1 %32, i32 %33, i32 %17
  %35 = add nuw nsw i32 %16, 1
  %36 = icmp eq i32 %35, 4
  br i1 %36, label %2, label %15, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

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
