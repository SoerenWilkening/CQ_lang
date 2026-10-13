; control_inplace_ry_reject_cond_register_lifted_chain.ll — ACCEPT since bd p3kd.13
; (was DECLINE; see RE-DERIVED below): the kept-
; flag accept (bd test_C_libtooling-dm7f.4) with a condition computed by a
; LIFTED CALL whose result would stand live at the controlled Ry. Review round 1
; of dm7f.4, finding F1 (introduced, L9).
; CASE: KEPT, then DECLINED. `t` has no reader after the region, so the strip is
; not available and the flag would be kept; the late chain check then refuses
; the undischarged `t`.
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
; ⚠ RE-DERIVED: NOW AN ACCEPT (bd test_C_libtooling-p3kd.13, 2026-10-08 — the
; trigger above fired; the file keeps its `reject_` name, as the live-record
; files do). A clone result is an uncompute-spine producer (CloneProducer.h), so
; the M-B interior partition discharges `%t` with its Bennett twin right after the
; flag mint (its last reader) and BEFORE the controlled Ry, while q is unrotated:
;     %t = __cq_q_h_1(%h); f = icmp_sgt_i32_hl(%t, 13)
;     __cq_q_h_1_unc(%t, %h); cqrt_free(%t)        ; t ^= 3q+1 -> |0>, freed honestly
;     cry(f, %h, .9); measure(%h)
; The kept-flag postcondition now finds the chain gone at the gate and admits the
; module; what stands there is the owner-ruled kept flag alone, which M-A reports
; as the warning (the same one @discharged in
; control_inplace_ry_cond_register_flag_kept_derived_cond.ll — this module's
; TEMPLATE twin, `(q & 3) == 1` — prints, stream for stream). The DECLINE survives
; for a callee whose twin cannot be synthesized:
; spec_intermediate_unc_reject_kept_flag_unsynthesizable.ll mirrors the string.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s < %t.ll
; WARN: warning: {{.*}}in function lifted{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: error
; WARN-NOT: warning
; CHECK-LABEL: define i32 @lifted(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_h_1(i32 %[[H]])
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[T]], i32 13)
; CHECK-NEXT: call void @__cq_q_h_1_unc(i32 %[[T]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[H]], double 9.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
; The kept flag is never freed (R5: it is not provably |0>).
; CHECK-NOT:  call void @cqrt_free(i32 %[[F]])
; CHECK:      ret i32

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
