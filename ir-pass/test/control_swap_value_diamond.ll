; control_swap_value_diamond.ll — ACCEPT spec, linear-HL-chain VALUE diamond
; (method-B; IMPLEMENTATION-4.2 §5d — symbol order IS the contract).
;
; `if (q > 5) { p = p*5; p = p+15; }` — a pure linear value chain over the
; routed straight-through %p, disjoint from the condition's provenance. The
; B-keep stream: flag mint -> |0> rail -> cswap route-in -> chain VERBATIM on
; the rail (HL templates) -> cswap route-back (p holds the muxed answer) ->
; alloc %out + cqrt_copy_i32 (the ONLY basis copy, AFTER route-back, BEFORE
; R-dagger) -> reverse-play: route-back-dagger, chain adjoints in reverse with
; _inv twins, route-in-dagger -> rail free (provably |0> ONLY after R-dagger,
; §3b) -> icmp_inv flag-strip + flag free. EXACTLY TWO frees: %out and the
; restored source %p are NEVER freed (either free is a hidden measurement).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; Independent EXACT free-count scan (§8.3 probe): two cqrt_free, no third anywhere.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i32 %p, 5
  %v2 = add i32 %v1, 15
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; 1: mint the flag from the tainted compare
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; 2: |0> work rail
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; 3: route the value register in
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P:[a-zA-Z0-9_.]+]], i32 %[[T]])
; 4: arm chain VERBATIM on the rail (uncontrolled HL templates)
; CHECK:     %[[V1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[T]], i32 5)
; CHECK:     %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[V1]], i32 15)
; 5: route back — p now holds the muxed answer
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[V2]])
; 6: B-keep copy-out (after route-back, before R-dagger — interlock §6.4)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[P]], i32 %[[OUT]])
; 7: reverse-play R-dagger — route-back-dagger, chain adjoint (reverse, _inv), route-in-dagger
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[V2]])
; CHECK:     %[[U1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl_inv(i32 %[[V2]], i32 15)
; CHECK:     %[[U2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl_inv(i32 %[[U1]], i32 5)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[U2]])
; 8: rail free consumes the FINAL threaded handle (interlock §6.5 — not %rail/%v2)
; CHECK:     call void @cqrt_free(i32 %[[U2]])
; 9: strip the boolean + reclaim the flag
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; the merge phi RAUWs to %out — the measure reads the copied answer
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; no third free (neither %out nor the restored source %p — hidden measurement)
; CHECK-NOT: call void @cqrt_free
; dephasing/shape guards: zero controlled gates, no surviving data mux
; CHECK-NOT: _controlled
; CHECK-NOT: phi i32

; Exact free count — two (work rail + flag), no third anywhere.
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
