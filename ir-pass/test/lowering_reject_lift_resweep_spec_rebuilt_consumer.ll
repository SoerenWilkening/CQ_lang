; bd test_C_libtooling-ec7r (Rule-13 r2 F-R2-1) — the lift re-sweep must run although
; `specialize()` ERASED the lift's only consumer (an fp-return spec call it rebuilt).
;
; THE DEFECT (a COMPOSITION of bd 8e5r x bd d88e; Rule-13 delta round r2, F-R2-1).
; The bd 2qyz post-lift stale-record re-sweep (`declineLiftedStaleRecordOps`) is a
; MODULE-WIDE re-run of `declineStaleRecordOps`, gated on "a one-register merge-phi
; lift occurred". bd d88e moved that re-sweep AFTER `specialize()`. bd 8e5r made the
; table the gate read, `taint.LiftedConsumers`, SELF-CLEANING — `empty()` counts LIVE
; members. `specialize()` -> `retargetSite` REBUILDS an fp-return spec call (fp result
; -> `i32` handle) and ERASES the old call; when that call was the lift's ONLY direct
; consumer the set went empty, the re-sweep was SKIPPED, and this module ACCEPTED on
; the merged tree (`c416f04d`, 3/3, allocator-independent) — while `main` before d88e
; (def1b088), 8e5r alone (818f8afa) and d88e alone (ba80bda1) all DECLINE it. A
; verdict move against `main` that exists only in the composition.
;
; THE FIX: the gate reads `taint.LiftedMergePhis` — d88e's per-lift RECORD, one entry
; pushed per accepted lift and never removed, so `!empty()` means "a lift occurred"
; whatever later happens to its consumers. Every lifted phi has >= 1 Instruction user
; (`declineClassicalMuxes` skips a `use_empty()` phi), so on every pre-merge binary
; "the raw consumer set is non-empty" and "a lift occurred" were the same fact; this
; restores exactly their verdicts. (Whether the re-sweep should be module-wide at all
; is the separate, pre-existing over-decline bd test_C_libtooling-3a43 / F-R2-3: the
; decline below is in `slice()`, the lift is in `main()` — this fixture pins the
; verdict main has, not a judgement that it is right.)
;
; Built from plain C, two TUs, `clang -O1` per TU + `llvm-link` (the reviewer's
; `build_probes.sh`, as `tests/e2e/run_slice_multi.sh` builds a multi-TU module).
; `slice()` is the shipped `e2e-slice-control-grover-loop-range-oracle` loop.
;
; Source (main TU; lib TU: `double h(int a, int k) { return (double)(a + k); }`):
;   double h(int a, int k);
;   __attribute__((noinline)) int slice(void) {
;       int a = 0; a = cq_theta(a, 0.5);
;       for (int i = 0; i < 2; ++i) {
;           if (a > 5 && a < 20) { cq_phi(3.14159265358979323846); }
;           a = cq_theta(a, -0.5);
;       }
;       return cq_measure(a);
;   }
;   int main(int c, char **v) {
;       int m = atoi(v[1]);
;       int q = cq_theta(m, .5);
;       if (m > 3) q = cq_theta(q, .2);    // the one-register merge-phi LIFT
;       double d = h(q, m);                 // its ONLY consumer: an fp-return spec site
;       return (int)cq_measure(d) + slice();
;   }
;
; Verdicts (3 runs each, `results` in TRACK_8E5R.md §15): def1b088 DECLINE, 818f8afa
; DECLINE, ba80bda1 DECLINE, c416f04d ACCEPT (the defect), this tree DECLINE.
; The twin with a SURVIVING consumer is `lowering_reject_lift_resweep_surviving_consumer.ll`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: <unknown>:0:0: in function slice i32 (): cq opcode lowering: operand predates a non-diagonal gate

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #5
  br label %4

2:                                                ; preds = %10
  %3 = tail call i32 @cq_measure_si32(i32 noundef %11) #5
  ret i32 %3

4:                                                ; preds = %10, %0
  %5 = phi i32 [ 0, %0 ], [ %12, %10 ]
  %6 = phi i32 [ %1, %0 ], [ %11, %10 ]
  %7 = add i32 %6, -6
  %8 = icmp ult i32 %7, 14
  br i1 %8, label %9, label %10

9:                                                ; preds = %4
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #5
  br label %10

10:                                               ; preds = %9, %4
  %11 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef -5.000000e-01) #5
  %12 = add nuw nsw i32 %5, 1
  %13 = icmp eq i32 %5, 0
  br i1 %13, label %4, label %2, !llvm.loop !6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !9
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #5
  %7 = icmp sgt i32 %5, 3
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.000000e-01) #5
  br label %10

10:                                               ; preds = %8, %2
  %11 = phi i32 [ %9, %8 ], [ %6, %2 ]
  %12 = tail call double @h(i32 noundef %11, i32 noundef %5) #5
  %13 = tail call double @cq_measure_f64(double noundef %12) #5
  %14 = fptosi double %13 to i32
  %15 = tail call i32 @slice()
  %16 = add nsw i32 %15, %14
  ret i32 %16
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define double @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = add nsw i32 %1, %0
  %4 = sitofp i32 %3 to double
  ret double %4
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = !{!10, !10, i64 0}
!10 = !{!"any pointer", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
