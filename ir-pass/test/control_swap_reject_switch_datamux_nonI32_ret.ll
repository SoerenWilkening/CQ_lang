; control_swap_reject_switch_datamux_nonI32_ret.ll — NON-i32 RETURN reject (8mld,
; the switch sibling of control_classical_call_arm_reject_nonI32_ret.ll): a
; tainted-scrutinee `switch` whose all-`ConstantInt` merge phi is `i64` and is
; consumed by a DIRECT `ret i64`. The data-mux emitter preloads + XOR-delta-copies
; into a FRESH `%out` handle and RAUWs the merge phi to it; `cqrt_alloc_<W>` is i32
; at every width (Rule 15), so accepting leaves `ret i64 <i32 handle>` — a BROKEN
; MODULE the verifier aborts on (`report_fatal_error`), NOT a Rule-1 decline. A
; crash on well-formed valid input (opt -verify exit 0) violates Rule 1.
;
; The data-mux merge is UNTAINTED (all-ConstantInt incomings), so the pre-detection
; `declineTaintEscapes` non-i32-return net never sees it. G4's `widthHasReversibleCopy`
; admits i8..i64 (correct for the width-independent MEASURE sink, which re-types),
; but a non-i32 `ret` is NOT width-independent. `proveSwitchDataMux` G6 now gates
; the `ret` escape to i32; i64-MEASURE data-muxes stay accepted (the surgical fix).
; NEVER lowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
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
