; lowering_reject_loop_value_accum_two_quantum.ll — DECLINE / over-accept probe
; (issue dtzb): an INTEGER add whose opcode dtzb DOES recognize, but where BOTH
; operands are tainted (a two-quantum accumulate, not a classical-immediate
; self-update):
;     int q = cq_theta(seed, 0.25);
;     int acc = 0;
;     for (int i = 0; i < n; i++) acc = acc + q;    // both operands quantum
;     return cq_measure(acc);
; This is the X1 dirty rail proper. dtzb's in-place strategy applies ONLY to a
; rail self-update with a CLASSICAL immediate (`q = q + c`) — the in-place
; constant adder. A two-quantum `acc + q` is the general in-place Cuccaro-adder
; case (acc <- acc + q over a LIVE quantum operand), a deferred follow-on, NOT
; this v1. The recognizer's "exactly one tainted operand" guard MUST reject it (a
; `cqrt_addc(acc, q)` with a quantum `q` in the immediate slot is a verify-clean
; silent miscompile — the immediate must be classical). It stays the existing X1
; decline. Mirror CHARACTER-FOR-CHARACTER (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried tainted value crosses iterations
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=NOINPLACE
; NOINPLACE-NOT: cqrt_addc
; NOINPLACE-NOT: cqrt_xorc

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @twoq(i32 %seed, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

exit:                                             ; preds = %entry, %loop
  %accx = phi i32 [ 0, %entry ], [ %accn, %loop ]
  %m = call i32 @cq_measure_si32(i32 %accx)
  ret i32 %m

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %accn, %loop ]
  %accn = add i32 %acc, %q0                        ; BOTH operands tainted (two-quantum)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop
}
