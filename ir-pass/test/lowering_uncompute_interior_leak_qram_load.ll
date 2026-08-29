; lowering_uncompute_interior_leak_qram_load.ll — LEAK PROBE (M-B Increment 5a,
; bd test_C_libtooling-6uqc). THE NAMED SCOPE GAP: a `cqrt_qram_load_<W>` rail is
; NOT an interior candidate in Increment 5, and it is excluded BY SCOPE rather
; than by physics.
;
; `%v` (the load result) is consumed forward by a `mul` template and would satisfy
; every other clause: it is a fresh rail, `preservesBasisUnderRecord` accepts a
; QRAM load (a cell copy conditioned on arr/idx), and its `_unc` is out-first like
; any template's. What Increment 5 does not do is reason about its PARENTS — the
; array handle is mutated in place by `cqrt_qram_store_<W>`, which is a whole
; 7.5-Shadow lifetime the clause-(d) scan would have to model, and severance class
; 4 (QRAM array cells) is the ruled-DEFERRED class at the M-A guard for the same
; reason (owner ruling 2026-08-27, second round, point 4).
; `ChainWalk::isInteriorTerminalHandle` therefore narrows (I1) to `cq_template_*`
; explicitly, and this fixture is the pin: if a later increment lifts the QROM/QRAM
; surface, THIS is the file that must change deliberately.
;
; THE INDEX RAIL IS A DIFFERENT MATTER AND IT *IS* DISCHARGED — see
; lowering_uncompute_interior_qram_index.ll. The array is what is deferred, not
; every rail that touches one.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_qram_load(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %i
  %v = load i32, ptr %g
  %w = mul i32 %v, 5
  %m = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; CHECK-LABEL: define i32 @leak_qram_load(
; CHECK:      %[[ARR:.*]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[V:.*]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[H]])
; CHECK-NEXT: call i32 @cq_template_mul_i32_hl(i32 %[[V]], i32 5)
; CHECK-NEXT: call i32 @cqrt_measure_i32
; the load rail is LEFT ALLOCATED — no adjoint, no free
; CHECK-NOT: cqrt_qram_load_i32_unc
; CHECK-NOT: call void @cqrt_free
