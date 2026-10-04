; lowering_reject_live_record_switch_mux_out_masked.ll — DECLINE, BUT NOT BY THIS
; CAMPAIGN'S GUARD. A boundary pin for severance class 2's SWITCH sub-case
; (M-A Increment 3, bd test_C_libtooling-6uqc).
;
; SOURCE: a `switch` whose case values are non-contiguous, so `clang -O1` keeps a
; real `switch` + merge phi instead of folding it into arithmetic (contrast
; lowering_reject_live_record_select_merge_tainted_src.ll, which is the folded
; spelling and DOES reach this campaign's guard):
;     int a = u0; cq_theta(&a, 0.5);
;     switch (a) { case 0: m=11; case 3: m=47; case 7: m=5; default: m=44; }
;     int w = m; cq_theta(&w, 0.25);  // chained Ry on the 4.5 data-mux out rail
;     return cq_measure(w);
;
; MEASURED AT HEAD AND AFTER INCREMENT 3 — the verdict and the message are
; IDENTICAL: this module declines in `SwitchClassify`, long before the late
; live-record slot, with
;     cq controlled lowering: control flow under quantum control
; So the 4.5 switch-data-mux out rail IS masked, by a guard of its own, and this
; file records WHICH guard so the next increment does not have to re-derive it.
;
; WHY THAT MATTERS FOR INCREMENT 4. `RotationLowering.h`'s Increment-1 scope note
; said severance classes (2) and (3) were masked by bd test_C_libtooling-lom0's
; position-free over-decline. Re-measured for Increment 3, that sentence is
; three different facts, not one:
;   * the `select` spelling of class 2 was NOT masked at all — a live over-accept
;     (lowering_reject_live_record_select_merge_out.ll);
;   * this `switch` spelling is masked, but by SwitchClassify's own control-flow
;     decline, not by lom0's "condition predates a non-diagonal gate";
;   * the value-arm `br` diamond (class 3) is masked by yet a third message
;     (lowering_reject_live_record_valuearm_merge_out_masked.ll).
; IF THIS FIXTURE EVER STARTS TO CARRY THE LIVE-RECORD MESSAGE INSTEAD, that is
; the switch path being widened; check that the record walk still reaches the
; data-mux out's copy sources before accepting the new verdict.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %def [
    i32 0, label %merge
    i32 3, label %c3
    i32 7, label %c7
  ]

c3:
  br label %merge

c7:
  br label %merge

def:
  br label %merge

merge:
  %m = phi i32 [ 44, %def ], [ 5, %c7 ], [ 47, %c3 ], [ 11, %entry ]
  %w = call i32 @cq_theta_si32(i32 %m, double 2.500000e-01)
  %r = call i32 @cq_measure_si32(i32 %w)
  ret i32 %r
}

; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
