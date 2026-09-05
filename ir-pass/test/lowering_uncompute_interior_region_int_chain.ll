; lowering_uncompute_interior_region_int_chain.ll — ACCEPT (M-B Increment 6,
; clause (d2)). The INTEGER twin of lowering_uncompute_interior_region_chain.ll:
; the same emitter-recorded-strip anchor over an all-integer condition chain.
;
;     q = cq_theta(u, 0.5);
;     if (((q * 37) >> 3) == 5) { q = cq_phi(q, PI); }
;     return cq_measure(q);
;
; `clang -O1` canonicalizes `(x*37)>>3 == 5` into `(x*37) & -8 == 40`, so the
; chain the pass sees is `cq_template_mul_i32_hl` then `cq_template_and_i32_hl`
; then the flag mint — the shape written verbatim below.
;
; WHY BOTH WIDTHS ARE PINNED. The fp fixture's chain bottoms at a CAST
; (`sitofp`), whose `_unc` reads the wire directly; this one bottoms at a
; `mul` whose `_unc` also reads the wire directly, but through a two-link
; integer chain with no cast in it. They exercise the same admission clause over
; different `_unc` families (`isUncHandleSlot` answers from the shape suffix: an
; `_hl` `_unc` has slots {rail, handle, literal}, and the LITERAL slot must not
; be read as a handle).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @int_chain(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = mul nsw i32 %q, 37
  %k  = and i32 %d, -8
  %c  = icmp eq i32 %k, 40
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %merge

merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK-LABEL: define i32 @int_chain(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[D:.*]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 37)
; CHECK-NEXT: %[[K:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[D]], i32 -8)
; CHECK-NEXT: %[[F:.*]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[K]], i32 40)
; the region, CONTROL-IN-PLACE since drbq Inc 2a: one `cqrt_rz_<W>_controlled` on
; the user's own register in place of the route quintuple — no work rail, no
; CSWAP, nothing to free but the flag.
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[K]], i32 40)
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[K]], i32 %[[D]], i32 -8)
; CHECK-NEXT: call void @cqrt_free(i32 %[[K]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 37)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])
