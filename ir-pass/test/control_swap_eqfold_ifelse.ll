; control_swap_eqfold_ifelse.ll — ACCEPT spec, equality-folded two-arm if/else
; (4.5 WI-5), BOTH clang arm orderings (open-Q 3: they must converge).
;
; `if (q == 7) { rz(q,a); } else { rz(q,b); }`. On the `q==7` (true) arm `clang
; -O1` CONST-FOLDS the gate base to the literal — `cq_phi(i32 7, θ)` — while the
; other arm keeps `cq_phi(i32 %q, θ)`. An if/else has NO Pred-edge merge incoming,
; so without WI-5's re-anchor `emitRegion`'s `phaseSpineBase` would bottom at the
; folded constant and route a CONSTANT instead of `q` (a verify-clean wrong
; unitary — the eq-fold analog of the §5 switch re-anchor). `tryEqFoldArm` records
; the proven routed handle in `Region.RoutedBase`, which `emitRegion` PREFERS, so
; both rails route `q`. The two arms route to distinct |0> rails — the flag-arm
; unbracketed, the ¬flag-arm via a self-inverse `cqrt_x(flag)` bracket — exactly
; as control_swap_ifelse.ll, but with `icmp eq`/`ne` and the folded base.
;
; @ifelse_eq  — ordering 1 (`icmp eq`): the FOLDED arm is S0 (R.Arm); classifyArms
;               processes it FIRST, so `tryEqFoldArm` anchors the routed handle.
; @ifelse_ne  — ordering 2 (`icmp ne`): the KEPT arm is S0 (R.Arm) and the FOLDED
;               arm is S1; classifyArms anchors via the leaf path first, then
;               `tryEqFoldArm` accepts the folded S1 arm against the set anchor.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @ifelse_eq(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 7
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 7, double %a)    ; folded base (q==7 here)
  br label %merge
else:
  %qe = call i32 @cq_phi_si32(i32 %q, double %b)   ; kept base
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK-LABEL: define i32 @ifelse_eq
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 7)
; CHECK:     %[[TT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[EE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; split: route q (NOT the folded const 7) -> then rail iff flag, q -> else rail iff ¬flag
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[TT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[EE]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; arm bodies: VERBATIM, UNCONTROLLED (re-anchor by physics — angle only)
; CHECK:     call void @cqrt_rz_i32(i32 %[[TT]], double %a)
; CHECK:     call void @cqrt_rz_i32(i32 %[[EE]], double %b)
; join = adjoint of the split
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[TT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[EE]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_free(i32 %[[TT]])
; CHECK:     call void @cqrt_free(i32 %[[EE]])
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl_inv(i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])

define i32 @ifelse_ne(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp ne i32 %q, 7
  br i1 %c, label %kept, label %folded
kept:
  %qk = call i32 @cq_phi_si32(i32 %q, double %a)   ; kept base (S0/R.Arm)
  br label %merge
folded:
  %qf = call i32 @cq_phi_si32(i32 7, double %b)    ; folded base (S1, q==7 here)
  br label %merge
merge:
  %qm = phi i32 [ %qk, %kept ], [ %qf, %folded ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK-LABEL: define i32 @ifelse_ne
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 7)
; CHECK:     %[[KK:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[FF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; kept arm (S0) unbracketed, folded arm (S1) ¬flag — both route q, not the const
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[KK]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[FF]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[KK]], double %a)
; CHECK:     call void @cqrt_rz_i32(i32 %[[FF]], double %b)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[KK]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[FF]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_free(i32 %[[KK]])
; CHECK:     call void @cqrt_free(i32 %[[FF]])
; CHECK:     call i32 @cq_template_icmp_ne_i32_hl_inv(i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])

; global re-anchor / dephasing guards across both functions
; CHECK-NOT: cq_phi
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32
