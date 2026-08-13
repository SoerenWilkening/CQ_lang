; control_swap_eqfold_polarity.ll — ACCEPT spec, FALSE-successor equality-folded
; diamond (4.5 WI-5; Rule 9 polarity probe).
;
; The eq-fold diamond of control_swap_eqfold_diamond.ll, but the gate arm is the
; FALSE successor: `%c = icmp ne i32 %q, 7 ; br i1 %c, label %merge, label %arm`,
; with the merge phi's entry-incoming listed FIRST. The arm is the `ne`-FALSE
; successor, i.e. the `q == 7` region — so the gate genuinely CONST-FOLDS to
; `cq_phi(i32 7, θ)` exactly as on the true-successor diamond. `tryEqFoldArm`'s D1
; predicate covers `ICMP_NE` as well as `ICMP_EQ` (both are equality), so the arm
; is re-anchored; ControlDetect resolves the arm by merge-phi IDENTITY (orientation
; B, `ArmNegated`) and `emitRegion` routes on ¬flag via a self-inverse
; `cqrt_x(flag)` bracket around BOTH the route-in and the route-back. The
; flag-strip is polarity-independent: Rz preserves q's basis value, so
; `icmp_ne_inv(q)` returns the flag to |0> regardless of which polarity routed it.
;
; (clang -O1 canonicalizes a natural `if(q==k)` to `icmp eq` + TRUE-successor — the
; const-fold requires `q==k` to dominate the arm — so this `icmp ne` + FALSE-
; successor shape is hand-transcribed as the defensive ¬flag-bracket probe, the
; eq-fold analog of control_swap_diamond_polarity.ll. It is a legal, coherent IR
; shape: the arm IS the `q==7` region, so the fold is genuine.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; Independent EXACT free-count scan: two cqrt_free; the ¬flag X-bracket adds
; cqrt_x, NOT extra frees.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp ne i32 %q, 7
  br i1 %c, label %merge, label %arm     ; SWAPPED: gate arm is the FALSE successor
arm:
  %q1 = call i32 @cq_phi_si32(i32 7,   double %a)   ; folded to 7 (q==7 holds here)
  %q2 = call i32 @cq_phi_si32(i32 %q1, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %q2, %arm ]   ; entry-incoming FIRST (edge order swapped)
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; br: mint the flag, then route q into a |0> work rail — but on ¬flag (the gate
; arm is the false successor), so the cswap is X-bracketed.
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 7)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; arm body: VERBATIM, UNCONTROLLED Rz gates on the routed rail
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %a)
; CHECK:     call void @cqrt_rz_i32(i32 %[[T]], double %b)
; phi: route back (adjoint of the split, same ¬flag bracket)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[Q]], i32 %[[T]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_free(i32 %[[T]])
; CHECK:     call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; no-spurious-free + re-anchor + dephasing guards
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cq_phi
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — two (work rail + flag), no third anywhere.
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
