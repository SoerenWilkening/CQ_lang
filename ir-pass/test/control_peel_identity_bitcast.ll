; control_peel_identity_bitcast.ll — ACCEPT (bd test_C_libtooling-b6ap, Rule-13
; ROUND-2 finding F-B6R2-1 — `foldIdentityBitcasts` is the FIFTH taint-delta
; consumer). A same-width int<->int `bitcast` READS the peeled mux:
;
;     %mux = phi i32 [ 7, %arm ], [ 5, %entry ]
;     %bc  = bitcast i32 %mux to i32          ; a zero-gate IDENTITY
;     %w   = add nsw i32 %bc, 3
;
; `foldIdentityBitcasts` (`TaintPropagation.cpp`) is the SOLE handler for that
; opcode and it folds ONLY a bitcast that is ALREADY `taint.Tainted` when it runs
; (`CQLoweringPass.cpp:159` / `:787`). `%bc` is CLASSICAL there — its operand is a
; constant-armed merge phi — and becomes tainted ~280 lines later, when the peel
; turns that phi into a `select`. Left standing, it has no template and the module
; died at `no template for opcode 'bitcast i32' in tainted context` while the
; HAND-PEELED twin of the SAME module lowered at exit 0 on BOTH binaries (probe
; `BC1_identity_bitcast` + `BC1_identity_bitcastt_handpeel`, reviewer's four-way
; matrix). That is an OVER-decline — never a wrong unitary, `castInScope` has no
; accept for an unfolded tainted bitcast — but it falsifies the increment's stated
; contract, "produce the module the hand peel already is".
;
; THE FIX: `foldIdentityBitcasts` is now call 1 of `adjudicateTaintDelta`, ahead of
; the four consumer-adjudicating stages, for the same reason it is wired first in
; both entry points — a standing identity node blinds the bespoke provenance walks
; those stages run. It is MONOTONE (RAUW `result === operand`, erase a no-op; it
; adds no taint and emits no gate) and IDEMPOTENT (a second run finds nothing left
; to fold), and `delta.empty()` still contains it to modules that actually peeled.
;
; RED-GREEN, MEASURED: `control flow under quantum control` on `main` 0c7380c (the
; 2-phi merge never got that far); `no template for opcode 'bitcast i32' in tainted
; context` on the round-1 fix tree b7d646c; the stream below now, whose runtime
; trace is BYTE-IDENTICAL (32 lines) to the ORACLE's lowering of the hand-peeled
; twin (`twin.sh BC1_identity_bitcast`).
;
; MUTANT (the pin): delete the `foldIdentityBitcasts` call from
; `adjudicateTaintDelta` and rebuild — this fixture returns to `opt` exit 1 with
; the `no template` string, and it is the ONLY fixture in the corpus that moves.
;
; THE WITNESS LINE is `call void @cqrt_addc_i32(i32 %[[OUT]], i32 3)`: the `add`
; reads the 4.4 merge OUT-RAIL DIRECTLY, which is what "the identity is folded"
; means — and `NOBC` asserts that no `bitcast` INSTRUCTION and no
; `cq_template_bitcast_*` call survives anywhere in the output (it cannot be
; spelled `-NOT: bitcast`: `%s` is this file's own path, so the `source_filename`
; line carries the word and the blunt negative is vacuously RED — measured).
;
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
; RUN: %filecheck %s --check-prefix=NOBC < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %a = call i32 @cq_theta_si32(i32 0, double 4.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %m
arm:
  %a2 = call i32 @cq_theta_si32(i32 %a, double 9.000000e-01)
  br label %m
m:
  %ap = phi i32 [ %a2, %arm ], [ %a, %entry ]
  %mux = phi i32 [ 7, %arm ], [ 5, %entry ]
  %nux = phi i32 [ 2, %arm ], [ 1, %entry ]
  %bc = bitcast i32 %mux to i32
  %w = add nsw i32 %bc, 3
  %x0 = call i32 @cq_measure_si32(i32 %ap)
  %x1 = call i32 @cq_measure_si32(i32 %w)
  %x2 = call i32 @cq_measure_si32(i32 %nux)
  %s1 = add nsw i32 %x0, %x1
  %s2 = add nsw i32 %s1, %x2
  ret i32 %s2
}

define i32 @main() {
  %r = call i32 @example()
  ret i32 0
}

; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: %[[HA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HA]], double 4.000000e-01)
; CHECK-NEXT: %[[HCMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[HCMP]], i32 %[[HA]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HCMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HCMP]])
; CHECK-NEXT: %[[HC1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HC1]], i32 %[[OUT]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HC1]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HC1]], i32 %[[OUT]], i32 5)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HC1]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HC1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HC1]])
; CHECK-NEXT: %[[HC2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HC2]], i32 %[[OUT2]], i32 2)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HC2]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[HC2]], i32 %[[OUT2]], i32 1)
; CHECK-NEXT: call void @cqrt_x(i32 %[[HC2]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[HC2]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HC2]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[OUT]], i32 3)
; CHECK-NEXT: %[[M0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[HA]])
; CHECK-NEXT: %[[M1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[M2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT2]])

; ---- The fold's own witness: NO bitcast INSTRUCTION survives (at any type), and
; no `cq_template_bitcast_*` was minted for one. (`-NOT: bitcast` alone would be
; VACUOUSLY RED here: `%s` is this file's own path, so the `source_filename` line
; contains the word.)
; NOBC-NOT: = bitcast
; NOBC-NOT: cq_template_bitcast

; ---- Whole-file negatives, each in its OWN pure-negative prefix (a positive
; line inside one WINDOWS every negative after it — the drbq Inc-4 F-L6-1 lesson).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cq_theta_
; NOROUTE-NOT: call void @cq_phi(
; NOROUTE-NOT: cq_phi_
; NOROUTE-NOT: = phi
; NOROUTE-NOT: = select
; ---- Whole-file EXACT COUNTS.
; XCNT-COUNT-4: call void @cqrt_x(
; XCNT-NOT:     call void @cqrt_x(
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; (bd dm7f.81: a constant or classical merge arm is a literal operand of cqrt_xorc_<W>_controlled, no longer an alloc'd rail + cqrt_copy_<W>_controlled; a zero arm emits no gate and no bracket. Counts below re-measured.)
; ACNT-COUNT-4: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; ---- (`_unc(` and `@cqrt_copy_` also match their own DECLARATION line, so these
; ---- two counts are calls + 1; the others are call-shaped and match no declare.)
; UCNT-COUNT-4: _unc(
; UCNT-NOT:     _unc(
; CPCNT-COUNT-1: @cqrt_copy_
; CPCNT-NOT:     @cqrt_copy_
; RYCNT-COUNT-3: call void @cqrt_ry_
; RYCNT-NOT:     call void @cqrt_ry_
