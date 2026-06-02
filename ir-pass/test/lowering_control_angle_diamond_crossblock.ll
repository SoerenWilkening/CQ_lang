; lowering_control_angle_diamond_crossblock.ll — Family B2, NEGATIVE
; (test_C_libtooling-byx, adversarial-review regression lock, 2026-06-03). A
; diamond-form classical-angle merge `φ` whose consuming rotations live in TWO
; different blocks: %rE in the merge block and %rL in a CFG-later `tail` block.
;
; The controlled-rotation-by-difference reducer anchors the flag uncompute after
; the BLOCK-LAST consumer (anchorAfterLastConsumer scans ONE block). With a
; cross-block consumer, the uncompute would land in the merge block — BEFORE
; %rL's controlled rotation in `tail`, so %rL fires on an already-uncomputed flag
; (a verify-clean SILENT miscompile). Detection therefore requires all angle
; consumers to be co-located with the φ (usersAreAngleFeeds single-block check);
; a cross-block feed is NOT cleanly lowerable and is DIAGNOSED instead.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: cqrt_rz_i32_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
tail:
  %rL = call i32 @cq_phi_si32(i32 %u, double %ang)
  %m = call i32 @cq_measure_si32(i32 %rL)
  ret i32 %m
merge:
  %ang = phi double [ %a, %arm ], [ %b, %entry ]
  %rE = call i32 @cq_phi_si32(i32 %u, double %ang)
  br label %tail
}
