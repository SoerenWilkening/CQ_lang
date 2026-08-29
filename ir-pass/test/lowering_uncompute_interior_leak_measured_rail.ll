; lowering_uncompute_interior_leak_measured_rail.ll — LEAK PROBE (M-B Increment
; 5a, bd test_C_libtooling-6uqc). INVARIANT 1: an interior candidate that is
; itself MEASURED is not a candidate at all.
;
; `%h_op` has two users — the `mul` that consumes it forward, and a
; `cqrt_measure_i32`. `ChainWalk::isInteriorConsumer` rejects the measure, so
; `%h_op` never enters the owned set. Had it been admitted, the reversal would
; have emitted `mul_unc(%h_op, %h, 3); cqrt_free(%h_op)` on a register the user's
; own measurement still reads — a free of a measured register, which is the
; hidden projective collapse Rules 5/6 exist to forbid and which the whole-DAG
; spine spends a LOUD diagnostic on (`kMsgLineageMeasured`).
;
; IT IS A LEAK, NOT A DECLINE, AND THAT IS THE DESIGN. M-B is leak-first: an
; unprovable rail is LEFT ALLOCATED and the LATE M-A guard
; (`declineLiveRecordRotations`) owns loudness for a record still standing at a
; non-diagonal gate. There is no chained `cq_theta` here, so nothing is dephased
; and nothing should be loud — `opt` exits 0 and no rail is freed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_measured(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %b = mul i32 %a, 5
  %m1 = call i32 @cq_measure_si32(i32 %a)
  %m2 = call i32 @cq_measure_si32(i32 %b)
  %s = add i32 %m1, %m2
  ret i32 %s
}

; CHECK-LABEL: define i32 @leak_measured(
; CHECK: call i32 @cq_template_mul_i32_hl
; CHECK: call i32 @cq_template_mul_i32_hl
; CHECK: call i32 @cqrt_measure_i32
; CHECK: call i32 @cqrt_measure_i32
; CHECK-NOT: cq_template_mul_i32_hl_unc
; CHECK-NOT: call void @cqrt_free
