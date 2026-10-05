; control_inplace_ry_reject_cond_register_lifted_chain.ll — DECLINE: the kept-
; flag accept (bd test_C_libtooling-dm7f.4) with a condition computed by a
; LIFTED CALL whose result would stand live at the controlled Ry. Review round 1
; of dm7f.4, finding F1 (introduced, L9).
;
;     __attribute__((noinline)) int h(int x) { return x * 3 + 1; }
;     int q = u; cq_theta(&q, .5);
;     if (h(q) > 13) cq_theta(&q, .9);
;     return cq_measure(q);
;
; WHAT 03d9ca8a EMITTED, `opt` exit 0 with one M-A warning:
;     %2 = __cq_q_h_1(%h)                      ; a fresh rail holding 3q + 1
;     f  = icmp_sgt_i32_hl(%2, 13)
;     cry(f, %h, .9)
;     measure(%h)                              ; %2 never _unc'd, never freed
; `%2` is an INJECTIVE record of the pre-Ry q, standing at the gate. The source
; keeps only the predicate [x > 4] (the kept flag the owner ruled into the
; circuit, option (a)); a record of all of q dephases q completely in the basis
; before the Ry, so q's measured distribution differs. A WRONG UNITARY, reported
; only by the generic `non-diagonal gate over a live derived record`. The root
; cause is pre-existing (bd ln16: a `__cq_q_*` result is never an interior
; producer, so the spine cannot discharge it before the gate); what was new is
; a customer whose gate is controlled from that record. `main` 7b4e6359 declines
; this module at R4, printed as `condition predates a non-diagonal gate under
; quantum control` (measured).
;
; THE FENCE: `declineUndischargedKeptFlagChains` (RotationLowering.cpp), the
; kept-flag postcondition in M-A's late slot. Every condition-chain record of the
; rotated wire other than the kept flag must be absent at the gate or exempt
; there under M-A's own predicates (discharged or collapsed before it, or
; observed by the program after it); `%2` is none of these, so the module
; declines with R4's string at the gate, and no warning precedes it. The
; observed twin, `int t = h(q); … cq_measure(t)`, keeps the record as the
; program's own data and ACCEPTS
; (control_inplace_ry_cond_register_flag_kept_derived_cond.ll, @lifted_observed).
;
; RETIREMENT TRIGGER: when bd ln16 lets the spine discharge a clone result
; before the gate, this module should ACCEPT with `__cq_q_h_1_unc` (or its
; equivalent) between the mint and the controlled Ry. Re-derive it then.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: warning
; CHECK: error: {{.*}}cq controlled lowering: rotation arm on a condition wire under quantum control
; CHECK-NOT: warning

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @h(i32 %x) #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}

define i32 @lifted(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = call i32 @h(i32 %q)
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

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
