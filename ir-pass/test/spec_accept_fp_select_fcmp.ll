; spec_accept_fp_select_fcmp.ll — ACCEPT (bd tkmn Inc 1, the fcmp-condition
; widening). WAS spec_reject_fp_select_fcmp.ll: the kmdc slice-1 gate admitted
; only an `ICmpInst` condition, deferring fcmp as "a separate flag path". This
; converts that pin — the deferral is lifted, nothing else about the shape moved.
;
; The body mirrors the REAL shape that motivated the widening: openlibm
; bsdsrc/b_exp.c:171 `return isfinite(x) ? scalbn(1.0,5000) : x`, inlined into
; `tgamma`, which `clang -O1` if-converts to a straight-line select — so this is
; a DATA mux, not control flow:
;     %c = fcmp one double %x, +inf
;     %a = select i1 %c, double +inf, double %x     ; const arm / derived arm
; const/value arms were already admitted (bd 20xt.3) and f64 was already in the
; result-width whitelist; the fcmp condition was the SOLE failing clause, pinned
; by instrumentation rather than inferred from the diagnostic.
;
; ANGLE SAFETY: a clone body is provably ROTATION-FREE (scanBody rejects every
; cq_theta/cq_phi as QuantumPrimitive), so there is no rotation arg-1 angle slot
; for the compared fp value to reach and kjd1's top-level stale-condition wire
; guard is VACUOUS here — the reason this needs no three-legged fp fence.
;
; bd p3kd.7.8: the clone is now lowered by MAIN's stage list (main's 4.4
; CondTreeEmit flag + SelectMergeEmit merge, which mints the fcmp flag through the
; same `lowerCompareToFlag`). The fcmp symbol, the |+inf> materialization and the
; two-copy stream are unchanged. What moved: the merge's own flag strip (trailing
; `cqrt_x`, fcmp `_unc`, free) is elided inside a clone, so the forward ends with
; the bracket OPEN (F = [!(X one +inf)]) and the mirror's single `cqrt_x` between
; the two copies closes it. Hand trace, |n>: X = sitofp(n); F = [X one +inf];
; SEL = F·(+inf) ⊕ ¬F·X = F ? +inf : X; R = fptosi(SEL). Mirror: R `_unc`'d to 0,
; SEL ^= ¬F·X, F→[X one +inf], SEL ^= F·(+inf) (SEL = 0), the fcmp `_unc` (X still
; live) zeroes F, the sitofp `_unc` zeroes X. X, F, SEL and R are |0> at their
; frees; FC stays allocated. The body is pinned CHECK-NEXT through `}`, replacing
; the old trailing CHECK-NOT (placed after the `ret`, it scanned only the tail).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --implicit-check-not=cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x = sitofp i32 %n to double
  %c = fcmp one double %x, 0x7FF0000000000000     ; FCMP condition (was the decline)
  %a = select i1 %c, double 0x7FF0000000000000, double %x
  %r = fptosi double %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK-LABEL: define internal i32 @__cq_q_mhelper_1(i32 %n)
; CHECK-NEXT: %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sitofp_i32_to_f64(i32 %n)
; The fcmp mints its flag through the SAME lowerCompareToFlag path as an icmp,
; differing only in the family stem — this symbol IS the widening's payload.
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_one_f64_hl(i32 %[[X]], double 0x7FF0000000000000)
; CHECK-NEXT: %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; The ConstantFP +inf TRUE arm is materialized to its own |const> rail (20xt.3).
; The 4.4 two-copy stream, ¬flag `cqrt_x`-bracketed (the bracket closes in the
; mirror). Copy SOURCES are named EXPLICITLY, never wildcarded: a wildcard source
; lets a mutant that copies the live qubit pass.
; CHECK-NEXT: call void @cqrt_xorc_f64_controlled(i32 %[[F]], i32 %[[SEL]], double 0x7FF0000000000000)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[X]], i32 %[[SEL]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fptosi_f64_to_i32(i32 %[[SEL]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[R]], i32 %[[OUT]])
;
; Bennett reverse — the EXACT adjoint, in reverse order (each copy/x is
; self-inverse), then the fcmp flag strip and the cast reversal.
; CHECK-NEXT: call void @cq_template_fptosi_f64_to_i32_unc(i32 %[[R]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[X]], i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_xorc_f64_controlled(i32 %[[F]], i32 %[[SEL]], double 0x7FF0000000000000)
; The flag strip NAMES the rail the next lines free (the 8txa out-first `_unc`).
; CHECK-NEXT: call void @cq_template_fcmp_one_f64_hl_unc(i32 %[[F]], i32 %[[X]], double 0x7FF0000000000000)
; CHECK-NEXT: call void @cq_template_sitofp_i32_to_f64_unc(i32 %[[X]], i32 %n)
;
; Rule 6: every freed rail was reversed to |0> above. The materialized |const>
; rail [[FC]] is separable classical data — LEFT allocated, never freed (the
; body ends at the `}` below without a free of it).
; CHECK-NEXT: call void @cqrt_free(i32 %[[X]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[SEL]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: ret i32 %[[OUT]]
; CHECK-NEXT: }
