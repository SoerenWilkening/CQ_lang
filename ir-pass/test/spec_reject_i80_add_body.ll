; spec_reject_i80_add_body.ll — DECLINE PIN (bd vqlq, the Rule-13 F1 fence):
; a spec-candidate callee body with an i80 binary op OUTSIDE the four shipped
; rows (`i80BinaryInScope`: and/lshr/or/shl — exactly the promoted-union
; extraction/field-insert form). `add i80` has no template; without the fence
; it over-accepts into the clone (i80 is a recognized intermediate width) and
; declines only LATE at lowerOps naming the CLONE (the WI-1.13
; detect-mirrors-lowerOps gap, the exact class of the i128 compare fence).
; The fence declines EARLY, source-located at the offending body op. Made
; newly reachable by the vqlq value-bitcast carve.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %y = call i32 @w(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

define i32 @w(i32 %0) {
  %z = zext i32 %0 to i80
  %a = add i80 %z, 5              ; not in i80BinaryInScope — decline HERE
  %t = trunc i80 %a to i32
  ret i32 %t
}

; CHECK: error{{.*}}in function w{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported width)
; CHECK-NOT: __cq_q_w
