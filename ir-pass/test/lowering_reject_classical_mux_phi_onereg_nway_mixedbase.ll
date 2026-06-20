; lowering_reject_classical_mux_phi_onereg_nway_mixedbase.ll — DECLINE: N-ary
; classical-cond merge phi where one incoming resolves to a DIFFERENT wire base
; (test_C_libtooling-sbt1.3 decline complement; the N-ary sibling of
; lowering_reject_classical_mux_phi_tworeg.ll — pins the "all Chains[k].Base ==
; Chains[0].Base" requirement under N>2).
;
; Two arms resolve through the in-place cq_phi wire to base %q, but arm3's
; incoming %r2 resolves (through its own in-place cq_phi) to a SEPARATE
; theta-minted register %r. The lift requires EVERY incoming to share ONE base;
; a single mismatched base means the phi is a runtime ALIAS of two live
; quantum registers, not a renaming of one — which register a downstream
; gate/measure/adjoint targets is path-dependent with no static story, so the
; lift refuses and the wi5 decline fires (the same stance as the arity-2 tworeg
; fixture, now exercised on the N-ary path: a SINGLE off-base edge among N must
; sink the whole accept).
;
; Guard: TaintPropagation::declineClassicalMuxes. It OWNS the exact `Msg`
; string; this CHECK mirrors it character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 4, double 5.000000e-01)   ; SECOND register
  switch i32 %k, label %merge [               ; CLASSICAL scrutinee
    i32 1, label %arm1
    i32 2, label %arm2
    i32 3, label %arm3
  ]
arm1:
  %q1 = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)
  br label %merge
arm2:
  %q2 = call i32 @cq_phi_si32(i32 %q, double 7.500000e-01)
  br label %merge
arm3:
  %r2 = call i32 @cq_phi_si32(i32 %r, double 1.250000e-01)   ; resolves to %r, NOT %q
  br label %merge
merge:
  %p = phi i32 [ %q, %entry ], [ %q1, %arm1 ], [ %q2, %arm2 ], [ %r2, %arm3 ]
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
