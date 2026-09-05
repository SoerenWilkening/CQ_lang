; lowering_ctlz_idiom_reject_body_call.ll — DECLINE (bd ww4c Inc 1, the Z6 probe,
; call flavour). The accepted shape plus ONE instruction: an in-loop `cq_phi`
; (Rz) on the shift recurrence.
;
; Z6 is far stricter than "no side effects": the loop must contain EXACTLY the
; two phis, the `shl`, the `add`, the `icmp` and the `br`, and nothing else. That
; is the measured shape of all three target loops, and anything beyond it is a
; shape whose closed form was never derived.
;
; The call flavour is the one that must not slip through, because an in-loop gate
; is not merely "an extra instruction" — it is a per-iteration UNITARY. Replacing
; the loop with a fixed four-op chain would emit the rotation a fixed number of
; times (or none), silently changing the circuit. It is also the boundary with
; the 799w/y05j rolled-in-place owners, whose whole vocabulary is in-loop cq_*
; calls; leaving it to them is correct, not a punt.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_body_call(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  call void @cq_phi(double 1.250000e-01)
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
