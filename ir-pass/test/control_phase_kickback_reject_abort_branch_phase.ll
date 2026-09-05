; control_phase_kickback_reject_abort_branch_phase.ll — DECLINE, and THE
; DISCRIMINATOR for `control_phase_kickback_abort_global_phase.ll`. bd
; test_C_libtooling-3qlq Inc 1, Rule-13 ROUND-2 finding F-R1-2.
;
;     void abort(void);
;     int slice(int u){ int q = cq_theta(u, 0.5);
;       if (q > 7) cq_phi(0.75);   // a GENUINE BRANCH phase (a P1 kickback region)
;       if (q == 5) abort();       // the 7.2 abort park
;       return cq_measure(q); }
;
; `clang -O1` output verbatim. The `q > 7` / `q == 5` pair is deliberate: with
; `q == 7` / `q == 5` (the shape the R1 lens tried) `clang -O1` FOLDS both `if`s
; into ONE `switch` with an abort case, which declines earlier at
; `control flow under quantum control` and never reaches the carrier at all. The
; ordered compare does not fold, so both regions survive and the fence is the
; thing that fires — MEASURED on the subject and on `fa96336`.
;
; WHY IT MUST DECLINE. The 7.2 park preserves ONLY the routed handle `Q`, and the
; §2.6 deferred-interaction question ("does the escaping value's lineage carry a
; RELATIVE PHASE?") is genuinely unanswered for it: `q`'s `q>7` branch carries a
; kickback phase, and the park does not assert it preserves that phase. Over-
; declining is safe (Prime Directive); this is the shape the F-L5-6 carrier
; widening exists for, and after F-R1-2 narrowed that carrier to genuine control
; dependence it is what keeps the narrowing from being a deletion.
;
; ⚠ READ THE PAIR TOGETHER. These two files differ in ONE respect — whether the
; `cq_phi` sits on an ARM of a tainted branch or on the path every returning
; execution takes — and they have opposite dispositions. That difference is
; exactly `controlDependentOnTaintedBranch`, and if a future change makes both
; accept or both decline, that predicate has been broken in one direction or the
; other.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

; CHECK: cq controlled lowering: phase-class value escaping under quantum control

; And it is that fence, not an earlier one — the two messages the R1 lens
; measured this shape falling into instead.
; CHECK-NOT: control flow under quantum control
; CHECK-NOT: nested control flow

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @slice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #2
  %3 = icmp sgt i32 %2, 7
  br i1 %3, label %4, label %5

4:                                                ; preds = %1
  tail call void @cq_phi(double noundef 7.500000e-01) #2
  br label %5

5:                                                ; preds = %4, %1
  %6 = icmp eq i32 %2, 5
  br i1 %6, label %7, label %8

7:                                                ; preds = %5
  tail call void @abort() #3
  unreachable

8:                                                ; preds = %5
  %9 = tail call i32 @cq_measure_si32(i32 noundef %2) #2
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1
declare void @abort() local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { nounwind }
attributes #2 = { nounwind }
attributes #3 = { noreturn nounwind }
