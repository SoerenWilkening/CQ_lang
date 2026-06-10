; control_swap_ifelse_derived_crossqubit_cond.ll — ACCEPT: condition on qubit P,
; arms rotate the DERIVED handle of qubit Q.
;
; `if (p > 5) { rz(q, a); } else { rz(q, b); }` where the routed handle is the
; pre-region-derived %qd of theta %q and the condition reads a DIFFERENT theta
; %p. This is a genuine TWO-QUBIT controlled phase — semantically distinct from
; the single-handle phase-kick of the other accept fixtures — and it is correct
; by the same §3a reasoning: the flag is minted from basis(p), NOTHING in the
; region touches p, so icmp_inv(p) strips the flag exactly; the arms are
; diagonal on q's rails, which return to |0> for free. Nothing in §0
; criterion 3 requires the routed base to share lineage with the condition.
; (The un-derived cross-qubit form was already accepted; the derived form was
; silently enabled by test_C_libtooling-9hh — this fixture pins it per Rule 12,
; flagged by the §8 completeness review 2026-06-10. The CROSS-HANDLE rejects —
; arms muxing two handles at the MERGE — are a different shape and still
; decline: control_swap_reject_{ifelse_crosshandle,ifelse_derived_mixed}.ll.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0, double %a, double %b) {
entry:
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c = icmp sgt i32 %p, 5                          ; condition on qubit P
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 %qd, double %a)  ; arms rotate derived Q
  br label %merge
else:
  %qe = call i32 @cq_phi_si32(i32 %qd, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; two distinct handles: %p (the control) and %qd's underlying %q (the target)
; CHECK:     %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; flag minted from P; routes move Q
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[P]], i32 5)
; CHECK:     %[[TT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[EE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[TT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[EE]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[TT]], double %a)
; CHECK:     call void @cqrt_rz_i32(i32 %[[EE]], double %b)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[TT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[EE]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_free(i32 %[[TT]])
; CHECK:     call void @cqrt_free(i32 %[[EE]])
; strip on P — untouched by the region, so the flag returns to |0> exactly
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[P]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; CNT-COUNT-3: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
