; lowering_reject_uncompute_measured_parent_frozen_transitive.ll — DECLINE (bd
; test_C_libtooling-eqti; the TRANSITIVE leg of the kept-rail adjoint fence). The
; `clang -O1` IR of
;     int q = x; cq_theta(&q, .25); int a = q * 3; int k = a + 5; k = k ^ a;
;     cq_theta(&k, .5); printf("%d\n", k); cq_theta(&q, .3); return cq_measure(q);
;
; The kept (step-3b frozen: printed, then Ry) rail is `k = (3q+5) ^ 3q`, and its
; adjoint `xor_i32_unc(k, 3q, 3q+5)` reads no borrowed register DIRECTLY — only the
; OWNED rails `3q` and `3q+5`, which the same reversal then returns to |0> and
; frees. Their labels are functions of the borrowed, measured `q`, so the adjoint
; is a q-controlled gate onto a leaked, recorded rail all the same, and `ry(q,.3)`
; after the reversal reads the changed coherence. MEASURED on the pre-eqti binary
; (8e4bc89a): `opt` exit 0 with one M-A warning, stage 2b clean, stream
; ... ry(k,.5); tape_write(T,k);
; ry(k,-.5); xor_i32_unc(k, 3q, 3q+5); add_unc; free; mul_unc; free; ry(q,.3);
; measure(q), with `k` never freed. `keptRailAdjointReadsBorrowed` closes the
; borrowed-dependence over the reduced DAG to a fixpoint, so it refuses; a
; direct-reads-only version of the fence accepts this module (the mutant this
; file kills).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)

define i32 @slice(i32 %0) {
  %2 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %3 = mul nsw i32 %2, 3
  %4 = add nsw i32 %3, 5
  %5 = xor i32 %4, %3
  %6 = tail call i32 @cq_theta_si32(i32 %5, double 5.000000e-01)
  %7 = tail call i32 (ptr, ...) @printf(ptr @.str, i32 %6)
  %8 = tail call i32 @cq_theta_si32(i32 %2, double 3.000000e-01)
  %9 = tail call i32 @cq_measure_si32(i32 %8)
  ret i32 %9
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
