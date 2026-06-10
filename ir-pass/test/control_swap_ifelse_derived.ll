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
; in-place), which is WHY routing the derived register is correct.
;
; REGRESSION GUARD (§8 adversarial review 2026-06-09 — this exact shape was a
; crash, then a WI-3 decline): with an UNBOUNDED phase-spine walk both arms
; appear to bottom at the theta %q and the emitter collects the SHARED %qd once
; per arm → double-erase SIGSEGV (exit 139); the sibling where %qd feeds the
; icmp emitted a dangling `void <badref>` (exit 134). The arm-block-bounded walk
; keeps both impossible: %qd is the routed base, never an arm gate. Any rebound
; of that walk re-crashes THIS fixture loudly. See
; [[swap-route-ifelse-derived-base-boundary]].
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; Independent EXACT free-count scan (§8.2): three cqrt_free (two rails + flag), no fourth.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)   ; UNCONDITIONAL pre-rotation
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 %qd, double %a)
  br label %merge
else:
  %qe = call i32 @cq_phi_si32(i32 %qd, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; q-prep, then the pre-region Rz fires UNCONDITIONALLY — strictly BEFORE the
; flag mint (it is not part of the routed region).
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; flag mint reads the SAME handle (%q and %qd RAUW to one i32 handle)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[TT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[EE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; split: route q -> then rail iff flag, q -> else rail iff ¬flag
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[TT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[EE]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; arm bodies: VERBATIM, UNCONTROLLED
; CHECK:     call void @cqrt_rz_i32(i32 %[[TT]], double %a)
; CHECK:     call void @cqrt_rz_i32(i32 %[[EE]], double %b)
; join = adjoint of the split
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[TT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[EE]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_free(i32 %[[TT]])
; CHECK:     call void @cqrt_free(i32 %[[EE]])
; strip: Rz (pre-region AND arms) preserves the basis value, so icmp_inv(q)
; returns the flag to |0> with zero controlled gates
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; no-spurious-free + dephasing guard (§8.2/§8.5)
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — three (two rails + flag), no fourth anywhere.
; CNT-COUNT-3: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
