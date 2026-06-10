; control_swap_value_ifelse.ll — ACCEPT spec, two-arm VALUE if/else (method-B;
; IMPLEMENTATION-4.2 §5e). Structural contract — WI-5 pins the exact bracket
; interleaving by deliberate regeneration (Rule 12).
;
; `if (q > 5) { p = p+3; } else { p = p*7; }` — both arms are pure linear value
; chains over the SHARED routed base %p. Dual rails: the then-chain routed
; under %flag, the else-chain under ¬flag via the self-inverse cqrt_x bracket;
; join = adjoint of the split for both; ONE copy-out of the settled %p (after
; both route-backs %p holds the two-sided answer); R-dagger for both arms in
; reverse emission order; two rail frees + the flag free (EXACTLY THREE) —
; %out and the restored source %p are never freed.
;
; XFAIL until WI-5 lands the dual-rail value path (WI-3 classification
; transitionally declines accept-class value regions as 'value-arm swap-route').
; XFAIL: *
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; Independent EXACT free-count scan: three cqrt_free (2 rails + flag), no fourth.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  %vt = add i32 %p, 3
  br label %merge
else:
  %ve = mul i32 %p, 7
  br label %merge
merge:
  %pm = phi i32 [ %vt, %then ], [ %ve, %else ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; flag mint + dual |0> rails
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[TT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[EE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; split: p -> then rail iff flag; p -> else rail iff ¬flag (X-bracketed)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P:[a-zA-Z0-9_.]+]], i32 %[[TT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[EE]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; both chains VERBATIM on their rails
; CHECK:     %[[VT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[TT]], i32 3)
; CHECK:     %[[VE:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[EE]], i32 7)
; join = adjoint of the split (both route-backs; p settles to the answer)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[VT]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[VE]])
; ONE B-keep copy-out of the settled p
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[P]], i32 %[[OUT]])
; R-dagger for both arms (reverse emission order): adjoint chains via _inv twins
; CHECK:     call i32 @cq_template_mul_i32_hl_inv(
; CHECK:     call i32 @cq_template_add_i32_hl_inv(
; both rails provably |0> only after R-dagger: two clean frees
; CHECK:     call void @cqrt_free(
; CHECK:     call void @cqrt_free(
; strip + flag free
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; the merge phi RAUWs to %out
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; no fourth free; no controlled gates; no surviving mux
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: _controlled
; CHECK-NOT: phi i32

; Exact free count — three (2 rails + flag), no fourth anywhere.
; CNT-COUNT-3: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
