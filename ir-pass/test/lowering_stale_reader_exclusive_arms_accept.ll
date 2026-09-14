; lowering_stale_reader_exclusive_arms_accept.ll — ACCEPT. THE `RequireEmitDominance`
; LEG-1 PIN for bd test_C_libtooling-3d8q: two in-place Ry on ONE rail that NEVER
; BOTH RUN.
;
; `%pa` and `%pb` are siblings on `%h`'s wire in the two arms of a CLASSICAL
; branch. Neither can stale the other — on any trace that reaches one, the other
; never executed — but NEITHER DOMINATES THE OTHER, so the shipped position-aware
; proof's dominance PRECONDITION (`DT.dominates(EmitPoint, T)`, kept for the
; pure-op policy) refuses both outright. The reader policy passes
; `RequireEmitDominance=false` so leg 1 (`!isPotentiallyReachable(T, EmitPoint)`)
; is asked directly, which is the exact proof this shape has.
;
; ⚠ THIS IS NOT A HYPOTHETICAL: without the bit, 14 shipped Rule-13-cleared
; fixtures flip to DECLINE, the whole drbq in-place controlled-Ry if/else family
; (`control_inplace_ry_ifelse.ll`, `..._sequential.ll`, …) plus
; `lowering_uncompute_escape_unrecognized.ll`, of which this file is the reduced
; form. An ACCEPT→DECLINE on a well-formed program is a DEFECT, not a safety
; margin (owner ruling 2026-09-11).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XFCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; Each arm measures its OWN chain tip, so the only question left in the module is
; the one this file exists for: is the sibling arm's Ry evidence against this
; arm's read? (No — they never both run.) Leaving the arm results DEAD instead
; declines at the Phase-5 spine, one owner later
; (`lowering_uncompute_escape_unrecognized.ll` is exactly that module and is a
; shipped DECLINE — it still declines there, NOT here, which is its own small
; witness that this fence stays a backstop.)
define i32 @slice(i32 %x, i1 %c) {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  br i1 %c, label %a, label %b
a:
  %pa = call i32 @cq_theta_si32(i32 %h, double 1.000000e-01)
  %ma = call i32 @cq_measure_si32(i32 %pa)
  ret i32 %ma
b:
  %pb = call i32 @cq_theta_si32(i32 %h, double 2.000000e-01)
  %mb = call i32 @cq_measure_si32(i32 %pb)
  ret i32 %mb
}

; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 1.000000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.000000e-01)

; RCNT-COUNT-3: call void @cqrt_ry_i32(
; RCNT-NOT: call void @cqrt_ry_i32(

; Counts in their OWN whole-file prefixes (a positive line inside a negative
; prefix WINDOWS every negative after it — Rule 12 fixture-hygiene defect (a)).
; Added by the injection matrix: `extra_x`, `extra_free`, `extra_alloc`,
; `drop_measure` and `dup_measure` were each caught by NO block.
; ACNT-COUNT-1: call i32 @cqrt_alloc_i32(
; ACNT-NOT: call i32 @cqrt_alloc_i32(

; MCNT-COUNT-2: call i32 @cqrt_measure_i32(
; MCNT-NOT: call i32 @cqrt_measure_i32(

; NOTHING is bracketed and NOTHING is freed: the rail is the user's, both arms
; measure it, and no ancilla is minted.
; XFCNT-NOT: call void @cqrt_x(
; XFCNT-NOT: call void @cqrt_free(

; NOQ-NOT: cq_theta_si32
; NOQ-NOT: cqrt_ry_i32_controlled
