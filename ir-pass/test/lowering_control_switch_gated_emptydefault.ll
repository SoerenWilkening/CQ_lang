; lowering_control_switch_gated_emptydefault.ll — Phase 4.1 WP18 (PRD §8.5,
; epic `-aht.3`), negative (first-cut BOUNDARY). When the `default` arm is empty
; (`default: break;`), `clang -O1` routes the default edge STRAIGHT to the merge
; (no distinct default block), so the merge gains a predecessor that is the
; switch block itself. The WP18 first cut requires every arm — including the
; default — to be a DISTINCT single-pred block reconverging on the merge, so it
; DECLINES this shape; the WP12 tainted-`switch` guard then diagnoses it (no
; silent miscompile). Lowering the default-direct-to-merge shape is a follow-on.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}switch under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  switch i32 %q, label %merge [
    i32 1, label %c1
    i32 2, label %c2
  ]
c1:
  %v1 = call i32 @cq_phi_si32(i32 %v, double 1.000000e-01)
  br label %merge
c2:
  %v2 = call i32 @cq_phi_si32(i32 %v, double 2.000000e-01)
  br label %merge
merge:
  %vm = phi i32 [ %v, %entry ], [ %v1, %c1 ], [ %v2, %c2 ]
  %m = call i32 @cq_measure_si32(i32 %vm)
  ret i32 %m
}
