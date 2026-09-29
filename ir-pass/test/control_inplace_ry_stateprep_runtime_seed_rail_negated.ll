; control_inplace_ry_stateprep_runtime_seed_rail_negated.ll — ACCEPT (bd
; test_C_libtooling-z0re): a RUNTIME seed under a NEGATED bare `_Bool` rail
; condition — the one spelling where the emitter CLONES the hoisted theta.
;
;     int r = s; _Bool b = cq_theta((_Bool)0, .5); if (!b) r = cq_theta(s, .2);
;
; The rail path fires `¬b` by Ry ADDITIVITY (no `cqrt_x` on a user register):
; the hoisted theta `T` stays the UNCONDITIONAL twin (`alloc(s); ry(h, .2)`) and
; its clone `TNeg` becomes the cancelling `ry_controlled(b, h, -.2)`. That matters
; for the bd z0re L1 record: the SOURCE theta — the one whose arg-0 IS the seed,
; and the one `declineRound2QuantumPrepSeeds` must read — is `T`, not the last
; gate `TNeg` that M-β RAUWs the merge to. The emitter captures it BEFORE the
; per-gate loop for exactly this reason; this file is the accept that exercises
; that capture (its decline twin is `…_runtime_seed_round2_quantum.ll`).
;
; On the ORACLE this module DECLINES at F1's literal-only clause.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_measure_i1(i1)

define i32 @example(i32 %s) {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %b, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 %s, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %s, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %zb = zext i1 %mb to i32
  %sum = add i32 %mr, %zb
  ret i32 %sum
}

; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %s)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[B]], i32 %[[R]], double -2.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

; The register IS the flag: nothing minted, stripped or freed, no bracket on it.
; NEG-NOT: call void @cqrt_free(
; NEG-NOT: call void @cqrt_x(
; NEG-NOT: cq_theta_
; NEG-NOT: = phi
