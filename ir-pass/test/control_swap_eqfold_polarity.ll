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
; Independent EXACT free-count scan: two cqrt_free; the ¬flag X-bracket adds
; cqrt_x, NOT extra frees.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp ne i32 %q, 7
  br i1 %c, label %merge, label %arm     ; SWAPPED: gate arm is the FALSE successor
arm:
  call void @cq_phi(double %a)  ; folded to 7 (q==7 holds here)
  call void @cq_phi(double %b)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; br: mint the flag. The gate arm is the FALSE successor, so the arm's whole gate
; run is X-bracketed and fires on ¬flag (drbq Inc 2a: ONE bracket pair around the
; run, where the route needed one pair around EACH of its two cswaps — the same
; self-inverse pair on the same flag, two fewer of them because there are two
; fewer gates to bracket).
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ne_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 7)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; arm body: one controlled Rz per gate, IN PLACE on q. The §5 re-anchor is what
; puts %[[Q]] at arg 0 — `clang -O1` folded it to the constant 7 in the arm.
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_ne_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 7)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; no-spurious-free + re-anchor + dephasing guards
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cq_phi
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — one (the flag; there is no work rail any more), no second.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; No swap route survives: no |0> work rail, no CSWAP — window is `define` -> EOF.
; NOROUTE:     define i32 @example
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
