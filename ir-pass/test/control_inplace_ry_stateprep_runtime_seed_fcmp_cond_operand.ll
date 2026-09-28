; control_inplace_ry_stateprep_runtime_seed_fcmp_cond_operand.ll — ACCEPT (bd
; test_C_libtooling-z0re): the fp mirror of
; `control_inplace_ry_stateprep_runtime_seed_cond_operand.ll`. A RUNTIME f64 seed
; that is also the classical operand of the region's own `fcmp oeq`.
;
;     double s = atof(v[2]); double r = s; if (x == s) r = cq_theta(s, .2);
;
; The RELATIONAL half of F2 reads the branch's `fcmp` through the SAME polarity
; table the literal fp ANCHOR uses (`fcmpEqualityHoldsOnEdge`): on the TRUE edge
; `%x == %s` holds, so a live tainted value IS equal to the seed there — `%x`, the
; compare's own operand, a member of `CondWire`, excluded at the TEST by the
; owner's 2026-09-11 ruling. A mutant that drops the exclusion DECLINES this file
; (`state prep seed is proven equal to the condition register`; TRACK_Z0RE.md §7),
; which is what makes the fp relational half measured-live rather than dead.
;
; (LLVM 19 does not substitute across `fcmp oeq` at all — `+0.0 == -0.0` — so the
; in-place rival `r = cq_theta(x, .2)` could not produce this module even with an
; equality-propagating pass; notes §9 item 24.)
;
; On the ORACLE this module DECLINES at F1's literal-only clause.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %s) {
entry:
  %x = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp oeq double %x, %s
  br i1 %c, label %arm, label %merge
arm:
  %rt = call double @cq_theta_f64(double %s, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi double [ %rt, %arm ], [ %s, %entry ]
  %mr = call double @cq_measure_f64(double %rm)
  %mx = call double @cq_measure_f64(double %x)
  %sum = fadd double %mx, %mr
  ret double %sum
}

; CHECK:      %[[X:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 %[[X]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_oeq_f64_hl(i32 %[[X]], double %s)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %s)
; CHECK-NEXT: call void @cqrt_ry_f64_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_fcmp_oeq_f64_hl_unc(i32 %[[F]], i32 %[[X]], double %s)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; NEG-NOT: cq_theta_
; NEG-NOT: = phi
