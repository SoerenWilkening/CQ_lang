; spec_reject_diamond_qq_cond.ll — Phase 6 / issue 5po2 (I1 over-accept probe): a
; diamond whose branch CONDITION is a quantum-quantum compare (`icmp %b, %c`,
; both params tainted) must decline. The clone select flag mint is the HL
; (handle+literal) form, which needs exactly ONE tainted compare operand; a Q+Q
; compare would mint a flag treating one handle as a literal (a silent-miscompile
; shape). Declined loudly by the explicit Q+Q fence in `lowerCloneSelect` — NOT
; left to an incidental downstream catch. A Q+Q compare condition is a separate
; capability, out of the shipped clone-control scope. Guards the flag-mint HL
; precondition.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %c) {
entry:
  %cc = icmp sgt i32 %b, %c
  br i1 %cc, label %then, label %else
then:
  %a1 = add i32 %b, 1
  %d1 = add i32 %b, 2
  br label %merge
else:
  %a2 = add i32 %b, 3
  %d2 = add i32 %b, 4
  br label %merge
merge:
  %pa = phi i32 [ %a1, %then ], [ %a2, %else ]
  %pd = phi i32 [ %d1, %then ], [ %d2, %else ]
  %r  = xor i32 %pa, %pd
  ret i32 %r
}

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  %r  = call i32 @helper(i32 %q, i32 %q2)
  %m  = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: cq specialization: quantum-quantum compare condition under quantum lift
