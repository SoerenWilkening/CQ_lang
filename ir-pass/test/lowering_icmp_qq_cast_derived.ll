; lowering_icmp_qq_cast_derived.ll — Phase 7.1 Increment A derived-operand
; positive (CAST source of HandleWidth). One QQ-compare operand is the result of
; a tainted `zext i8 -> i32`, whose handle records `HandleWidth = cw.To = i32`
; (the DEST width, recorded by CastLowering's extended `promote` — never
; `cw.From`/i8). It is compared `slt` against a second i32 theta handle (records
; i32). Both recovered widths AGREE (i32) → the bare-QQ
; `cq_template_icmp_slt_i32(i32, i32)` lowers.
;
; Shaping note (same forcing as lowering_sext_i8_to_i32.ll): RotationLowering
; runs BEFORE OpcodeLowering and launders every theta result to an i32 handle,
; so a cast reading a theta result DIRECTLY would capture an i32 source. To
; manufacture a width-preserved i8 source we `trunc i32 -> i8` first (its i8
; result type is read at phase-1 before the trunc itself lowers), then the
; `zext i8 -> i32` under test records cw.To = i32 on its result handle.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call i32 @cq_template_trunc_i32_to_i8(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_zext_i8_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_icmp_slt_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
;
; The zext result (logical DEST width i32) drives a QQ — not an HL — compare,
; and no garbage same-width cast appears.
; CHECK-NOT: = icmp slt
; CHECK-NOT: cq_template_icmp_slt_i32_hl(
; CHECK-NOT: cq_template_zext_i32_to_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 9, double 5.000000e-01)
  %b = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)
  ; Manufacture a width-preserved i8 source (its i8 result type is read at
  ; phase-1 before the trunc lowers), then the zext-under-test records
  ; cw.To = i32 on `%d`, so the QQ compare against `%b` recovers i32 on both.
  %n = trunc i32 %a to i8
  %d = zext i8 %n to i32
  %c = icmp slt i32 %d, %b
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
