; lowering_reject_stale_record_crossblock.ll — DECLINE: the straight-line
; stale-record shape with the pure producer in a LATER BLOCK than the chained
; theta (test_C_libtooling-uzb adversarial probe).
;
; Same wire as lowering_reject_stale_record_add.ll, but a (classical-
; condition) branch separates the chained Ry from the add, so the order proof
; is cross-block: `DT.dominates(add, theta)` is false (the theta's block
; dominates the add's), hence the add's template is NOT provably emitted
; before the Ry on any trace — it provably is not — and the guard declines.
; Position comparison via `Instruction::comesBefore` alone would be undefined
; across blocks; the dominance formulation handles multi-block layouts and
; conservatively declines anything it cannot prove (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, double %t2, i1 %cc) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double %g)
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained, in-place Ry
  br i1 %cc, label %tail, label %tail                 ; classical branch
tail:
  %d = add i32 %q, 1                                  ; SSA denotes the PRE-Ry record
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate
