; lowering_control_ne_i32.ll — false-successor gate arm (swapped branch). `clang`
; canonicalizes `if (u != 5) { u = gate(u); }` to `icmp eq; br i1 %eq, Merge,
; Arm` — the gate arm is the FALSE successor (taken when `u != 5`), and `clang`
; ALSO value-propagates the merge's straight-through (entry) edge to the known
; literal `5` (on that path `u == 5`). Two latent Phase-4-core bugs surfaced by
; the Phase 4.3 audit re-sweep:
;   (1) the merge φ `[gate, 5]` was RAUW'd to the Pred-edge value — here the
;       constant `5`, not the handle — emitting `cq_measure(5)` (crash);
;   (2) the control flag was the raw `icmp eq` (`u == 5`) with the gate fired on
;       flag=1, i.e. the NEGATION of the source `u != 5` (silent miscompile).
; Fix: dissolve a gate φ to its TAINTED incoming (the handle, on the arm edge
; here), and — for a false-successor arm (`region.ArmNegated`) — fire the gates
; on ¬flag via the self-inverse `cqrt_x` bracket. Net: rotate iff `u != 5`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; Flag = icmp eq; gate bracketed by cqrt_x(flag) so it fires on ¬(u==5)=(u!=5);
; the measure is on the HANDLE, never the propagated constant 5.
; CHECK:     call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     call void @cqrt_x(i32 %[[F:[a-zA-Z0-9_.]+]])
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[H]], double {{.*}})
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT: br i1
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %eq = icmp eq i32 %u, 5
  br i1 %eq, label %merge, label %arm        ; gate on the FALSE successor
arm:
  %ru = call i32 @cq_phi_si32(i32 %u, double 0.25)
  br label %merge
merge:
  %r = phi i32 [ %ru, %arm ], [ 5, %entry ]  ; entry edge value-propagated to 5
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
