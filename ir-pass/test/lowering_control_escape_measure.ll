; lowering_control_escape_measure.ll — Phase 4.1 WP17 (PRD §8.6, epic
; `-aht.2`), negative. MEASUREMENT under quantum control is rejected
; PERMANENTLY — a measurement gated on a superposed predicate is unphysical
; (you would have to measure the control first). This is Silq's rejected
; `condMeas`; Sturm forbids `measure` inside `when(q)`; Q#/Quipper refuse it.
; The verdict (PRD §8.6, confirmed against the Julia stack + literature) is the
; TERMINAL state, not a stopgap. Even though the arm RECONVERGES to the merge
; (so it is not a control-flow escape), the `@cq_measure_*` in the shadow is the
; escape: `armEscapesOrCollect` diagnoses at the measure.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}measurement under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 0
  br i1 %c, label %arm, label %merge
arm:
  %m = call i32 @cq_measure_si32(i32 %q)   ; measurement under quantum control
  br label %merge
merge:
  %y = phi i32 [ %m, %arm ], [ %a, %entry ]
  ret i32 %y
}
