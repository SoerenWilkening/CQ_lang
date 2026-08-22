; lowering_ctlz_idiom_reject_counter_nonconst_init.ll — DECLINE (bd ww4c Inc 1,
; the Z4 seed probe). The accepted shape with ONE change: the counter's preheader
; incoming is the runtime argument %c0 instead of a ConstantInt.
;
; Z4 requires C0 to be a ConstantInt because the emitted `sub` folds it to the
; LITERAL (C0 - 1) — the `_lh` shape cq_template_sub_i32_lh(C0-1, %m). A dynamic
; C0 is not un-lowerable in principle (it would be a QQ sub after a classical
; decrement), but it is outside the shipped accept shape and therefore declines:
; over-declining is safe, over-accepting is the silent miscompile.
;
; Note this asymmetry with the SHIFT recurrence, and that it is deliberate: the
; shift recurrence's preheader incoming is an OPAQUE Value the fence never
; inspects (PRD §5.4 — that is what makes the pre-shift invisible), while the
; COUNTER's preheader incoming must be constant. The two seeds play different
; roles in the closed form: v is the function's argument, C0 is its offset.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: loop under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @reject_nonconst_seed(i32 %u, i32 %c0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %loop

loop:                                             ; preds = %entry, %loop
  %ix = phi i32 [ %c0, %entry ], [ %dec, %loop ]
  %x = phi i32 [ %q, %entry ], [ %sh, %loop ]
  %dec = add nsw i32 %ix, -1
  %sh = shl nuw i32 %x, 1
  %pos = icmp sgt i32 %sh, 0
  br i1 %pos, label %loop, label %exit

exit:                                             ; preds = %loop
  %m = call i32 @cq_measure_si32(i32 %dec)
  ret i32 %m
}
