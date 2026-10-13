; spec_intermediate_unc_reject_kept_flag_unsynthesizable.ll — DECLINE (bd
; test_C_libtooling-p3kd.13): the decline twin of the re-derived accept
; control_inplace_ry_reject_cond_register_lifted_chain.ll.
;
;     if (inner(q) > 13) cq_theta(&q, .9);   return cq_measure(q);
;
; With a twin-synthesizable callee that module now ACCEPTS: the lifted chain rail
; is discharged by its Bennett twin between the flag mint and the controlled Ry,
; and only the owner-ruled kept flag stands at the gate. Here `@inner` carries an
; undef-derived scratch computation, so no twin can be synthesized (CloneProducer.h
; (P3), the bd xy9n duplication hazard), the chain rail `3q + 1` — an injective
; record of the pre-Ry q — stays at the gate, and the kept-flag postcondition
; `declineUndischargedKeptFlagChains` (RotationLowering.h, bd dm7f.4) refuses the
; module with R4's string, exactly as it refused every lifted chain before
; p3kd.13. A wrong unitary declined, never warned (the flag's lyyf ruling covers
; the flag and nothing else). The open gap — a twin for this body — is the
; follow-up drafted in the p3kd.13 report.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: warning
; CHECK: error: {{.*}}cq controlled lowering: rotation arm on a condition wire under quantum control
; CHECK-NOT: warning

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal fastcc i32 @inner(i32 %x) {
  %c = xor i32 undef, 7          ; undef-DERIVED scratch, never returned
  %y = mul i32 %x, %c
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}

define i32 @lifted(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = call fastcc i32 @inner(i32 %q)
  %c = icmp sgt i32 %t, 13
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
