; control_swap_ifelse_multigate.ll — ACCEPT probe: asymmetric multi-gate if/else.
;
; `if (q > 5) { rz(q, a); rz(q, c); } else { rz(q, b); }` — the then arm carries
; TWO Rz gates, the else arm ONE. Each arm's gates run VERBATIM/UNCONTROLLED on its
; OWN |0> rail (then's two on the then rail, else's one on the else rail); the join
; repeats the two CSWAP-pairs (adjoint of the split, same flag); both rails free
; clean; icmp_inv(q) strips the boolean.
;
; ADVERSARIAL POSTCONDITIONS (§8.2 no-spurious-free + §8.5 dephasing guard) for the
; two-rail shape: EXACTLY THREE cqrt_free (then rail + else rail + flag) — the later
; uncompute pass must add NO fourth (a spurious free is a hidden measurement that
; collapses q); and ZERO controlled gates / copies (method-B copy on a PHASE arm
; dephases the answer — verified P0 0.585->0.500), NO surviving data mux.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free-count scan (§8.2): three cqrt_free and no fourth anywhere.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %c, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = icmp sgt i32 %q, 5
  br i1 %k, label %then, label %else
then:
  %t1 = call i32 @cq_phi_si32(i32 %q,  double %a)
  %t2 = call i32 @cq_phi_si32(i32 %t1, double %c)
  br label %merge
else:
  %e1 = call i32 @cq_phi_si32(i32 %q,  double %b)
  br label %merge
merge:
  %qm = phi i32 [ %t2, %then ], [ %e1, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; flag mint
; CHECK:         %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; then arm: BOTH Rz gates controlled on %[[F]], IN PLACE on q, IN ARM-GATE ORDER;
; else arm: its one Rz inside the single ¬flag bracket (drbq Inc 2a — the two
; distinct |0> work rails are gone; the arms stay mutually exclusive by POLARITY)
; CHECK:         call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK-NEXT:    call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %c)
; CHECK-NEXT:    call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:    call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; CHECK-NEXT:    call void @cqrt_x(i32 %[[F]])
; then strip + flag free; q (not the phi) is measured
; CHECK:         call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:         call void @cqrt_free(i32 %[[F]])
; CHECK:         call i32 @cqrt_measure_i32(i32 %[[Q]])
; no-spurious-free: the flag free is the LAST free — no second after it
; CHECK-NOT:     call void @cqrt_free
; dephasing guard: zero copies, no surviving data mux
; CHECK-NOT:     cqrt_copy
; CHECK-NOT:     phi i32

; Exact free count — one (the flag; the two work rails went with the route at
; drbq Inc 2a), no second anywhere.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
; No swap route survives: no |0> work rail, no CSWAP — window is `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
