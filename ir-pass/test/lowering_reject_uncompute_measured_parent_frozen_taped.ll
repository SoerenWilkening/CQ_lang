; lowering_reject_uncompute_measured_parent_frozen_taped.ll — DECLINE (bd
; test_C_libtooling-eqti, repro 1; the ptue Rule-11 round-1 finding F1). The
; `clang -O1` IR of
;     bool q = x; cq_theta(&q, .25); bool t = !q; cq_theta(&t, .5);
;     printf("%d\n", t); cq_theta(&q, .3); return cq_measure(q);
;
; THE SILENT MISCOMPILE THE MEASURED-RAIL RETRY INTRODUCED. The retry borrows the
; measured `q` and reverses the dead chain of `t`. `t` is RECORDED (the printf
; tape) and carries an Ry, so step 3b freezes it: no `cqrt_free`, but every
; adjoint is still emitted — `ry(t,-.5); xor_i1_hl_unc(t, q, 1)` — on the premise
; that "an adjoint on a rail we then leak is harmless, a local unitary". That
; premise holds only when every register the adjoint reads is dead or reversed by
; the same plan. Here the `_unc` reads the BORROWED `q`, which stays live and takes
; `ry(q, .3)` after the reversal (clause (d) admits a gate after `At` by design).
; After the record `t` holds a definite |w> per branch; the adjoints leave
; X^{q⊕1} Ry(-.5)|w>, so q's coherence is multiplied by ∓sin(.5) instead of 1, and
; after Ry(.3) P(q=1) = 0.037181 (source) vs 0.045584 (emitted) — `opt` exit 0,
; stage 2b clean (hand arithmetic, the reviewer's p1_sim.py).
;
; THE FENCE: the retry now refuses when a rail the reduced plan reverse-plays but
; does NOT free (frozen, a QRAM array, or not a scanned rail) has a gate that reads
; a borrowed register or a rail whose label depends on one
; (`keptRailAdjointReadsBorrowed`), and the module keeps today's decline verbatim.
; Not a physics wall — leaving `t` alone (no adjoint at all) is the faithful
; stream; the spine has no "leak without adjoint" plan for a rail in a reversed
; DAG yet, so this stays loud rather than guessed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @printf(ptr, ...)

define i32 @slice(i1 zeroext %0) {
  %2 = tail call zeroext i1 @cq_theta_i1(i1 zeroext %0, double 2.500000e-01)
  %3 = xor i1 %2, true
  %4 = tail call zeroext i1 @cq_theta_i1(i1 zeroext %3, double 5.000000e-01)
  %5 = zext i1 %4 to i32
  %6 = tail call i32 (ptr, ...) @printf(ptr @.str, i32 %5)
  %7 = tail call zeroext i1 @cq_theta_i1(i1 zeroext %2, double 3.000000e-01)
  %8 = tail call zeroext i1 @cq_measure_i1(i1 zeroext %7)
  %9 = zext i1 %8 to i32
  ret i32 %9
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
