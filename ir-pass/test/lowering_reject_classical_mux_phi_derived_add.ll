; lowering_reject_classical_mux_phi_derived_add.ll — DECLINE: classical-cond
; merge phi whose arm incoming is a tainted DERIVED value, not an in-place
; gate (test_C_libtooling-5j5 decline complement):
;     if (classical_c) q = q + 1;  measure(q);
;
; Looks like the headline lift shape, but the arm computes `add i32 %q, 1` —
; and a tainted add does NOT stay on the operand's register: ArithLowering
; lowers it to `cq_template_add_*` and RAUWs the add to the template CALL
; result, a FRESH rail handle (`h_op`). Post-lowering the phi incomings would
; be DIFFERENT handles (new rail vs base) — a real runtime-chosen data mux,
; never a renaming. The 5j5 wire resolution only peels collected
; cq_theta/cq_phi call sites (the only in-place ops), so the add incoming
; resolves to itself, bases differ, the lift refuses, and the wi5 decline
; fires.
;
; (A value-arm under QUANTUM control is the swap-route emitter's deferred
; method-B territory; under CLASSICAL control this shape needs a real owner
; for the rail-vs-base merge before it can ever accept — out of 5j5 scope.)
;
; Guard: TaintPropagation::declineClassicalMuxes. It OWNS the exact `Msg`
; string; this CHECK mirrors it character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %c, label %arm, label %merge            ; CLASSICAL condition
arm:
  %a1 = add i32 %q, 1                           ; lowers to a FRESH template rail
  br label %merge
merge:
  %p = phi i32 [ %a1, %arm ], [ %q, %entry ]    ; new-rail-or-base — real mux
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
