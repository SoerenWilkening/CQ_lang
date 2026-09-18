; control_predmux_accept_residue_orphan_rail_compare_cond.ll — ACCEPT (bd
; test_C_libtooling-cfmv). ⚠ THE PRE-EXISTING HALF, AND THE FIX CLOSES IT TOO.
;
; This is …_residue_orphan_rail_survives.ll with the region conditioned on a
; COMPARE rather than on a bare rail — a shape the compiler has claimed since long
; before the rail leaf landed. It is the probe bd `cfmv` used to establish that the
; defect was PRE-EXISTING: on the pre-fix ORACLE this module ALSO lost the user's
; rail (0 `cqrt_alloc_i1`, 0 `cqrt_ry_i1`).
;
; ⚠ SO "PRE-EXISTING" WAS TRUE OF THE DEFECT AND FALSE OF ITS POPULATION — the
; standing formula — and the fix is at the ERASER, so it repairs the older
; population as well as the new one. Measured after: 2 mints, 3 rotations, same as
; its sibling. This fixture is what keeps that from silently regressing to "only
; the rail-leaf shape is guarded".
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: grep "call i32 @cqrt_alloc_i1(" %t.cqd0.ll | count 1
; RUN: grep "call void @cqrt_ry_i1(" %t.cqd0.ll | count 2
;
; CHECK: cqrt_alloc_i1
; CHECK: cqrt_ry_i1

declare i1 @cq_theta_i1(i1, double) memory(none) nounwind willreturn
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %dead = and i1 %rail, false
  %c = icmp sgt i32 %q, 1
  br i1 %c, label %arm, label %merge
arm:
  br label %merge
merge:
  %p1 = phi i1 [ false, %arm ], [ false, %entry ]
  %p2 = phi i1 [ %dead, %arm ], [ false, %entry ]
  %z1 = zext i1 %p1 to i32
  %z2 = zext i1 %p2 to i32
  %m  = call i32 @cq_measure_si32(i32 %q)
  %s  = add i32 %z1, %z2
  %s2 = add i32 %s, %m
  ret i32 %s2
}
