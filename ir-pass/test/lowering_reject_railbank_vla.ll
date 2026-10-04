; lowering_reject_railbank_vla.ll — DECLINE (bd `test_C_libtooling-xdu2` / L-1a Increment W1).
;
; Increment A boundary — a runtime `_Bool b[n]` needs a dynamic i8-to-i32
; storage rewrite, which this increment deliberately does not claim.
;
; Runtime `int b[n]` is now admitted when its classical extent equals the exact
; preparation and measurement bounds. This fixture remains a loud decline because
; its `alloca i8, i64 %n` cannot hold i32 rail handles without a separately-proven
; dynamic object rewrite. It is the explicit `_Bool b[n]` follow-up boundary.
;
; ⚠ RED-GREEN, AND THE RED HALF IS A BINARY. MEASURED: on the frozen 2026-09-14
; ORACLE (`cq-opt` sha256 5c6f7490…, from `c8007c37`) this exact module declines the
; GENERIC `cq taint escape: tainted value stored to memory`; on the subject
; (bc886235…) it declines the per-clause string below. BOTH ARE DECLINES — bd
; `xdu2` Increment W1 originally made a decline→decline STRING change. xdu2.4
; moves runtime i32 VLAs to accept while retaining this i8 width decline.
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
;   file stays a REJECT until a dynamic i8 object can be widened to i32 handle
;   storage without changing its byte extent or lifetime. Re-derive the allocation,
;   GEP, lifetime, and stackrestore proof together; do NOT inherit the int path."
;
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackL/probes/N1_vla_bound.c`:
;   /* dynamic-bool boundary: i8 storage cannot yet carry i32 handles */
;   #include "CQ.h"
;   __attribute__((noinline)) int slice(int n){ int a=5; bool b[n]; for(int i=0;i<n;++i){ b[i]=0; if(a>=3) cq_theta(&b[i],0.5); if(b[i]) a-=3; } return cq_measure(a)+cq_measure(b[0]); }
;   int main(void){ return slice(3); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq rail bank: array element is not a reversible rail cell
; CHECK-NOT: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = zext i32 %0 to i64
  %3 = alloca i8, i64 %2, align 16
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = zext nneg i32 %0 to i64
  br label %15

7:                                                ; preds = %23, %1
  %8 = phi i32 [ 5, %1 ], [ %27, %23 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #3
  %10 = load i8, ptr %3, align 16, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #3
  %13 = zext i1 %12 to i32
  %14 = add nsw i32 %9, %13
  ret i32 %14

15:                                               ; preds = %5, %23
  %16 = phi i64 [ 0, %5 ], [ %28, %23 ]
  %17 = phi i32 [ 5, %5 ], [ %27, %23 ]
  %18 = getelementptr inbounds i8, ptr %3, i64 %16
  store i8 0, ptr %18, align 1, !tbaa !6
  %19 = icmp sgt i32 %17, 2
  br i1 %19, label %20, label %23

20:                                               ; preds = %15
  %21 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #3
  %22 = zext i1 %21 to i8
  store i8 %22, ptr %18, align 1, !tbaa !6
  br label %23

23:                                               ; preds = %20, %15
  %24 = load i8, ptr %18, align 1, !tbaa !6, !range !10, !noundef !11
  %25 = trunc nuw i8 %24 to i1
  %26 = add nsw i32 %17, -3
  %27 = select i1 %25, i32 %26, i32 %17
  %28 = add nuw nsw i64 %16, 1
  %29 = icmp eq i64 %28, %6
  br i1 %29, label %7, label %15, !llvm.loop !12
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #2 {
  %1 = tail call i32 @slice(i32 noundef 3)
  ret i32 %1
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
