
; control_swap_reject_select_mergephi_value_region.ll — DECLINE (bd `boi6` D-B /
; Track M). GREEN ON BOTH BINARIES, and the string is the PRE-EXISTING one.
;
; A φ that is a VALUE arm's merge (`if (b0) seed ^= 1;` on a `_Bool`) rather than
; a controlled rotation's. Track M's rung 0 requires
; `ClassArm/ClassArmFalse == ArmClass::InPlaceRotation`, because that is the ONE
; class whose emitter collapses the φ's two edges onto a single physical register
; (M-β). A VALUE arm's merge is a DATA MUX: the φ names no register, so there is
; nothing for `cqrt_cnot` to copy a basis label out of.
;
; ⚠ SAY WHAT ACTUALLY FIRES, not what would fire (Rule 11). MEASURED on both
; binaries, the string is `bare i1 register condition`, NOT `control flow` — an
; EARLIER fence owns this module: `classifyArms` refuses a VALUE arm under a bare
; rail condition (`kBareRailCondReason`, bd `fg9k`), so the region never enters
; the plan and the select's rung 0 is never reached. The row is therefore pinned
; as a DISCRIMINATOR (the widening moved neither the disposition nor the string),
; not as a proof that rung 0's class conjunct fires. RETIREMENT TRIGGER: when bd
; `fg9k` lands a rail-conditioned VALUE arm, this file's string changes and rung
; 0's class conjunct becomes the owner — re-derive it then, and check that it
; still DECLINES.

; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @example(i1 %u0) {
entry:
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext %u0, double 5.000000e-01)
  %seed = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %v = xor i1 %seed, true
  br label %merge
merge:
  %p = phi i1 [ %v, %arm ], [ %seed, %entry ]
  %sel = select i1 %p, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK: cq controlled lowering: bare i1 register condition under quantum control
