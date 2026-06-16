; control_swap_defer_switch.ll — DECLINE: an IDENTITY (no-content) tainted switch.
;
; 4.5 WI-1 repurpose: the merge `phi` carries the scrutinee `%q` unchanged on every
; edge (`[%q,…],[%q,…],[%q,…]`) — the arms are empty (`br label %merge`), so there
; is NO content phase/value/data arm. `classifySwitchRegion`'s G1/G5 finds no
; content arm and declines generic `control flow` (string captured from a real -O1
; run, Rule 12), NOT the would-be-accept transitional `switch` string. A no-op
; tainted switch is nothing to lower.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %q, %a0 ], [ %q, %a1 ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
