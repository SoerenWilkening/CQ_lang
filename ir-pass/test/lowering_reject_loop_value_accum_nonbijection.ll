; lowering_reject_loop_value_accum_nonbijection.ll — DECLINE / over-accept probe
; (issue dtzb): a loop-rail self-update whose immediate operand is CLASSICAL and
; whose shape otherwise matches the in-place value rail, but whose opcode is NOT a
; reversible bijection:
;     int q = cq_theta(seed, 0.25);
;     for (int i = 0; i < n; i++) q = q & 5;        // AND is lossy, not a bijection
;     return cq_measure(q);
; `and`/`or`/`mul`/`shl`/`lshr` are NOT bijections of the rail (they lose
; information), so they have no in-place reversible form — only add/xor (and the
; constant-shift/rotate family, deferred) qualify. dtzb's recognizer keys on the
; opcode being add/xor; `and` falls through and the rail stays the X1
; cross-iteration dirty rail (a fresh out-of-place `cq_template_and` handle per
; iteration). The recognizer MUST NOT mis-lower it to an in-place op — that would
; be a verify-clean silent miscompile (`cqrt_andc` does not and must not exist).
; Over-declining is safe (Prime Directive). LoopLowering OWNS the `Msg`; mirror
; CHARACTER-FOR-CHARACTER (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: loop-carried tainted value crosses iterations
;
; And it is NEVER lowered to a (non-existent) in-place form:
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=NOINPLACE
; NOINPLACE-NOT: cqrt_andc
; NOINPLACE-NOT: cqrt_xorc
; NOINPLACE-NOT: cqrt_addc

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @nonbij(i32 %seed, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %seed, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

exit:                                             ; preds = %entry, %loop
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %qn = and i32 %q, 5                             ; NON-bijection self-update
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop
}
