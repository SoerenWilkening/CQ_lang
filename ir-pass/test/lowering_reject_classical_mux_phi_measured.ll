; lowering_reject_classical_mux_phi_measured.ll — DECLINE: classical-branch
; merge phi mixing tainted data with a literal, base handle ALSO measured
; (test_C_libtooling-wi5, the phi sibling of the select headline).
;
; `%p = phi i32 [ %q, %a ], [ 5, %entry ]` joins a CLASSICAL branch: its result
; is handle-or-literal-5 at runtime. Pre-guard this was a confirmed verify-clean
; SILENT miscompile (exit 0; the phi survives on the i32 runtime handle and
; `cqrt_measure_i32(%p)` measures "handle-or-5"): the base %q is measured, so
; `computeFreePoint` returns `Measured` BEFORE the phi could reach its
; FirstUnrecognized reject — and the phi is LIVE, so it is not the benign
; dead live-range merge either.
;
; BOUNDARY (what stays accepted/owned elsewhere):
;   * a DEAD (use_empty) merge phi over the SAME handle is FreePoint's benign
;     live-range domain — pinned ACCEPT: lowering_uncompute_branch_botharms.ll;
;   * a merge phi of a TAINTED-condition region is ControlDetect's /
;     SwapRouteEmit's — pinned: control_swap_diamond.ll, control_swap_ifelse.ll
;     (accepted, phi erased) and control_swap_reject_clobber.ll (declined with
;     its own message BEFORE this guard runs — opt exits at the first DS_Error).
;
; Guard: TaintPropagation::declineClassicalMuxes (post-control, pre-rotation,
; both entry points). It OWNS the exact `Msg` string; this CHECK mirrors it
; character-for-character (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %c, label %a, label %merge            ; CLASSICAL condition
a:
  br label %merge
merge:
  %p = phi i32 [ %q, %a ], [ 5, %entry ]      ; live mux: handle-or-literal-5
  %m0 = call i32 @cq_measure_si32(i32 %q)     ; base measured -> FreePoint net bypassed
  %m1 = call i32 @cq_measure_si32(i32 %p)     ; "handle-or-5" measured as a handle
  %r = add i32 %m0, %m1
  ret i32 %r
}

; CHECK: error{{.*}}cq taint escape: tainted value muxed by a classical-condition phi
