; spec_reject_consume_merge_source.ll — DECLINE, loud (bd
; test_C_libtooling-r2j3.37.1; the shape of
; control_classical_call_arm_accept_onward_spec_transitive.ll with `%q` dead).
; `z = outer(q, y)`, `outer(b, e) = b + inner(e)`, `y` the 6.5 merge rail of a
; classical-call arm under the condition `q > 3`. `q` is a dead user register and
; the chain is linear in it, but the source `inner(y)` reads `y`, which a
; condition on q's OLD value built: consuming `q` would leave the merge rail to be
; discharged against the new `q`. The decision asks `dependsOnTarget` of every
; other handle operand and fails loudly with the inlined `z = q + inner(y)`'s
; message (ruling-dm7f51-step1-departures-2026-10-15 Q2). A mutant that drops
; that check accepts here.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq in-place lowering: the source of a quantum reassignment depends on the dead register's old value
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
define i32 @inner(i32 %x) {
entry:
  %s = mul i32 %x, %x
  ret i32 %s
}

define i32 @outer(i32 %base, i32 %exp) {
entry:
  %i = call i32 @inner(i32 %exp)     ; round-1: classical subcall; round-2: __cq_q_inner_1
  %r = add i32 %base, %i
  ret i32 %r
}

define void @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %z = call i32 @outer(i32 %q, i32 %y)   ; re-planned 0b01 -> 0b11
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }


