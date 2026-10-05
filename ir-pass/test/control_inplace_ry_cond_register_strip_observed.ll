; control_inplace_ry_cond_register_strip_observed.ll — ACCEPT, CASE: STRIPPED.
; An Ry on the condition's own register whose compare reads only a record the
; program keeps, so the flag IS uncomputable after the gate and is stripped and
; freed (bd test_C_libtooling-dm7f.4, review round 2, finding F-A).
;
;     int q = u; cq_theta(&q, .5);
;     int d = q & 6;
;     if (d == 2) cq_theta(&q, .9);
;     cq_theta(&d, .4);
;     return cq_measure(q) + cq_measure(d);
;
; THE TWO CASES OF THE dm7f.4 ACCEPT. The owner's ruling (2026-10-03, option
; (a)) keeps the flag BECAUSE it cannot be uncomputed after the Ry. That is the
; KEPT case: a compare operand on the rotated wire (`q > 5`), or a temporary
; with no later reader that the spine discharges before the gate
; (`(q & 3) == 1`). Here the compare's only tainted operand is `d`'s rail: off
; the rotated wire, untouched by the stream, and read by the program after the
; region. So the strip after the gate is EXACT, and this is the STRIPPED case,
; lowered exactly as the disjoint-register path lowers.
;
; WHAT 272bf17a EMITTED (measured): the flag kept,
;     h1 = and(h0,6); f = [h1==2]; cry(f, h0, .9); ry(h1, .4); measure h0, h1
; which is a WRONG UNITARY. The source's circuit is unitary on (q, d) with no
; flag. Keeping f = [d_pre == 2] makes the measured (q, d) state the mixture
; Σ_b |ψ_b⟩⟨ψ_b| over b = [d == 2] instead of the pure Σ_b ψ_b. The cross terms are
; generically nonzero: on b = 1, Ry(.9) spreads q's bits onto values b = 0
; holds, and `ry(h1, .4)` spreads d = 2 onto d = 0/4/6. So d's distribution
; differs, behind a warning that fires either way: F1's class.
;
; TRACE NOW: f = [h1 == 2]; cry(f, h0, .9); icmp_eq_hl_unc(f, h1, 2) XORs
; [h1 == 2] back onto f with h1 unchanged since the mint, so f = 0 on every
; branch and its free is honest (R5); then ry(h1, .4) acts on d alone.
;
; ⚠ ONE M-A WARNING REMAINS, AND IT IS AN OVER-WARN. M-A counts f as a live
; derived record of q at the gate because its strip runs after the gate. f is a
; function of h1, which is live and observed, so f adds no dephasing beyond
; the program's own `d`. Removing it needs M-A to read a strip-after-gate
; flag, which is not this change's to make.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s --implicit-check-not=keptflag < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = and i32 %q, 6
  %c = icmp eq i32 %d, 2
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %dt = call i32 @cq_theta_si32(i32 %d, double 4.000000e-01)
  %m1 = call i32 @cq_measure_si32(i32 %qm)
  %m2 = call i32 @cq_measure_si32(i32 %dt)
  %s  = add nsw i32 %m2, %m1
  ret i32 %s
}

; WARN-COUNT-1: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: error

; CHECK-LABEL: define i32 @example(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[H]], i32 6)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[D]], i32 2)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[H]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[D]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[D]], double 4.000000e-01)
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[D]])
