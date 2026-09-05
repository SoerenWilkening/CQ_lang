; control_phase_switch_kickback.ll — ACCEPT. P5, THE REGISTER-FREE PHASE SWITCH
; (bd test_C_libtooling-3qlq Inc 1 part B, PRD `retire-swap-route-PRD.md` §6.2
; row P5).
;
;     switch (q) { case 0: cq_phi(.1); case 1: cq_phi(.2); case 2: cq_phi(.3); }
;
; N INDEPENDENT KICKBACKS AND NOTHING ELSE: per content case, mint
; `f_i = (q == k_i)` into a |0> ancilla, put that case's phases ON `f_i` with
; `cqrt_rz_i1`, strip with the `_unc` twin, free. The eq-flags are MUTUALLY
; EXCLUSIVE (`q` equals at most one literal) and NOTHING here touches `q`, so the
; cases compose and every later mint reads the pristine register.
;
; WHAT IT REPLACES (PRD §1): the 4.5 route emitted, per case, an
; `cqrt_alloc_i32` work rail, `cqrt_cswap` in, a TENSORED `cqrt_rz_i32` on the
; rail, `cqrt_cswap` back, and two frees. `cqrt_rz_<W>` is Rz on EACH qubit, so
; the marked branch got `(-1)^popcount(k_i)` and `|0..0>` could not be marked at
; all — every shipped golden was the identity on `q`. The §5 CONST-FOLD RE-ANCHOR
; SCRUB is retired with it: a `void @cq_phi(double)` has no arg-0 to fold and this
; region has no merge φ to degenerate.
;
; ⚠ NO PLAIN-C `-O1` CUSTOMER EXISTS FOR THIS SHAPE, MEASURED OVER 7 SPELLINGS.
; A phase arm's only possible content is `call void @cq_phi(double)`, so every
; arm's suffix is identical modulo one operand and SimplifyCFG's common-code
; sinking ALWAYS applies: dense case values become a `@switch.table` of angles (or
; of pointers) with ONE shared call, sparse ones a cascade of blocks joined by
; `phi double`. Neither is this shape and both keep their existing loud declines
; — see control_phase_switch_reject_table_fold.ll. The construct is therefore
; exercised from hand IR, the same footing the if/else kickback arm has had since
; part A; a table-fold recognizer is a separate capability (prep-b OQ-4).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [
    i32 0, label %a0
    i32 1, label %a1
    i32 2, label %a2
  ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
a2:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; THE EMITTED STREAM, DERIVED FROM THE PASS OUTPUT (never typed: the Inc-4
; round-1 review found 9 of 20 fixtures naming an SSA value the pass never
; produced). Ordered CHECK-NEXT, so a gate inserted anywhere in the run fails.
; CHECK:      %[[V0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V1:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 5.000000e-01)
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[V0]], i32 0)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V2]], double 1.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[V2]], i32 %[[V0]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V2]])
; CHECK-NEXT: %[[V3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[V0]], i32 1)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V3]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[V3]], i32 %[[V0]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V3]])
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[V0]], i32 2)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V4]], double 3.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[V4]], i32 %[[V0]], i32 2)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V4]])
; CHECK-NEXT: %[[V5:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE (the Inc-3 F-L6-1 / Inc-4 F-L7-1 discipline: a
; POSITIVE directive inside a prefix WINDOWS every negative one of that prefix,
; so counts live in their own prefixes and NOROUTE carries no positives). The
; four things a register-free kickback must NEVER emit: a route of any kind, a
; `_controlled` gate, a `cqrt_rz_<W>` for W != i1 (the TENSORED per-register Rz
; PRD §1 records as the defect), and a surviving `@cq_phi` call.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled
; NOROUTE-NOT: cqrt_rz_i8
; NOROUTE-NOT: cqrt_rz_i16
; NOROUTE-NOT: cqrt_rz_i32
; NOROUTE-NOT: cqrt_rz_i64
; NOROUTE-NOT: cqrt_rz_f32
; NOROUTE-NOT: cqrt_rz_f64
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
