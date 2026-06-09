; control_swap_defer_nested.ll — nested tainted control DEFERS to 4.3.
;
; `if (q > 5) { if (q > 3) { rz(q, a); } }`. The outer arm block (%mid) holds a
; second tainted-condition `br` — nested control. 4.1 handles only a single
; flat region (the block-lifetime / cross-region free hazard activates with
; nesting), so the outer region declines with the distinct "nested control flow"
; string, NOT the generic "control flow" one. Detection is by SSA-value identity
; before any mutation: recoverRegion sees the outer arm's terminator is itself a
; tainted conditional branch.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}nested control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %c2 = icmp sgt i32 %q, 3
  br i1 %c2, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
