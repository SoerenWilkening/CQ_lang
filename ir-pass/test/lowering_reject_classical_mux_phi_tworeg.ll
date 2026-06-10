; lowering_reject_classical_mux_phi_tworeg.ll — DECLINE: classical-cond merge
; phi over TWO DISTINCT registers (test_C_libtooling-5j5 decline complement;
; the phi sibling of lowering_reject_classical_mux_select_alltainted_main.ll).
;
; `%p = phi i32 [ %q1, %a ], [ %q2, %b ]` joins two SEPARATE theta-minted
; registers under a classical branch: a runtime-chosen ALIAS of two live
; quantum registers. The 5j5 wire resolution stops at each classical-operand
; theta (the register's mint point IS its base), yielding two DIFFERENT
; bases — not a renaming of one register, so the lift refuses and the wi5
; decline fires: which register a downstream gate/measure/adjoint targets is
; path-dependent, with no static story.
;
; Guard: TaintPropagation::declineClassicalMuxes. It OWNS the exact `Msg`
; string; this CHECK mirrors it character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i1 %c) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 3, double 2.500000e-01)
  %q2 = call i32 @cq_theta_si32(i32 4, double 7.500000e-01)
  br i1 %c, label %a, label %b                  ; CLASSICAL condition
a:
  br label %merge
b:
  br label %merge
merge:
  %p = phi i32 [ %q1, %a ], [ %q2, %b ]         ; two registers — real data mux
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
