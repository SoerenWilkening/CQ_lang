; railbank_reject_classical_cond_bank.ll — a bank whose per-trip store is under
; a CLASSICAL condition.  bd `xdu2` / L-1a W1 (Track B, session 2026-09-15).
;
; The merge phi then has ONE tainted incoming and one untainted one.
; `liftOneRegisterMergePhi` clause (2) requires EVERY incoming tainted, so the
; lift refuses and `declineClassicalMuxes` owns it:
; `cq taint escape: tainted value muxed by a classical-condition phi`.  That is
; the right owner and the right string — the program asks for a cell that holds
; a rail on one path and a classical `0` on the other, which the rail model
; cannot name — and W1's second half must NOT take it away from that owner.
;
; ⚠ IT IS ALSO THE PIN FOR A CRASH ONE DELETION AWAY (`SCOPE_B.md` §5.3).
; `declineClassicalMuxes` SKIPS a `use_empty()` phi (its own comment calls a
; dead phi "a pure live-range extender").  If that merge phi ever became DEAD,
; the decline would DISAPPEAR, `lowerRotations`' cross-type RAUW would leave
; `phi i8 [ i32 %h, … ]`, and the run would end in
; `report_fatal_error("Broken module found")` — MEASURED, in both the `i1` and
; the `i8` spellings, on the pre-second-half binary.  In the shipped design the
; SURVIVING STORE is always the phi's user so the phi is never dead; "the store
; keeps the phi alive" is a premise a future DCE can falsify SILENTLY, and this
; file is what goes red when it does.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, VERBATIM, of
; `…/trackB/probes/b06_bank_classical_cond.c`:
;   #include "CQ.h"
;   int main(int argc, char **argv) {
;       (void)argv;
;       int a = argc;
;       bool b0[3];
;       for (int i = 0; i < 3; ++i) { if (a >= 3) b0[i] = cq_theta(b0[i], 0.5); }
;       return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]);
;   }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq taint escape: tainted value muxed by a classical-condition phi

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 4) i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %3) #3
  %4 = icmp sgt i32 %0, 2
  br label %22

5:                                                ; preds = %30
  %6 = load i8, ptr %3, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = trunc nuw i8 %6 to i1
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #3
  %9 = zext i1 %8 to i32
  %10 = getelementptr inbounds i8, ptr %3, i64 1
  %11 = load i8, ptr %10, align 1, !tbaa !6, !range !10, !noundef !11
  %12 = trunc nuw i8 %11 to i1
  %13 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %12) #3
  %14 = zext i1 %13 to i32
  %15 = add nuw nsw i32 %14, %9
  %16 = getelementptr inbounds i8, ptr %3, i64 2
  %17 = load i8, ptr %16, align 1, !tbaa !6, !range !10, !noundef !11
  %18 = trunc nuw i8 %17 to i1
  %19 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %18) #3
  %20 = zext i1 %19 to i32
  %21 = add nuw nsw i32 %15, %20
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %3) #3
  ret i32 %21

22:                                               ; preds = %2, %30
  %23 = phi i64 [ 0, %2 ], [ %31, %30 ]
  br i1 %4, label %24, label %30

24:                                               ; preds = %22
  %25 = getelementptr inbounds [3 x i8], ptr %3, i64 0, i64 %23
  %26 = load i8, ptr %25, align 1, !tbaa !6, !range !10, !noundef !11
  %27 = trunc nuw i8 %26 to i1
  %28 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %27, double noundef 5.000000e-01) #3
  %29 = zext i1 %28 to i8
  store i8 %29, ptr %25, align 1, !tbaa !6
  br label %30

30:                                               ; preds = %22, %24
  %31 = add nuw nsw i64 %23, 1
  %32 = icmp eq i64 %31, 3
  br i1 %32, label %5, label %22, !llvm.loop !12
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
