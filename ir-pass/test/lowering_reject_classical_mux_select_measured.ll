; lowering_reject_classical_mux_select_measured.ll — DECLINE: classical-cond
; select over tainted data, base handle ALSO measured (test_C_libtooling-wi5,
; the issue headline shape).
;
; `%s = select i1 %c, i32 %q, i32 5` under a CLASSICAL condition is a
; runtime-chosen alias: handle-or-literal-5. Pre-guard this was a confirmed
; verify-clean SILENT miscompile (exit 0; the select survives lowering on the
; i32 runtime handle and `cqrt_measure_i32(%s)` measures "handle-or-5"). The
; Phase-5 FreePoint net never fires because `computeFreePoint` returns
; `Measured` for %q BEFORE its FirstUnrecognized check (FreePoint.cpp §2.5/§2.6
; ordering) — and that ordering is correct for its own pinned domain (the
; measure-sink exclusion), so the fix is an authoritative PRE-LOWERING owner,
; not a FreePoint reorder (a reorder still misses the `main`-resident and
; non-terminal-base variants; see the wi5 trail).
;
; Guard: TaintPropagation::declineClassicalMuxes, wired in BOTH pipeline entry
; points AFTER `lowerControlRegions` (ControlDetect keeps sole ownership of
; TAINTED-condition selects — pinned by control_swap_defer_select.ll — and
; accepted regions' merge phis are already erased) and BEFORE `lowerRotations`
; (pre-RAUW SSA identity). The guard OWNS the exact `Msg` string; this CHECK
; mirrors it character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = select i1 %c, i32 %q, i32 5            ; classical-cond mux over the handle
  %m0 = call i32 @cq_measure_si32(i32 %q)     ; base measured -> FreePoint net bypassed
  %m1 = call i32 @cq_measure_si32(i32 %s)     ; "handle-or-5" measured as a handle
  %r = add i32 %m0, %m1
  ret i32 %r
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition select
