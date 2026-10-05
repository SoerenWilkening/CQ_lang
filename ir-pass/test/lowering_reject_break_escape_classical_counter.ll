; lowering_reject_break_escape_classical_counter.ll — DECLINE (bd
; test_C_libtooling-923w; found by the bd 3by9 Rule-11 review, round 1, F1).
; A 7.4 value-arm break whose loop COUNTER escapes through an exit φ and keys a
; branch phase after the loop. The module is lowering_loop_break_qq_phase.ll's
; `clang -O1` output plus, in the exit merge, the LCSSA φ of `i.next` and a
; phase under it (hand-added; `-O1` C does not reach it today: the unfused exit
; declines at L1, the AND / `slt` continue-polarity form at E2/E4, and a sunk use
; leaves no escape φ):
;
;     %iex = phi i32 [ 0, %7 ], [ %15, %10 ]     ; %15 = i.next
;     %c2  = icmp eq i32 %iex, 2
;     br i1 %c2, label %ph, label %end
;     ph:  call void @cq_phi(double 7.0e-01)
;
; THE MISCOMPILE THIS DECLINE REPLACES (measured on the 3by9 head dc192929:
; `cq-opt` exit 0, verify-clean, `ph` emptied). The 7.4 lowering realizes the
; break VIRTUALLY: `emitBreakForward` strips the tainted break flag from the loop
; terminator, so the rolled loop runs its FULL classical trip on every branch.
; The rail is safe (the index-gated capture copies the break value into `out`),
; but an UNTAINTED loop-variant value has no capture: `%iex` leaves the loop as
; its full-trip value n, not the source's value (the break iteration + 1, which
; is a function of q0 and p). With n = 4, `iex == 2` holds in the source exactly
; on the branches that break in iteration 1 (a relative phase); after the strip
; no tainted control is left above `ph`, so `deleteGlobalPhases` deletes it as
; global. The same φ lets `return cq_measure(q) + i` return n where the source
; returns the break index: a quantum-dependent value read with no measure.
;
; THE FENCE. B2 inspects only TAINTED exit φs. The emitter's precondition (E16)
; now refuses any value DEFINED IN the loop with a use outside it other than the
; escape φ itself, until such a value is lowered as a tainted control-merge
; value (the gap is bd 923w). It is the emitter's recognized-but-non-canonical
; decline, so it mirrors `kMsgBreakUnemittable` character for character. The
; loop-invariant twin (lowering_loop_break_escape_invariant_classical.ll) carries
; `n` out through the same φ position and still lowers.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop


target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @break_escape_counter(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #2
  %5 = icmp eq i32 %4, 3
  br i1 %5, label %6, label %7

6:                                                ; preds = %3
  tail call void @cq_phi(double noundef 3.000000e-01) #3
  br label %7

7:                                                ; preds = %6, %3
  %8 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #2
  %9 = icmp sgt i32 %2, 0
  br i1 %9, label %10, label %18

10:                                               ; preds = %7, %10
  %11 = phi i32 [ %15, %10 ], [ 0, %7 ]
  %12 = phi i32 [ %13, %10 ], [ %8, %7 ]
  %13 = xor i32 %12, 9
  %14 = icmp eq i32 %13, %4
  %15 = add nuw nsw i32 %11, 1
  %16 = icmp eq i32 %15, %2
  %17 = select i1 %14, i1 true, i1 %16
  br i1 %17, label %18, label %10, !llvm.loop !6

18:                                               ; preds = %10, %7
  %19 = phi i32 [ %8, %7 ], [ %13, %10 ]
  %iex = phi i32 [ 0, %7 ], [ %15, %10 ]
  %c2 = icmp eq i32 %iex, 2
  br i1 %c2, label %ph, label %end

ph:
  tail call void @cq_phi(double noundef 7.000000e-01) #3
  br label %end

end:
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #3
  ret i32 %20
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
