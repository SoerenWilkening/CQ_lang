; control_phase_kickback_and3_tree.ll — ACCEPT. P3 at DEPTH 2: `(a && b) && c`
; (bd test_C_libtooling-3qlq Inc 1 part B).
;
; Three leaf flags, TWO conjunction ancillas, and the property this fixture
; exists for is the ORDER of the teardown: the strip walks the nodes in REVERSE
; post-order, so the PARENT (`%g3`) un-computes and is freed while its child
; (`%g`) is STILL ALLOCATED — the parent's inverse toffoli READS `%g`, so freeing
; the child first would be a use-after-free of a rail whose value the undo needs.
; Only then do the leaves strip, in reverse mint order. The ordered CHECK-NEXT
; run below is the whole assertion; a count-only check cannot see it.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDTAG < %t.cqd0.ll


; ── Rule-13 ROUND-2 finding F-R2-1, the assertion repair ────────────────────
; Round 1 repaired three assertion families (the 8-width Rz negative, the
; `cqrt_x` negative, the `cqrt_free` count) in the corpus IT could see, and the
; merge brought in a set that had never been asked the same question. Measured by
; injection at `c4bd888`: `cqrt_rz_f80`/`f16` NOT CAUGHT in 18 accepts, an
; UNPAIRED `cqrt_x` (a wrong-branch phase) NOT CAUGHT in 21, an EXTRA
; `cqrt_free` (a hidden measurement, Rule 6) NOT CAUGHT in 20. Every accept in
; the branch now carries all three, and each is validated by injecting the line
; into this fixture's OWN output.
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
; NOROUTE-NOT: call void @cqrt_x(i32

; The `cqrt_free` census. An EXTRA free is a hidden measurement (Rule 6).
; FCNT-COUNT-5: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(



; ── THE BRANCH-PHASE RECORD, COUNTED — Rule-13 round-2, the `g_drop_mark`
; injection. Round 1's F-L7-1 was a CONFIRMED miscompile in which the whole-DAG
; spine ADJOINTED a kickback gate and cancelled the user's phase exactly; the
; `!cq.branchphase` record on every emitted gate is what stops it. Dropping that
; record from one gate was CAUGHT by 15 of the 35 gate-bearing accepts and MISSED
; by 20 — including every P4 nest but one and every P5 switch but one. MDCNT
; counts the GATES and MDTAG the MARKED gates, in SEPARATE prefixes, and they
; must agree. (An unmarked gate BEFORE a marked one moves only MDCNT; a dropped
; mark moves only MDTAG; an extra marked gate after moves both — round-2 F-R2-11.)
; MDCNT-COUNT-1: call void @cqrt_rz_i1(
; MDCNT-NOT: call void @cqrt_rz_i1(
; MDTAG-COUNT-1: call void @cqrt_rz_i1({{.*}}), !cq.branchphase
; MDTAG-NOT: call void @cqrt_rz_i1(


declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %u2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %s = call i32 @cq_theta_si32(i32 %u2, double 1.250000e-01)
  %ca = icmp eq i32 %q, 5
  %cb = icmp eq i32 %r, 3
  %cc = icmp eq i32 %s, 7
  %n1 = select i1 %ca, i1 %cb, i1 false
  %c = select i1 %n1, i1 %cc, i1 false
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  %n = call i32 @cq_measure_si32(i32 %r)
  %o = call i32 @cq_measure_si32(i32 %s)
  %t1 = add i32 %m, %n
  %t2 = add i32 %t1, %o
  ret i32 %t2
}

; THE EMITTED STREAM, DERIVED FROM THE PASS OUTPUT (never typed: the Inc-4
; round-1 review found 9 of 20 fixtures naming an SSA value the pass never
; produced). Ordered CHECK-NEXT, so a gate inserted anywhere in the run fails.
; CHECK:      %[[V0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V1:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V0]], double 5.000000e-01)
; CHECK-NEXT: %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V3:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V2]], double 2.500000e-01)
; CHECK-NEXT: %[[V4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V5:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[V4]], double 1.250000e-01)
; CHECK-NEXT: %[[V6:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[V0]], i32 5)
; CHECK-NEXT: %[[V7:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[V2]], i32 3)
; CHECK-NEXT: %[[V8:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V6]], i32 %[[V7]], i32 %[[V8]])
; CHECK-NEXT: %[[V9:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[V4]], i32 7)
; CHECK-NEXT: %[[V10:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V8]], i32 %[[V9]], i32 %[[V10]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[V10]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V8]], i32 %[[V9]], i32 %[[V10]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V10]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[V6]], i32 %[[V7]], i32 %[[V8]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V8]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[V9]], i32 %[[V4]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V9]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[V7]], i32 %[[V2]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V7]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[V6]], i32 %[[V0]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V6]])
; CHECK-NEXT: %[[V11:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V0]])
; CHECK-NEXT: %[[V12:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V2]])
; CHECK-NEXT: %[[V13:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[V4]])

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
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
