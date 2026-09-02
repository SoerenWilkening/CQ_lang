; control_inplace_ry_ifelse.ll — ACCEPT spec, the TWO-ARM control-in-place
; rotation if/else (control-in-place-PRD §4 R3, owner Q4; bd
; test_C_libtooling-drbq Inc 1).
;
;     if (c) r = cq_theta(r, .9); else r = cq_theta(r, .2);
;
; Both arms rotate the SAME base `r`, so ONE register is relabelled twice: the
; true arm under `flag` (unbracketed) and the false arm under `¬flag` (the
; `cqrt_x` bracket). Composed over the two branches that is exactly the source's
; unitary — on `flag=1` only the first gate fires, on `flag=0` only the second.
;
; ⚠ HAND-CONSTRUCTED IR, and the reason is worth recording. `clang -O1` does NOT
; emit this shape from the C above: both arms call the same opaque `cq_theta`, so
; SimplifyCFG MERGES them into ONE call with a `select i1 %c, double .9, double
; .2` on the ANGLE — a tainted-condition angle mux, which declines `rotation
; angle under quantum control` and never reaches this classifier (measured
; 2026-09-02). The if/else accept is therefore real but not reachable from that
; source spelling; it is kept because the classifier and emitter support it
; symmetrically with the diamond and a future frontend/optimization change must
; not silently lose it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
armf:
  %rf = call i32 @cq_theta_si32(i32 %r, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %armt ], [ %rf, %armf ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; TRUE arm first, unbracketed; FALSE arm second, inside the ¬flag bracket
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  cqrt_cswap
; CHECK-NOT:  phi i32

; ONE base register per arm: two allocs total, no work rail; one free (the flag)
; CNT-COUNT-2: call i32 @cqrt_alloc_i32(
; CNT-NOT:     call i32 @cqrt_alloc_i32(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
