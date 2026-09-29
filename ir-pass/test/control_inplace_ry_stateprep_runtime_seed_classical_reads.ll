; control_inplace_ry_stateprep_runtime_seed_classical_reads.ll — ACCEPT (bd
; test_C_libtooling-z0re): the runtime seed is READ CLASSICALLY after the region.
;
;     int r = s; if (q > 3) r = cq_theta(s, .2);
;     return cq_measure(r) + s * 3;          // `s` read after the region
;
; This file pins WHY R4 and R6 are SKIPPED (not handed the seed) for a state prep —
; §14.5's argument, and bd z0re's reason it matters MORE for a runtime seed than for
; a literal. The rotated rail is minted by the hoisted theta, so it has no
; pre-region SSA name; `s` is a CLASSICAL value, not a record of that rail. Had R6
; been asked of `railWireClosure(%s)` (whose `Out.insert(W)` runs before its taint
; gate) it would enumerate `mul %s, 3` — a user after the region — and decline
; `stale rail record read past a controlled Ry` on a program with no record at all.
; The classical `mul` stays a plain `mul` in the output (no template: `s` is
; untainted at every stage).
;
; On the ORACLE this module DECLINES at F1's literal-only clause.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %s) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %s, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %s, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s3 = mul i32 %s, 3
  %sum = add i32 %mr, %s3
  ret i32 %sum
}

; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %s)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[R]], double 2.000000e-01)
; CHECK:      %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: %s3 = mul i32 %s, 3
; CHECK-NEXT: add i32 %[[M]], %s3

; NEG-NOT: cq_template_mul
; NEG-NOT: cq_theta_
