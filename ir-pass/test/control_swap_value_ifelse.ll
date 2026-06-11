; control_swap_value_ifelse.ll — ACCEPT spec, two-arm VALUE if/else (method-B;
; IMPLEMENTATION-4.2 §5e — symbol order IS the contract; the exact X-bracket
; interleaving is pinned with CHECK-NEXT, the deliberate WI-5 regeneration of
; the WI-3 structural sketch, Rule 12).
;
; `if (q > 5) { p = p+3; } else { p = p*7; }` — both arms are pure linear value
; chains over the SHARED routed base %p. Dual rails: the then-chain routed
; under %flag, the else-chain under ¬flag via the self-inverse cqrt_x bracket;
; join = adjoint of the split for both; ONE copy-out of the settled %p (after
; both route-backs %p holds the two-sided answer); R-dagger per arm in REVERSE
; emission order (else block first — arm blocks commute: disjoint rails,
; complementary flag controls); two rail frees on the FINAL threaded handles +
; the flag free (EXACTLY THREE) — %out and the restored source %p are never
; freed (either free is a hidden measurement).
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

; 1: flag mint + 2: dual |0> rails (then rail first, else rail second)
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: %[[TT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[EE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; 3: split — p -> then rail iff flag; p -> else rail iff ¬flag (X-bracketed)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[P:[a-zA-Z0-9_.]+]], i32 %[[TT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[EE]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; 4: both chains VERBATIM + UNCONTROLLED, each on its OWN rail
; CHECK-NEXT: %[[VT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[TT]], i32 3)
; CHECK-NEXT: %[[VE:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[EE]], i32 7)
; 5: join = adjoint of the split (complementary controls — exactly one swap
;    fires per branch, so p settles to the two-sided answer)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[VT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[VE]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; 6: ONE B-keep copy-out of the settled p (after BOTH route-backs, before any
;    R-dagger — interlock §6.4)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[P]], i32 %[[OUT]])
; 7: R-dagger per arm in REVERSE emission order — ELSE block first (¬flag
;    brackets throughout): route-back-dagger, chain adjoint (_inv twin),
;    route-in-dagger on the THREADED handle
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[VE]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[UE:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl_inv(i32 %[[VE]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[UE]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
;    THEN block second (unbracketed)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[VT]])
; CHECK-NEXT: %[[UT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl_inv(i32 %[[VT]], i32 3)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[UT]])
; 8: both rails provably |0> only after R-dagger — clean frees on the FINAL
;    threaded handles (interlock §6.5), same reverse arm order
; CHECK-NEXT: call void @cqrt_free(i32 %[[UE]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[UT]])
; 9: strip the boolean + reclaim the flag
; CHECK-NEXT: call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the merge phi RAUWs to %out — the measure reads the copied answer
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[OUT]])
; no fourth free (neither %out nor the restored source %p — hidden
; measurement); no controlled gates; no surviving mux
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: _controlled
; CHECK-NOT: phi i32

; Exact free count — three (2 rails + flag), no fourth anywhere.
; CNT-COUNT-3: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
