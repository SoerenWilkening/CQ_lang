; lowering_reject_live_record_valuearm_merge_out_masked.ll — DECLINE, BUT NOT BY
; THIS CAMPAIGN'S GUARD. The boundary pin for SEVERANCE CLASS 3, the value-arm
; merge out rail (M-A Increment 3, bd test_C_libtooling-6uqc).
;
; SOURCE — a real `br` diamond. The `volatile` load inside the arm is what makes
; it one: without a non-speculatable instruction there, `clang -O1` folds the
; whole thing into a `select` and the program becomes severance class 2 instead
; (lowering_reject_live_record_select_merge_out.ll — which ACCEPTED at HEAD).
;     volatile int off = 3;
;     int q = 0; cq_theta(&q, 0.5);
;     int m = 7;
;     if (q == 5) { m = off * 2 + 1; }     // value arm
;     int w = m; cq_theta(&w, 0.25);       // chained Ry on the merge out
;     return cq_measure(w);
;
; MEASURED AT HEAD AND AFTER INCREMENT 3 — verdict and message IDENTICAL:
;     cq controlled lowering: value-arm swap-route under quantum control
; from `ArmClassify`, long before the late live-record slot. So
; class 3 IS masked — but NOT by bd test_C_libtooling-lom0's
; "condition predates a non-diagonal gate", which is what the Increment-1 scope
; note said. See lowering_reject_live_record_switch_mux_out_masked.ll for the
; three-way correction.
;
; IF THIS FIXTURE EVER STARTS TO CARRY THE LIVE-RECORD MESSAGE, the value-arm
; path has been widened and the record walk's reach into the merge out rail (the
; `cqrt_copy_<W>` destination edge) is what must be re-verified first.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@off = global i32 3, align 4

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:
  %o = load volatile i32, ptr @off, align 4
  %s = shl nsw i32 %o, 1
  %v = or disjoint i32 %s, 1
  br label %merge

merge:
  %m = phi i32 [ %v, %arm ], [ 7, %entry ]
  %w = call i32 @cq_theta_si32(i32 %m, double 2.500000e-01)
  %r = call i32 @cq_measure_si32(i32 %w)
  ret i32 %r
}

; CHECK: error{{.*}}cq controlled lowering: value-arm swap-route under quantum control
