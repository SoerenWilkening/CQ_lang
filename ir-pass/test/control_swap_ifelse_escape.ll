; control_swap_ifelse_escape.ll — ACCEPT probe: if/else result ESCAPES via ret.
;
; `if (q > 5) { rz(q, a); } else { rz(q, b); } return q;` — the merged handle is
; NOT measured; it escapes to the caller. The swap-route stream is identical to the
; measured case (the merge phi RAUWs to q), and the boolean is still stripped
; (icmp_inv(q)) so the escaping handle is coherent and disentangled — the caller
; owns it.
;
; ADVERSARIAL POSTCONDITION (§6.2 + Rule 6): q ESCAPED, so it must NOT be freed
; (freeing an escaped handle is a hidden measurement that collapses it). Exactly
; THREE cqrt_free are emitted — the two work rails and the flag — and q is returned
; live. The later uncompute pass sees q escape (computeFreePoint → Escaped) and adds
; no free. Pairs with control_swap_ifelse_multigate.ll (the measured-q free count).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free-count scan: three frees (two rails + flag), no fourth.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = icmp sgt i32 %q, 5
  br i1 %k, label %then, label %else
then:
  call void @cq_phi(double %a)
  br label %merge
else:
  call void @cq_phi(double %b)
  br label %merge
merge:
  ret i32 %q
}

; CHECK:         %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; both arms CONTROL-IN-PLACE on q (drbq Inc 2a): THEN on %[[F]], ELSE bracketed
; CHECK:         call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK-NEXT:    call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:    call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; CHECK-NEXT:    call void @cqrt_x(i32 %[[F]])
; CHECK:         call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:         call void @cqrt_free(i32 %[[F]])
; q escapes to the caller — returned LIVE, never freed:
; CHECK:         ret i32 %[[Q]]
; CHECK-NOT:     call void @cqrt_free
; CHECK-NOT:     cqrt_copy
; CHECK-NOT:     phi i32

; Exact free count — one (the flag; the two work rails went with the route at
; drbq Inc 2a), no second anywhere. q itself is returned LIVE and never freed.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
; No swap route survives: no |0> work rail, no CSWAP — window is `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
