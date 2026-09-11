; control_peel_classical_call_datamux.ll — ACCEPT (bd test_C_libtooling-b6ap): the
; arm is a Phase-6.5 CLASSICAL CALL (a `memory(none)` `noinline` callee on a
; classical argument), and the merge holds its `%out` phi beside a constant data
; mux. The mux peels; the 6.5 arm keeps its own merge phi and lowers by the
; shipped `emitClassicalCallArmRegion` — the call HOISTED to the pred and its i32
; result route-merged into a fresh rail. Probe `p71_call_arm_opaque` / hand peel
; `h71`.
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.
;
; The peel is arm-class-BLIND: P1-P9 ask about the SHAPE and the phis, never about
; what the arm contains, which is why one predicate covers the state-prep arm, the
; phase arm, the 6.5 call arm and the value arm alike.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`): an
; accept-only normalisation that turns each merge phi a tainted control region does
; NOT define into a tainted-condition `select` on a CLONE of the region's compare,
; so `ControlDetect::soleMergePhi` sees the ONE phi it requires. It emits no gate
; and no runtime symbol; every gate checked here is the pre-existing substrate's.
; See `control_peel_stateprep_datamux.ll` for the full account and the
; byte-identity pair.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=UCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal fastcc i32 @f(i32 %x) unnamed_addr #0 {
  %a = mul nsw i32 %x, 3
  %b = add nsw i32 %a, 1
  ret i32 %b
}

define i32 @example() {
entry:
  %kp = alloca i32, align 4
  store volatile i32 4, ptr %kp, align 4
  %k = load volatile i32, ptr %kp, align 4
  %b0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  br i1 %c, label %merge, label %arm
arm:
  %r = call fastcc i32 @f(i32 %k) #1
  br label %merge
merge:
  %amux = phi i32 [ 5, %arm ], [ 2, %entry ]
  %out = phi i32 [ %r, %arm ], [ 0, %entry ]
  %m0 = call i32 @cq_measure_si32(i32 %b0)
  %ma = call i32 @cq_measure_si32(i32 %amux)
  %m1 = call i32 @cq_measure_si32(i32 %out)
  %s1 = add nsw i32 %m0, %ma
  %s2 = add nsw i32 %s1, %m1
  ret i32 %s2
}
attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind willreturn memory(none) }

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call fastcc i32 @f(i32 4) #1
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP]], i32 %[[SELOP]], i32 %[[OUT1]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: %[[SELOP2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP]], i32 %[[SELOP2]], i32 %[[OUT1]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[HCMP3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 1)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP3]], i32 %[[SELOP4]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP3]])
; CHECK-NEXT: %[[SELOP5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP3]], i32 %[[SELOP5]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP3]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP3]], i32 %[[H]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP3]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: %[[M6:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[M7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT1]])
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M]], %[[M6]]
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S1]], %[[M7]]
; CHECK-NEXT: ret i32 %[[S2]]


; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive
; line inside one WINDOWS every negative after it — the drbq Inc-4 F-L6-1 lesson).
; The peel emits NOTHING itself: every gate below is the pre-existing substrate's.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cq_theta_
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = select
; ---- Whole-file EXACT COUNTS. An injected extra `cqrt_x` / `cqrt_free` /
; controlled copy, or a DROPPED `_unc` strip, changes one of these even when
; it slots into a position the ordered stream above still matches.
; XCNT-COUNT-4: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; ACNT-COUNT-7: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-3: _unc(
; UCNT-NOT:     _unc(
; CPCNT-COUNT-5: @cqrt_copy_
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-1: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
