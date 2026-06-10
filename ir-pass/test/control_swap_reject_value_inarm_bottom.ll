; control_swap_reject_value_inarm_bottom.ll — a value chain bottoming at an
; IN-ARM non-link (a cast under the chain) is a broken lineage, not a routable
; arm (4.2 WI-3; Rule-12 pin for the in-arm-bottoming edge of the value
; classifier).
;
; `if (q > 5) { p32 = (int)p16 + 3; }` — the chain's add link threads an
; in-arm `sext` (a cast is never a chain link: §0 criterion 2 — no
; cq_phi/cq_theta/compare/cast link). The chain must bottom OUTSIDE the arm at
; the live routed register in the pred; an in-arm bottoming value cannot be
; the routed slot (it does not even exist before the branch).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: value-arm swap-route
declare i32 @cq_theta_si32(i32, double)
declare i16 @cq_theta_si16(i16, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i16 %v0, i32 %w0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p16 = call i16 @cq_theta_si16(i16 %v0, double 2.500000e-01)
  %p32 = call i32 @cq_theta_si32(i32 %w0, double 1.250000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %pc = sext i16 %p16 to i32   ; in-arm CAST under the chain — not a link
  %p1 = add i32 %pc, 3
  br label %merge
merge:
  %pm = phi i32 [ %p1, %arm ], [ %p32, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
