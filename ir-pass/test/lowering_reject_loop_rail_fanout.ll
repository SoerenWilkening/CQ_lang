; lowering_reject_loop_rail_fanout.ll — DECLINE / over-accept probe (issue dtzb;
; the Rule-13 adversarial review 2026-06-26 silent-miscompile finding). A
; loop-carried VALUE rail whose rail value is read by TWO in-place self-updates —
; one carried via the latch, one escaping to the measure:
;     int q = seed; cq_theta(&q, 0.25);
;     for (int i = 0; i < n; i++) { qn = q ^ 9; qm = q ^ 3; q = qn; }
;     return cq_measure(qm_last);
; This is FAN-OUT (Rule 8 no-cloning): `%q` is read by both `%qn = q ^ 9` (carried)
; and `%qm = q ^ 3` (escaping). The in-place collapse would serialize BOTH onto the
; single rail handle — `cqrt_xorc_i32(%h, 9); cqrt_xorc_i32(%h, 3)` — so the measure
; reads `q ^ 9 ^ 3 = q ^ 10`, NOT the source's `q ^ 3` (and the carried rail is
; corrupted too). VERIFY-CLEAN and trace-plausible, yet WRONG — exactly the
; unforgivable over-accept (the recognizer accepted this before the fan-out guard).
; In-place mutation requires LINEAR lineage (one forward in-place consumer); a
; fan-out of a superposed source needs an ancilla/`cqrt_cswap`, not in-place
; collapse. LOUD decline. LoopLowering OWNS the `Msg`; mirror CHARACTER-FOR-CHARACTER
; (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried rail has multiple in-place consumers
;
; And it is NEVER lowered to the serialized in-place form:
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=NOINPLACE
; NOINPLACE-NOT: cqrt_xorc

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @fanout(i32 %seed, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %qn = xor i32 %q, 9                             ; carried rail (latch)
  %qm = xor i32 %q, 3                             ; FAN-OUT 2nd read of %q, escapes
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop

exit:                                             ; preds = %entry, %loop
  %ans = phi i32 [ %q0, %entry ], [ %qm, %loop ]
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
