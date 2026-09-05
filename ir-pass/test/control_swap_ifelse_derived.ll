; control_swap_ifelse_derived.ll — ACCEPT: if/else routing a DERIVED base (pre-region cq_phi).
;
; `q = rz(q, 0.9); if (q > 5) { rz(q, a); } else { rz(q, b); }` — both arm spines
; bottom at the PRE-REGION `%qd = cq_phi(%q, ·)` (an unconditional Rz applied
; before the branch, shared by both arms). %qd is the LIVE derived base handle:
; it is tainted (theta lineage), and Rz is DIAGONAL (basis-value-preserving), so
; icmp(%qd) equals the minted flag throughout the region and the icmp_inv(%qd)
; flag-strip is exactly as valid as for an un-derived theta base (§0 criterion 3
; permits a derived tainted base; test_C_libtooling-9hh). The condition here ALSO
; reads %qd — the natural clang -O1 shape (the condition reads the live register).
;
; At the HANDLE level the stream is control_swap_ifelse.ll plus one unconditional
; `cqrt_rz` that MUST fire BEFORE the flag mint (the CHECK order pins it):
; rotation lowering RAUWs both %q and %qd to the SAME i32 handle (Rz is
; in-place), which is WHY gating on the derived register is correct. Under the §6a
; control-in-place peephole that is now visible directly — the controlled arm gates
; name that one handle as their target.
;
; REGRESSION GUARD (§8 adversarial review 2026-06-09 — this exact shape was a
; crash, then a WI-3 decline): with an UNBOUNDED phase-spine walk both arms
; appear to bottom at the theta %q and the emitter collects the SHARED %qd once
; per arm → double-erase SIGSEGV (exit 139); the sibling where %qd feeds the
; icmp emitted a dangling `void <badref>` (exit 134). The arm-block-bounded walk
; keeps both impossible: %qd is the region's gated base, never an arm gate — which
; is why exactly TWO controlled rotations are emitted here, one per arm, and the
; pre-region Rz stays uncontrolled. Any rebound of that walk re-crashes THIS fixture
; loudly. See [[swap-route-ifelse-derived-base-boundary]].
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Independent EXACT free-count scan (§8.2): one cqrt_free (the flag), no second.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; Independent EXACT arm-gate count: two controlled rotations, one per arm — a walk
; that re-collected the shared pre-region %qd would emit a third.
; RUN: %filecheck %s --check-prefix=RZCNT < %t.cqd0.ll
; The route's ABSENCE, anchored at the function header so the window is the whole
; function (a trailing CHECK-NOT scans only past the LAST positive of its prefix,
; and every route line would land BEFORE that — it could never fire).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  call void @cq_phi(double %a)
  br label %merge
else:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; q-prep, then the pre-region Rz fires UNCONDITIONALLY — strictly BEFORE the
; flag mint (it is not an arm gate; it stays uncontrolled).
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; flag mint reads the SAME handle (%q and %qd RAUW to one i32 handle)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; THEN arm: controlled on %flag, in place on the SAME derived handle
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; ELSE arm: the complement — X-bracketed gate run, so it fires on ¬flag
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; strip: Rz (pre-region AND arms) preserves the basis value, so icmp_inv(q)
; returns the flag to |0>
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; no-spurious-free + dephasing guard (§8.2/§8.5)
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — one (the flag), no second anywhere.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; Exactly two CONTROLLED rotations — one arm gate each, the shared pre-region %qd
; collected NEITHER time (the double-erase regression would show as a third).
; RZCNT-COUNT-2: call void @cqrt_rz_i32_controlled(
; RZCNT-NOT:     call void @cqrt_rz_i32_controlled(

; No swap route survives: no |0> work rails, no CSWAP, no copy, no data mux —
; window is `define` -> EOF, so a re-introduced route WOULD trip these.
; NOROUTE:     define i32 @example
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: phi i32
