
; control_swap_reject_select_mergephi_three_incoming.ll — DECLINE (bd `boi6` D-B /
; Track M). GREEN ON BOTH BINARIES.
;
; The grammar's SHAPE fence: `isCondRailPhiShape` requires EXACTLY TWO incoming
; values, and this φ has three. The bound is not cosmetic — it is the same
; 2-incoming bound `soleMergePhi` (`ControlDetect`) imposes on a region's merge,
; so a φ with more edges can never be some `BranchRegion`'s `Merge` and rung 0
; could not prove it anyway. Refusing it in the GRAMMAR rather than in the ladder
; keeps the two bounds from drifting apart.
;
; ⚠ It is ALSO why the precedence-cycle backstop in `lowerControlRegions` stays
; unreachable: a cycle needs a merge φ with three or more predecessors, which
; region recovery refuses. Do not relax one bound without the other.

; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_theta_si32(i32, double)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare i32 @cq_measure_si32(i32)
define i32 @example(i1 %u0, i32 %g) {
entry:
  %b0 = call zeroext i1 @cq_theta_i1(i1 zeroext %u0, double 5.000000e-01)
  %cg = icmp sgt i32 %g, 7
  br i1 %cg, label %a, label %b
a:
  br label %merge
b:
  br i1 %b0, label %arm, label %merge
arm:
  %t = call zeroext i1 @cq_theta_i1(i1 zeroext false, double 5.000000e-01)
  br label %merge
merge:
  %p = phi i1 [ false, %a ], [ false, %b ], [ %t, %arm ]
  %sel = select i1 %p, i32 2, i32 5
  %m = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
