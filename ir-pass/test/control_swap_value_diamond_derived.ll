; control_swap_value_diamond_derived.ll — ACCEPT: value diamond over a DERIVED
; base (pre-region cq_phi; the 9hh discipline), lowered by the CONTROLLED-COPY
; MERGE (bd test_C_libtooling-3qlq Inc 2).
;
; `pd = rz(p, 0.9); if (q > 5) { pd = pd*5; pd = pd+15; }` — the merged slot
; %pd is a pre-region `cq_phi` result: a diagonal alias of %p's wire, and
; NEITHER is in condProvenance(icmp %q), so the region is accept-class (the
; positive contrast pin for control_swap_reject_value_alias_cond.ll). Rotation
; lowering RAUWs %p and %pd to the SAME i32 handle, so the emitter merges the
; live SSA register exactly like an un-derived base; the lowered stream is
; control_swap_value_diamond.ll plus one unconditional `cqrt_rz` strictly
; BEFORE the hoisted chain. Every CHECK is re-derived from the pass output.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Whole-file PURE-NEGATIVE scan (bd drbq Inc-4 lens: a positive COUNT directive
; inside a prefix WINDOWS every negative after it, so the negatives live alone).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Exact counts, one symbol per prefix for the same windowing reason.
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
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

; pre-region Rz on the merged register's wire, strictly BEFORE the chain
; CHECK:     %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[P]], double 9.000000e-01)
; the hoisted arm chain, on the DERIVED register (same handle)
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK:     call void @cqrt_addc_i32(i32 %[[V]], i32 15)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; No route survives anywhere in the module: the swap route is RETIRED for value
; arms (bd test_C_libtooling-3qlq Inc 2), there is no work rail, and no
; uncontrolled basis copy — the merge is the two CONTROLLED copies alone.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy_i32(
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: call i32 @cq_phi
; NOROUTE-NOT: cqrt_free(i32 %out)

; EXACTLY ONE free in the whole module — the flag. `%out`, the source `%p` and
; the hoisted chain's final rail are all left ALLOCATED (keep-source-live: a
; free of any of them is a hidden measurement, Rule 6/8).
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; EXACTLY TWO controlled copies — the whole merge.
; CCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CCNT-NOT:     call void @cqrt_copy_i32_controlled(
