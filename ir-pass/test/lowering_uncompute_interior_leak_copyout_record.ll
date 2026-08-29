; lowering_uncompute_interior_leak_copyout_record.ll — LEAK PROBE (M-B Increment
; 5a, bd test_C_libtooling-6uqc). INVARIANT 1: an interior candidate read as the
; SOURCE of a method-B `cqrt_copy_<W>` is not a candidate.
;
; The copy DESTINATION is a kept carrier the reversal never touches — the same
; relation to the reversal the output tape has (bd 5pio, owner ruling
; 2026-08-11) — so the same refusal applies for the same reason as the tape
; sibling. Bennett.jl requires nothing whatever of a copy destination, which is
; why the reclamation licence has to rest on the SOURCE's own chain; the interior
; partition declines to make that argument for a rail whose destination it does
; not own and leaves the rail allocated.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_copy_i32(i32, i32)

define i32 @leak_copyout(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a = mul i32 %q, 3
  %b = mul i32 %a, 5
  %dst = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %a, i32 %dst)
  %m = call i32 @cq_measure_si32(i32 %b)
  ret i32 %m
}

; CHECK-LABEL: define i32 @leak_copyout(
; CHECK: call void @cqrt_copy_i32
; CHECK: call i32 @cqrt_measure_i32
; CHECK-NOT: cq_template_mul_i32_hl_unc
; CHECK-NOT: call void @cqrt_free
