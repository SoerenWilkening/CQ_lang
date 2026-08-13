; control_swap_value_diamond_derived.ll — ACCEPT: value diamond routing a
; DERIVED base (pre-region cq_phi; the 9hh discipline; IMPLEMENTATION-4.2 §0
; criterion 3). Graduated at WI-4 from the WI-3 transitional defer
; (control_swap_defer_value_derived_disjoint.ll) — same shape, now lowered.
;
; `pd = rz(p, 0.9); if (q > 5) { pd = pd*5; pd = pd+15; }` — the routed slot
; %pd is a pre-region `cq_phi` result: a diagonal alias of %p's wire, and
; NEITHER is in condProvenance(icmp %q) — the alias-closure walk (%pd -> %p,
; stop at theta) finds no provenance hit, so the region is accept-class (the
; positive contrast pin for control_swap_reject_value_alias_cond.ll: the
; diagonal-alias closure must not over-decline the legitimate derived-base
; discipline). Rotation lowering RAUWs %p and %pd to the SAME i32 handle, so
; the emitter routes the live SSA register exactly like an un-derived base;
; the lowered stream is control_swap_value_diamond.ll plus one unconditional
; `cqrt_rz` strictly BEFORE the flag mint.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; Independent EXACT free-count scan (§8.3 probe): two cqrt_free, no third anywhere.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %pd = call i32 @cq_phi_si32(i32 %p, double 9.000000e-01)   ; derived base, DISJOINT from cond
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i32 %pd, 5
  %v2 = add i32 %v1, 15
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %pd, %entry ]   ; straight-through = the DERIVED %pd
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; pre-region Rz on the routed register's wire, strictly BEFORE the flag mint
; CHECK:     %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[P]], double 9.000000e-01)
; 1: mint the flag from the (cross-register) tainted compare
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; 2: |0> work rail
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; 3: route the derived value register in
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[T]])
; 4: arm chain VERBATIM on the rail (uncontrolled HL templates)
; CHECK:     %[[V1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[T]], i32 5)
; CHECK:     %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[V1]], i32 15)
; 5: route back — p now holds the muxed answer
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[V2]])
; 6: B-keep copy-out (after route-back, before R-dagger — interlock §6.4)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[P]], i32 %[[OUT]])
; 7: reverse-play R-dagger — route-back-dagger, chain adjoint in reverse via the
;    void `_unc` forms (out=forward result, src=live forward operand), route-in-
;    dagger on the WORK RAIL %[[T]] (the chain head, restored to |0>)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[V2]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[V2]], i32 %[[V1]], i32 15)
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[V1]], i32 %[[T]], i32 5)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[T]])
; 8: rail free consumes the WORK RAIL %[[T]] (|0> after route-in-dagger; the
;    `_unc`-zeroed intermediates leak — accepted WI-3 leak, never freed dirty)
; CHECK:     call void @cqrt_free(i32 %[[T]])
; 9: strip the boolean + reclaim the flag
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
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
