; lowering_uncompute_leak_irreducible_dead_spine.ll — SAFE LEAK (Phase 5 §2.9,
; hardened by bd test_C_libtooling-4p7j's Rule-13 round, finding F1). The
; DEAD-TERMINAL spine's own irreducible-cycle hole — measured on `main`
; (c36934a), i.e. PRE-DATING the M-B interior partition entirely.
;
; THE DEFECT. `%h_op` is minted once in `entry`; `cqrt_addc_i32(%h_op, 7)` sits
; in `%A`, which executes K >= 1 times (`entry -> A -> B -> A -> …`). `%h_op` is
; a DEAD TERMINAL (its only user is a diagonal `cqrt_rz`), so the whole-DAG
; spine recovers {mul, addc, rz} and reverses them once in `%exit`:
;
;     cqrt_rz_i32(%h_op, -1.0); cqrt_addc_i32(%h_op, -7)      ; ONE adjoint …
;     cq_template_mul_i32_hl_unc(%h_op, %h, 5); cqrt_free(%h_op)
;     cqrt_ry_i32(%h, -0.5); cqrt_free(%h)                    ; … for K addcs
;
; `opt` rc=0 and verify-clean. For K > 1 the freed rail holds `5h + 7(K-1)`, so
; both `cqrt_free`s are resets of non-|0> rails — hidden measurements (Rule 6).
;
; ROOT CAUSE, and why it is the SAME bug as the interior one: the §2.9 acyclic
; backstop asks `LoopInfo::getLoopFor` per recovered gate, and `%A`/`%B` form an
; IRREDUCIBLE cycle (two entries, no dominating header) that `LoopInfo` does not
; see. bd c6yw / bd memory [free-placement-invariant-2026-08-11] recorded the
; blindness when the FINAL-`At` test was switched to `blockCanRepeat`; the
; per-gate test was left on `LoopInfo` and is the last consumer of the blind
; predicate. `blockCanRepeat` is a strict superset of the natural-loop test, so
; the NATURAL-loop behaviour (and the Phase-7.3 ITERATION-LOCAL exception, which
; is affirmative and re-confirmed per gate against `IterationLocalBlocks`) is
; unchanged — no committed golden moves.
;
; DISPOSITION: a SILENT LEAK, matching exactly what the backstop already does
; for a natural-loop-resident gate (`return; // safe leak`). The whole DAG is
; left allocated — Rule 6's fallback — and if a later non-diagonal gate stands
; over one of these records, the LATE M-A guard owns the loud decline.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEANY < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare void @cqrt_addc_i32(i32, i32)

define void @dead_spine_irreducible(i32 %u0, i1 %c0, i1 %c1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = mul i32 %q, 5
  br i1 %c0, label %A, label %B
A:                                        ; preds = %entry, %B — irreducible
  call void @cqrt_addc_i32(i32 %r, i32 7)
  br i1 %c1, label %B, label %exit
B:                                        ; preds = %entry, %A
  br label %A
exit:
  %k = call i32 @cq_phi_si32(i32 %r, double 1.000000e+00)
  ret void
}

; The forward stream lowers normally — the rotation is emitted, nothing else is:
; CHECK-LABEL: define void @dead_spine_irreducible(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK:      call void @cqrt_addc_i32(i32 %[[OP]], i32 7)
; CHECK:      call void @cqrt_rz_i32(i32 %[[OP]], double 1.000000e+00)
; CHECK-NEXT: ret void

; NOTHING is reversed and NOTHING is freed anywhere in the module (one anchor,
; one prefix ⇒ window anchor -> EOF; bd memory
; [filecheck-check-not-window-trap], and `tools/fixture_guard_liveness.py`
; proves the guard executes):
; NOFREEANY:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREEANY-NOT: call void @cqrt_free(
; NOFREEANY-NOT: _unc(
; NOFREEANY-NOT: double -1.000000e+00
; NOFREEANY-NOT: double -5.000000e-01
; NOFREEANY-NOT: i32 -7
