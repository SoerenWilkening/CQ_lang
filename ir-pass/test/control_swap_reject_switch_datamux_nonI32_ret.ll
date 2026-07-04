; control_swap_reject_switch_datamux_nonI32_ret.ll — NON-i32 RETURN reject (8mld,
; the switch sibling of control_classical_call_arm_reject_nonI32_ret.ll;
; re-routed by dugh): a tainted-scrutinee `switch` whose all-`ConstantInt` merge phi
; is `i64` and is consumed by a DIRECT `ret i64`. The data-mux emitter preloads +
; XOR-delta-copies into a FRESH `%out` handle and RAUWs the merge phi to it;
; `cqrt_alloc_<W>` is i32 at every width (Rule 15), so accepting leaves
; `ret i64 <i32 handle>` — a BROKEN MODULE the verifier aborts on, NOT a Rule-1
; decline. A crash on well-formed valid input (opt -verify exit 0) violates Rule 1.
;
; The data-mux merge is UNTAINTED (all-ConstantInt incomings). dugh (Phase 4×6)
; retired the `proveSwitchDataMux` G6 merge-out gate and instead RE-SEEDS a second
; propagation from the emitted `%out` (`repropagateControlMerges`); the now-tainted
; `ret` declines via the precise `kMsgNonI32Return`. The return check keys on the
; FUNCTION return type (i64), not the RAUW'd RV type (i32), so it catches the
; post-emit mismatch and `exit(1)`s before the verifier. i64-MEASURE data-muxes stay
; accepted (the sink re-types); the non-i32 raw quantum return is the (A1) limit that
; STAYS declined (feature jx32). NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}tainted value returned at non-i32 width
declare i32 @cq_theta_si32(i32, double)

define i64 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %c0
                                i32 1, label %c1 ]
c0:
  br label %merge
c1:
  br label %merge
merge:
  %y = phi i64 [ 10, %c0 ], [ 20, %c1 ], [ 5, %entry ]   ; UNTAINTED all-const i64 data-mux
  ret i64 %y                                             ; non-i32 ret of the RAUW'd i32 handle
}
