; lowering_reject_classical_mux_select_alltainted_main.ll — DECLINE: an
; ALL-TAINTED classical-cond select (two DISTINCT handles), resident in `main`
; (test_C_libtooling-wi5). This one fixture pins the two residuals that ruled
; out both narrower fix candidates:
;
;   * ALL-TAINTED incomings (vs the issue's "mixed tainted+untainted" candidate
;     (b)): `select i1 %c, i32 %q1, i32 %q2` under a CLASSICAL condition is NOT
;     ControlDetect's (detection keys strictly on condition taint) and was
;     confirmed silent pre-guard — a mixed-only guard leaves it as a known
;     silent shape. A runtime-chosen alias of two registers has no static
;     uncompute/free story (which register the adjoint targets is
;     path-dependent), so it declines like the mixed form.
;   * `main` RESIDENCY (vs the FreePoint-reorder candidate (a)):
;     `computeFreePoint` returns `Escaped` for EVERY handle in `main` before
;     it ever walks users (process exit reclaims registers — pinned ACCEPT:
;     lowering_uncompute_escape_main.ll), so no reorder of its internal checks
;     can see this select. The authoritative owner must be pre-lowering.
;
; Guard: TaintPropagation::declineClassicalMuxes (post-control, pre-rotation,
; both entry points). It OWNS the exact `Msg` string; this CHECK mirrors it
; character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i1 %c) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 3, double 2.500000e-01)
  %q2 = call i32 @cq_theta_si32(i32 4, double 7.500000e-01)
  %s = select i1 %c, i32 %q1, i32 %q2         ; classical mux of two live registers
  %m = call i32 @cq_measure_si32(i32 %s)      ; measures "q1-or-q2" as one handle
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition select
