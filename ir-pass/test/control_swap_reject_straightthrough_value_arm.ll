; control_swap_reject_straightthrough_value_arm.ll — DECLINE (a8c0 re-anchor
; boundary, the load-bearing safety gate): a folded straight-through where the arm
; is a VALUE arm, not a phase arm.
;
; `if (q != 0) q = q + 1; measure(q);`. The else edge folds to `0` exactly like the
; accepted phase case, BUT the arm changes q's VALUE (`add q, 1`), so
; `phi [q+1, 0]` is a genuine many-to-one value mux (q ∈ {0} → 0, q ≠ 0 → q+1),
; NOT a phase in place. The re-anchor requires the arm's phase-spine `Base` to BE
; the compare's handle `q`; here the arm bottoms at the `add` (a value-changing
; op), so `Base != q` and `straightThroughConstFoldHandle` returns null. The region
; falls through to the value path and declines loudly — the re-anchor never turns a
; value collapse into a (wrong) phase arm (Prime Directive; Rule 7).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_rz
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 0
  br i1 %c, label %merge, label %arm
arm:
  %q1 = add i32 %q, 1                     ; value-changing arm (not a phase)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ 0, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
