; control_inplace_ry_sequential_classical_between.ll — ACCEPT. The in-place
; rotation-arm half of the `RoutedBase` lifetime fix (round-1 Rule-13 review of
; bd test_C_libtooling-drbq Inc 1, lens L4 §2), where the same stale pointer
; caused an OVER-DECLINE rather than the crash its phase twin got.
;
;     if (q == 5) cq_theta(&r, .9);   /* region 1: in-place Ry            */
;     if (cc)     g();                   /* a CLASSICAL branch between them  */
;     if (p == 6) cq_theta(&r, .3);   /* region 2: in-place Ry on the SAME
;                                           register, base = region 1's φ    */
;
; THE DEFECT: `classifyArms` records `Region.RoutedBase` at DETECTION (Inc 1 made
; this field non-null on EVERY in-place accept, where before it was written only
; by the two const-fold re-anchors). Region 1 is emitted first and does
; `MergePhi->replaceAllUsesWith(base)`, which DOES rewrite region 2's arm theta's
; operand — a use — but NOT region 2's raw `RoutedBase` pointer. The emitter then
; compared the two (`T->getArgOperand(0) != Base`), found them different, and
; declined `control flow under quantum control`. One dereference short of the
; SIGSEGV its eq-fold sibling took (`control_swap_eqfold_classical_between.ll`).
;
; WHAT MAKES IT UNAMBIGUOUS RATHER THAN A JUDGEMENT CALL — three measured
; controls, each one line from this module:
;   * DELETE the classical branch  -> the hcrg chain shape, which ALWAYS lowered;
;   * `cq_theta` -> `cq_phi`       -> the phase twin, which ALWAYS lowered;
;   * SAME CFG, blocks re-laid-out -> lowered.
; Detection is pure SSA + DominatorTree analysis and cannot depend on textual
; block order, so a verdict that flips with it is emission-order, not semantics.
;
; `RoutedBase` is now a `llvm::WeakTrackingVH` (see `ControlPlan.h`): it follows
; the RAUW, so at region 2's emission it names region 1's base — which IS the
; register the arm theta now takes.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @g()

define i32 @example(i32 %cc) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 4, double 6.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.500000e-01)
  %t1 = icmp eq i32 %q, 5
  br i1 %t1, label %arm1, label %merge1
arm1:
  %r1 = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge1
merge1:
  %m1 = phi i32 [ %r1, %arm1 ], [ %r, %entry ]
  %cz = icmp eq i32 %cc, 0
  br i1 %cz, label %cjoin, label %cbody
cbody:
  call void @g()
  br label %cjoin
cjoin:
  %t2 = icmp eq i32 %p, 6
  br i1 %t2, label %arm2, label %merge2
arm2:
  %r2 = call i32 @cq_theta_si32(i32 %m1, double 3.000000e-01)
  br label %merge2
merge2:
  %m2 = phi i32 [ %r2, %arm2 ], [ %m1, %cjoin ]
  %a = call i32 @cq_measure_si32(i32 %q)
  %b = call i32 @cq_measure_si32(i32 %p)
  %c = call i32 @cq_measure_si32(i32 %m2)
  %s = add i32 %a, %b
  %s2 = add i32 %s, %c
  ret i32 %s2
}

; BOTH controlled gates fire on the ONE register %h3, in source order, each under
; its own flag — that shared handle is the whole assertion.
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK:      call void @g()
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %h2, i32 6)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %h2, i32 6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %h)
; CHECK:      call i32 @cqrt_measure_i32(i32 %h2)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])

; No route and no work rail on either region: three allocs (the three sources),
; two frees (the two flags), and the rotated register is FROZEN — never freed.
; CNT-COUNT-3: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-NOT:     call void @cqrt_cswap(
