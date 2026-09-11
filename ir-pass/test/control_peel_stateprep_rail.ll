; control_peel_stateprep_rail.ll — ACCEPT (bd test_C_libtooling-b6ap × bd
; test_C_libtooling-l4x4 sub-increment l4x4.b): the OWNER'S OWN FILE with `int b1`
; — `example/grover/grover_oracle_uncompute.c` at `-O1`, b6ap probe
; `p01_owner_intb1`. The peel FIRES (P7 clause (b) admits a bare RAIL condition,
; and the `a` data mux is peeled to a select), and what is left is the STATE-PREP
; ARM on a bare `_Bool` rail — which l4x4.b lowers.
;
; ⚠ THIS FILE WAS `control_peel_reject_stateprep_rail.ll`, A DECLINE, AND ITS OWN
; HEADER PREDICTED THIS FLIP IN WRITING: *"this fixture FLIPS TO AN ACCEPT when bd
; `l4x4` lands"*. It flipped at the l4x4.b × main(A.1 + b6ap) MERGE (2026-09-11,
; `session-l4x4/MERGE_l4x4_1.md`) — the first binary that carries the peel AND the
; bool prep arm — and is REWRITTEN as the accept rather than deleted, the Inc-1b
; `control_phase_kickback_reject_bare_i1.ll` → `..._rail_diamond.ll` precedent.
; Three dispositions of one module, in order: `main` 0c7380c declined
; `control flow` (the 2-phi wall); b6ap alone declined `bare i1 register
; condition` (the wall one increment further in); here it lowers.
;
; WHAT THE STREAM IS, read against the source line by line — the point of the
; fixture is that the two mechanisms COMPOSE on ONE rail with no interference:
;   * `%h` is the user's `_Bool` register (`cqrt_alloc_i1` + `cqrt_ry_i1`). It is
;     NEVER `cqrt_x`-bracketed and NEVER freed (Inc 1b's invariant + Rule 6); the
;     only gates touching it are READ-ONLY controls and its own `cqrt_measure_i1`.
;   * THE STATE PREP IS ON THE FALSE EDGE, so it is emitted by l4x4.b's
;     ANTI-CONTROL BY Ry ADDITIVITY: an unconditional `cqrt_ry_i32(%h2, +0.5)`
;     then `cqrt_ry_i32_controlled(%h, %h2, -0.5)`. b = 1 ⇒ Ry(θ)Ry(−θ) = I ⇒ the
;     seed 0, which is the `[0, %entry]` incoming; b = 0 ⇒ Ry(θ)|0⟩, the prep.
;     `−θ` is an IEEE SIGN FLIP, not an `fsub`, so no rounding fence applies.
;   * THE PEELED MUX is the r9e5 (1b-B.1) rail-root CNOT COPY: `%bf` is a fresh
;     `|0⟩` ancilla, `cqrt_cnot(%h, %bf)` copies the basis label, the cleared 4.4
;     stream runs X-bracketed ON THE ANCILLA, and the second `cqrt_cnot` returns
;     `%bf` to `x ⊕ x = 0` for a proven-|0⟩ `cqrt_free` (Rule 6). `%h` is read
;     twice as a control and is byte-for-byte unmodified between the two reads.
; NOTHING IS MINTED FOR THE CONDITION — the `NOROUTE` block below pins the absence
; of any `cq_template_icmp_*` flag, which is the whole difference from the `int`
; twin `control_peel_stateprep_datamux.ll` (5 allocs / 4 `cqrt_x` / 2 frees / 3
; `_unc` there; 6 / 2 / 1 / 0 here).
;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`): the
; peel is ACCEPT-ONLY and emits NO gate and NO runtime symbol; every gate checked
; below belongs to the pre-existing substrate (4.4 `SelectMergeEmit`) or to
; l4x4.b's in-place rotation emitter.

; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CPCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

define i32 @example()  {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) 
  br i1 %1, label %4, label %2

2:                                                ; preds = %0
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) 
  br label %4

4:                                                ; preds = %2, %0
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ]
  %6 = phi i32 [ %3, %2 ], [ 0, %0 ]
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1) 
  %8 = zext i1 %7 to i32
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6) 
  %10 = add nsw i32 %9, %8
  %11 = tail call i32 @cq_measure_si32(i32 noundef %5) 
  %12 = add nsw i32 %10, %11
  ret i32 %12
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) 

declare i32 @cq_theta_si32(i32 noundef, double noundef) 

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) 

declare i32 @cq_measure_si32(i32 noundef)

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[H]], i32 %[[H2]], double -5.000000e-01)
; CHECK-NEXT: %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[SELOP:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: %[[SELOP2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[SELOP2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[H]], i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i1 @cqrt_measure_i1(i32 %[[H]])
; CHECK-NEXT: %[[Z:[a-zA-Z0-9_.]+]] = zext i1 %[[M]] to i32
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H2]])
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = add nsw i32 %[[M2]], %[[Z]]
; CHECK-NEXT: %[[M3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = add nsw i32 %[[S1]], %[[M3]]
; CHECK-NEXT: ret i32 %[[S2]]

; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive line
; inside one WINDOWS every negative after it — the drbq Inc-4 F-L6-1 lesson).
; The two that matter most here are `cq_template_icmp` (a rail condition mints NO
; flag) and `cqrt_x(i32 %h)`-on-the-register, which is spelled as the absence of
; any `cqrt_x` beyond the ancilla's two, pinned by XCNT.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cq_template_icmp
; NOROUTE-NOT: _unc(
; NOROUTE-NOT: cqrt_rz_
; NOROUTE-NOT: call i32 @cq_theta_
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = select
; ---- Whole-file EXACT COUNTS. An injected extra `cqrt_x` / `cqrt_free` / CNOT /
; controlled copy / rotation, or a DROPPED one, moves one of these even when it
; slots into a position the ordered stream above still matches.
; XCNT-COUNT-2: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; ACNT-COUNT-6: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; CNCNT-COUNT-2: call void @cqrt_cnot(
; CNCNT-NOT:     call void @cqrt_cnot(
; CPCNT-COUNT-2: call void @cqrt_copy_
; CPCNT-NOT:     call void @cqrt_copy_
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
; MCNT-COUNT-3: call i{{1|32}} @cqrt_measure_
; MCNT-NOT:     call i{{1|32}} @cqrt_measure_
