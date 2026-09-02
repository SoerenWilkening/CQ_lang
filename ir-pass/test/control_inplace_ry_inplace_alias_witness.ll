; control_inplace_ry_inplace_alias_witness.ll — the CONTROL for
; `control_inplace_ry_reject_inplace_alias_base.ll` (round-1 Rule-13 review,
; lens L1 §1). No region at all: just the compare and the `xor`.
;
; Its whole job is to MEASURE the premise the decline fixture rests on, rather
; than assert it in prose: `int b = q ^ 2` with no later data use of `q` really
; is lowered by M-C IN PLACE, on `q`'s own rail (`cqrt_xorc_i32(%h, 2)` — no
; `cq_template_xor_*`, no second `cqrt_alloc`). So `%b` and `%q` are two SSA
; names for ONE physical wire, which is what makes the sibling fixture a
; TRUE-POSITIVE R4 decline and not the over-decline the family's only other R4
; fixture is.
;
; If a future change makes this `xor` lower OUT of place, this fixture reddens
; and the sibling's header stops being true — which is the point of committing
; the two together.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %b = xor i32 %q, 2
  %m = call i32 @cq_measure_si32(i32 %b)
  ret i32 %m
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: call void @cqrt_xorc_i32(i32 %[[Q]], i32 2)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])

; ONE rail: the `xor` mints nothing.
; CNT-COUNT-1: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-NOT:     cq_template_xor
