; control_swap_switch_value.ll — ACCEPT spec: a clean homogeneous VALUE switch
; (4.5 WI-3; IMPLEMENTATION-4.5 §4B — the N-way method-B, symbol ORDER is the
; contract).
;
; `switch(q){ case 0: p=p+1; case 1: p=p+2; }` — each arm a pure linear value
; chain over the SHARED routed base %p = the merge default-edge (straight-through)
; incoming, p != q (the C2 anchor; routing q would clobber the eq-flags, §3c). The
; eq-flags f_i=(q==c_i) are MUTUALLY EXCLUSIVE, so the forward stage is interleaved
; per case: mint f_i -> |0> rail -> cswap route-in (positive-polarity, NO ¬-bracket)
; -> chain VERBATIM on the rail (HL templates) -> cswap route-back (p holds the
; muxed answer). Then ONE cqrt_copy_i32(p,out) copy-out (after route-back, before
; any R†), the LIFO reverse-play (route-back† · body-chain void `_unc` adjoint ·
; route-in† on the work rail; §8.5 seam — route cswaps are bracketed by emitRoute,
; NEVER fed to the inverter), the clean rail frees, the icmp_inv flag strips (the
; flag-strip stays `_inv` — direct emitEqFlag, not the spine; q==q0, q never
; routed), and the flag frees. EXACTLY FOUR frees (2 rails + 2 flags); %p (restored
; to p0) and %out (the result) are NEVER freed (either free is a hidden measurement).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free-count scan (§8 probe): four cqrt_free, no fifth anywhere.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; Accept (no decline anywhere).
; RUN: %filecheck %s --check-prefix=ACC < %t.cqd0.ll
; Whole-output stray-x scan (WI-7 §8.2 lit-robustness, 4.4 XCT precedent): the
; value emitter is positive-polarity (NO ¬-bracket) — ZERO cqrt_x anywhere. The
; default ordered CHECK's CHECK-NOT block only scans post-measure, so a stray
; cqrt_x BEFORE the measure (swapped operands / dirty flag, an identical-multiset
; miscompile) would slip the default prefix; this independent whole-file scan
; closes it at the lit layer (was e2e-only).
; RUN: %filecheck %s --check-prefix=XCT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %p0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %p0, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = add i32 %p, 1
  br label %merge
a1:
  %v1 = add i32 %p, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; --- Forward case 0 (q==0): flag -> |0> rail -> route-in -> chain -> route-back ---
; CHECK:     %[[F0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 0)
; CHECK:     %[[R0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F0]], i32 %[[P:[a-zA-Z0-9_.]+]], i32 %[[R0]])
; CHECK:     %[[OP0:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[R0]], i32 1)
; CHECK:     call void @cqrt_cswap(i32 %[[F0]], i32 %[[P]], i32 %[[OP0]])
; --- Forward case 1 (q==1) ---
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 1)
; CHECK:     %[[R1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[P]], i32 %[[R1]])
; CHECK:     %[[OP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[R1]], i32 2)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[P]], i32 %[[OP1]])
; --- ONE copy-out (after the route-backs, before any R†) ---
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[P]], i32 %[[OUT]])
; --- Reverse-play (LIFO: case1, then case0). route-back† · void `_unc` body
;     adjoint (out=forward result, src=live rail) · route-in† on the work rail ---
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[P]], i32 %[[OP1]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP1]], i32 %[[R1]], i32 2)
; CHECK:     call void @cqrt_cswap(i32 %[[F1]], i32 %[[P]], i32 %[[R1]])
; CHECK:     call void @cqrt_cswap(i32 %[[F0]], i32 %[[P]], i32 %[[OP0]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[OP0]], i32 %[[R0]], i32 1)
; CHECK:     call void @cqrt_cswap(i32 %[[F0]], i32 %[[P]], i32 %[[R0]])
; --- Rail frees (reverse order, on the WORK RAIL — |0> after route-in†) ---
; CHECK:     call void @cqrt_free(i32 %[[R1]])
; CHECK:     call void @cqrt_free(i32 %[[R0]])
; --- Flag strip + free (each reads pristine q == q0) ---
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F0]], i32 %[[Q]], i32 0)
; CHECK:     call void @cqrt_free(i32 %[[F0]])
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 1)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
; --- the merge phi RAUWs to %out — the measure reads the copied answer ---
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; no fifth free (neither %out nor the restored source %p — hidden measurement)
; CHECK-NOT: call void @cqrt_free
; dephasing/shape guards: zero controlled gates, no surviving data mux
; CHECK-NOT: _controlled
; CHECK-NOT: phi i32

; Exact free count — four (2 rails + 2 flags), no fifth anywhere.
; CNT-COUNT-4: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; No ¬-bracket: ZERO cqrt_x in the whole output (a stray x = swapped operands +
; dirty flag, an identical-multiset wrong unitary the ordered prefix misses).
; XCT-NOT: call void @cqrt_x(

; ACC-NOT: under quantum control
