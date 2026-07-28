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
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; Independent EXACT free-count scan: three frees (two rails + flag), no fourth.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = icmp sgt i32 %q, 5
  br i1 %k, label %then, label %else
then:
  %t = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
else:
  %e = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %t, %then ], [ %e, %else ]
  ret i32 %qm
}

; CHECK:         %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:         %[[TT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:         %[[EE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:         call void @cqrt_rz_i32(i32 %[[TT]], double %a)
; CHECK:         call void @cqrt_rz_i32(i32 %[[EE]], double %b)
; CHECK:         call void @cqrt_free(i32 %[[TT]])
; CHECK:         call void @cqrt_free(i32 %[[EE]])
; CHECK:         call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:         call void @cqrt_free(i32 %[[F]])
; q escapes to the caller — returned LIVE, never freed:
; CHECK:         ret i32 %[[Q]]
; CHECK-NOT:     call void @cqrt_free
; CHECK-NOT:     _controlled
; CHECK-NOT:     cqrt_copy
; CHECK-NOT:     phi i32

; CNT-COUNT-3: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
