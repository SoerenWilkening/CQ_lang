; control_swap_reject_select_mergephi_other_class.ll — DECLINE (bd `boi6` D-B /
; Track M, orchestrator ruling item 2). GREEN ON BOTH BINARIES — a discriminator.
;
; RUNG 0'S **CLASS** CONJUNCT, ISOLATED, and it is the conjunct that survived when
; `RailLadderProven` was dropped. The region here is genuinely CLAIMED — its
; condition is a compare (`icmp eq i32 %q, 1`) over a quantum register, exactly
; like `control_swap_accept_select_mergephi_cmp_cond_region.ll` — but its arm is a
; VALUE chain (`%v = xor i1 %seed, true`), not a controlled rotation. So
; `ClassArm`/`ClassArmFalse` is not `InPlaceRotation`, rung 0 finds no matching
; region, and gate 2 fires `control flow`.
;
; WHY THE CLASS IS THE RIGHT DISCRIMINATOR, in one sentence of physics:
; `InPlaceRotation` is the ONE class whose emitter COLLAPSES the merge φ's two
; edges onto a single physical register (it hoists the arm's theta and RAUWs the φ
; to it — M-β), which is what makes `cqrt_cnot(rail, bf)` a copy of one register's
; basis label. A VALUE arm's merge is a DATA MUX: the φ names no register, so
; there is nothing to copy a label out of and the merge would have to be built,
; not borrowed.
;
; ⚠ Read it with `..._mergephi_value_region.ll`, which is the same CLASS question
; reached under a BARE RAIL condition — there an EARLIER fence owns the module
; (`classifyArms` refuses a value arm on a rail, `bare i1 register condition`,
; bd `fg9k`), so that file pins a different string. Two spellings, two owners,
; one disposition. RETIREMENT TRIGGER (L8): when bd `fg9k` lands the value arm,
; re-derive BOTH and check that THIS one still declines — a value-arm merge φ is
; a data mux whatever the guard was.

; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %seed = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 9.000000e-01)
  %c = icmp eq i32 %q, 1
  br i1 %c, label %arm, label %merge
arm:
  %v = xor i1 %seed, true
  br label %merge
merge:
  %p = phi i1 [ %v, %arm ], [ %seed, %entry ]
  %sel = select i1 %p, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %sel)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %r = add i32 %m, %mq
  ret i32 %r
}

; CHECK: cq controlled lowering: control flow under quantum control
