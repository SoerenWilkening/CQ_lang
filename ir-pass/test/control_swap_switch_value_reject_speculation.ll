; control_swap_switch_value_reject_speculation.ll — DECLINE: the SWITCH twin of
; the Inc-2 speculation-totality fence (bd test_C_libtooling-3qlq Inc 2,
; retire-swap-route-PRD §10.3 lens 8).
;
; `switch(q){ case 0: p = p/n; case 1: p = p+2; }` with `n` a RUN-TIME CLASSICAL
; value. Since Inc 2 every case's chain is HOISTED into the switch block and runs
; unconditionally on the original %p, so a division by a divisor that is not
; proven non-zero is UB the source never wrote. Same predicate as the diamond
; fence (`isSafeToSpeculativelyExecute`), same string, asked in
; `emitSwitchValueRegion`. Without this file the switch half of the fence would
; be unpinned — the diamond fixture cannot reach it.
;
; ⚠ MEASURED: the pre-3qlq binary ACCEPTS this module (exit 0), emitting the
; `sdiv` template unconditionally on a |0> work rail. The narrowing is
; deliberate; over-declining is always safe.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %p0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %p0, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  %v0 = sdiv i32 %p, %n             ; run-time classical divisor — may be zero
  br label %merge
a1:
  %v1 = add i32 %p, 2
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v0, %a0 ], [ %v1, %a1 ]
  %m = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; CHECK: cq controlled lowering: value arm op that cannot run unconditionally under quantum control
; nothing is lowered: the decline is PRE-MUTATION (before the hoist)
; CHECK-NOT: cqrt_copy_i32_controlled
; CHECK-NOT: cqrt_cswap
