; control_peel_qq_datamux.ll — ACCEPT (bd test_C_libtooling-b6ap): the peeled phi
; is a Q+Q MUX — `phi i32 [%p, %arm], [%p+3, %entry]` over TWO DISTINCT TAINTED
; REGISTERS, both available at the pred. Probe `p90_qq_mux` / hand peel `h90`.
;
; RED-GREEN: `control flow under quantum control` on `main` 0c7380c.
;
; ⚠ SCOPE H-8 — THE FIRST TIME THE *PEEL* RATHER THAN THE SOURCE CREATES A
; NO-CLONING QUESTION, so the Rule-8 argument is re-derived here rather than
; inherited. The merge is the shipped 4.4 controlled-XOR copy: a fresh |0> out-rail
; `%out` receives `cqrt_copy_i32_controlled(f, %h_op, %out)` on `f = 1` and, under
; the `cqrt_x` bracket, `cqrt_copy_i32_controlled(f, %h, %out)` on `f = 0`. Exactly
; ONE write per basis branch, so `out` is `f ? p+3 : p` with no cloning of either
; source; BOTH sources and `%out` are LEFT ALLOCATED (never freed dirty, Rules
; 6/8), and the only rail freed is the flag, after its `_unc` strip returns it to
; |0>. NOTHING here is new: it is the same stream the hand-written select produces.
;
; `%h_op` (the `add` chain head) is left allocated and entangled — a leak, the
; Rule-6-safe direction, and identical to the hand peel's disposition (stage 2b
; reports `0 violation(s)` on both).;
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
define i32 @example() {
entry:
  %p = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %b0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp eq i32 %b0, 1
  %p3 = add nsw i32 %p, 3
  br i1 %c, label %merge, label %arm
arm:
  %t1 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %merge
merge:
  %qmux = phi i32 [ %p, %arm ], [ %p3, %entry ]
  %b1 = phi i32 [ %t1, %arm ], [ 0, %entry ]
  %m0 = call i32 @cq_measure_si32(i32 %b0)
  %m1 = call i32 @cq_measure_si32(i32 %b1)
  %mq = call i32 @cq_measure_si32(i32 %qmux)
  %s1 = add nsw i32 %m0, %m1
  %s2 = add nsw i32 %s1, %mq
  ret i32 %s2
}

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; CHECK-NEXT: %[[HOP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H2]], i32 1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[HCMP]], i32 %[[H3]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H2]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[HCMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H2]], i32 1)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP1]], i32 %[[HOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP1]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[HCMP1]], i32 %[[H]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[HCMP1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP1]], i32 %[[H2]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP1]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H2]])
; CHECK-NEXT: %[[M4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H3]])
; CHECK-NEXT: %[[M5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M]], %[[M4]]
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S1]], %[[M5]]
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
; ACNT-COUNT-4: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; UCNT-COUNT-3: _unc(
; UCNT-NOT:     _unc(
; CPCNT-COUNT-3: @cqrt_copy_
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
