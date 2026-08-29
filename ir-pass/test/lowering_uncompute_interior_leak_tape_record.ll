; lowering_uncompute_interior_leak_tape_record.ll — LEAK PROBE (M-B Increment 5a,
; bd test_C_libtooling-6uqc). INVARIANT 1: an interior candidate RECORDED into a
; kept 7.6 output tape is not a candidate.
;
; `%h_op` feeds both a forward `mul` and a `cqrt_tape_write_i32`.
; `ChainWalk::isInteriorConsumer` rejects the tape write. That looks redundant
; beside the 261j record freeze — the freeze would also refuse to free a rail a
; kept carrier records — but it is NOT: the freeze consults
; `preservesBasisUnderRecord` PER GATE, and this rail's only gate IS a basis
; permutation, so the freeze would clear it for freeing. What actually protects it
; is the 261j invariant's clause (d): the tape entry is a register the reversal
; never touches AND never restores, so ordering the free after the write is not
; enough on its own — the interior partition has no view of the tape's own
; lifetime. Refusing the rail up front is the Rule-6 fallback (left allocated).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i32(i32, i32)

define i32 @leak_taped(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %b = mul i32 %a, 5
  %tape = call i32 @cqrt_tape_alloc()
  %w = call i32 @cqrt_tape_write_i32(i32 %tape, i32 %a)
  %m = call i32 @cq_measure_si32(i32 %b)
  ret i32 %m
}

; CHECK-LABEL: define i32 @leak_taped(
; CHECK: call i32 @cqrt_tape_write_i32
; CHECK: call i32 @cqrt_measure_i32
; CHECK-NOT: cq_template_mul_i32_hl_unc
; CHECK-NOT: call void @cqrt_free
