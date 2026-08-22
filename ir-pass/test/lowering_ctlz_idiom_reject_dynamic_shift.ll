; lowering_ctlz_idiom_reject_dynamic_shift.ll — DECLINE (bd ww4c Inc 1, the Z3
; constant-amount probe). The accepted shape with ONE change: the shift amount is
; the runtime argument %n instead of the literal 1.
;
; Z3 requires a ConstantInt amount. A dynamic amount has no closed form the
; compiler can substitute at all — and if %n were itself tainted, or zero, the
; loop would not even terminate. This is the fence's floor, not a scope call.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_dynamic_shift(i32 %u, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ -1022, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl i32 %x, %n
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
