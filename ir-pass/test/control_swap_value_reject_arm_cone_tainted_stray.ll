; control_swap_value_reject_arm_cone_tainted_stray.ll — DECLINE: the cone's (K1)
; conjunct (bd test_C_libtooling-fn1q, increment 1).
;
; `if (q > 5) { <a tainted computation on q that goes nowhere>; p += 3; }` — a
; TAINTED instruction in the arm that is not on the chain. It was a stray op
; before the increment and it must stay one: a tainted arm value the chain does
; not thread is a quantum value with no owner. `RegionFlatten` erases the arm
; BLOCK, so admitting it would DROP a quantum op (Rule 5) and dangle the taint
; work-list pointer that names it — the two hazards the stray rule was written for,
; neither of which the cone rule may inherit.
;
; ⚠ (K1) ALSO CARRIES THE COMPOSITION ARGUMENT, which is the part worth reading:
; because every cone member is UNTAINTED, no cone member can read a chain link
; (forward taint propagation would have tainted it), so the cone is strictly
; independent of the chain and hoisting it FIRST is sound by construction. That
; deduction is stated at `valueArmIsPureChain` AND asked there directly as a
; separate operand test — L1's rule, that one stage's conclusion must never be
; another stage's unstated premise.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %s1 = mul i32 %q, 9               ; (K1) — TAINTED, and not on the chain
  %s2 = add i32 %s1, 1              ; its only user, also in the arm
  %v1 = add i32 %p, 3               ; the chain
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: cq controlled lowering: impure value arm under quantum control
