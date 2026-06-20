; lowering_reject_classical_mux_phi_onereg_nway_mixed_incoming.ll — DECLINE:
; N-ary classical-cond merge phi mixing tainted handles with an UNTAINTED
; literal (test_C_libtooling-sbt1.3 decline complement; the N-ary sibling of
; lowering_reject_classical_mux_phi_measured.ll — pins "every incoming tainted"
; under N>2).
;
; Two arms route the in-place-rotated handle to base %q, but the default
; incoming is the literal 5: at runtime %p is handle-or-literal-5, a real data
; mux on the handle domain (the survivor would `cqrt_measure_i32` a value that
; is sometimes a literal, never a register). A SINGLE untainted incoming among
; N must sink the whole accept — the lift requires every incoming tainted — so
; it refuses and the wi5 decline fires. (Pre-guard this exact shape, at arity 2,
; was a confirmed verify-clean SILENT miscompile — phi_measured.)
;
; Guard: TaintPropagation::declineClassicalMuxes. It OWNS the exact `Msg`
; string; this CHECK mirrors it character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %k, label %merge [               ; CLASSICAL scrutinee
    i32 1, label %arm1
    i32 2, label %arm2
  ]
arm1:
  %q1 = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
  br label %merge
arm2:
  %q2 = call i32 @cq_phi_si32(i32 %q, double 7.500000e-01)
  br label %merge
merge:
  %p = phi i32 [ 5, %entry ], [ %q1, %arm1 ], [ %q2, %arm2 ]  ; default edge: untainted literal
  %m0 = call i32 @cq_measure_si32(i32 %q)     ; base measured -> FreePoint net bypassed
  %m1 = call i32 @cq_measure_si32(i32 %p)     ; "handle-or-5" measured as a handle
  %r = add i32 %m0, %m1
  ret i32 %r
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
