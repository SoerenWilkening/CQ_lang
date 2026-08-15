; lowering_reject_io_controlled_undef_coarg.ll — DECLINE (bd c4ow).
; ARM: the SAME `collectTapeTargets` fence, reached from the OTHER caller —
; `lowerControlledIOSinks`, which validates once per arm.
;
; WHY A SECOND FIXTURE FOR ONE `if`. The fence lives inside the shared validator,
; so this file does not pin a second guard; it pins the Rule-14 SHARING — that the
; controlled emitter still routes its argument validation through
; `collectTapeTargets` rather than growing a parallel copy. If someone ever
; inlines a private arg check into `lowerControlledIOSinks`, the uncontrolled
; fixture stays green and only this one goes red. That is the whole job.
;
; It also pins the CLAIM-TIME placement on the path where it matters most: the
; controlled emitter mints a flag, allocates a tape and emits controlled writes,
; so a fence that ran late would leave a half-emitted stream. `collectTapeTargets`
; is called at step 5, BEFORE step 7a mints the flag — the first `CreateCall` on
; this path — so `opt` exits with nothing emitted.
;
; Shape is `lowering_io_controlled_printf_sgt.ll` with ONE token added: a second,
; `undef` printf argument. That fixture is this one's reach control and stays
; green.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq I/O output sink: classical argument is undef/poison, not a compile-time known value

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [7 x i8] c"%d %d\0A\00"

define void @slice(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %q, i32 poison)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %m = call i32 @cq_measure_si32(i32 %q)
  ret void
}
