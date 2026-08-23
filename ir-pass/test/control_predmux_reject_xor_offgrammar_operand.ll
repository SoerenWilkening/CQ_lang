; control_predmux_reject_xor_offgrammar_operand.ll — DECLINE (bd 3c6m.67): the
; xor widening is SCOPED TO ITS OPERANDS, not blanket. Here one operand of the
; branch-condition `xor i1` is a `trunc i32 %q to i1`, which is off-grammar for
; E6 `isSupportedCondTree` exactly as it was before this increment (it is neither
; a ConstantInt, a convertible i1 phi, a supported compare leaf, an and/or/xor
; node, nor a poison-shielded short-circuit select).
;
; The point of the fixture is that admitting the xor NODE must not smuggle in an
; operand the recogniser would otherwise refuse: `isSupportedCondTree` recurses
; into both xor children with the SAME grammar, so an off-grammar child still
; sinks the whole claim. Over-declining is always safe; over-accepting here
; would hand `buildNegation` a `trunc` it has no negation rule for and the
; emitter a value with no flag-mint shape (Prime Directive, Rule 1).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_cnot
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ca = icmp sgt i32 %q, 1
  %tr = trunc i32 %q to i1                 ; off-grammar operand
  %cc = xor i1 %ca, %tr
  br i1 %cc, label %inband, label %merge
inband:
  %v1 = add i32 %q, 1
  br label %merge
merge:
  %rm = phi i32 [ %q, %entry ], [ %v1, %inband ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
