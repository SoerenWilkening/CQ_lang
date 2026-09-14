; control_phase_kickback_reject_mergephi_three_incoming.ll — DECLINE (bd `3qps`,
; Track P). THE DISCRIMINATOR SURVIVES: a φ the grammar does NOT admit still takes
; `branch phase on a bare i1 condition`, GREEN ON BOTH BINARIES.
;
; THE SHAPE: a THREE-incoming `i1` φ, which `isCondRailPhiShape` refuses (2
; incomings exactly — the shape a single diamond's `Merge` has). `collectCondTree`
; then finds no leaf of any kind, and the `IsCondTree` split correctly reports
; "not a condition TREE" and keeps the bare-`i1` string.
;
; ⚠ WHY THIS FILE MATTERS MORE THAN IT LOOKS. bd `3qps` MOVED that string for one
; shape (a claimed prep's φ is now an ACCEPT), and a string that has stopped
; discriminating is worse than no string at all: every `i1` residual would read as
; "a capability we have not built" with no fixture able to tell which. This file
; plus `control_phase_kickback_rail_*`'s siblings for `trunc`/`zext`/argument
; conditions (bd `r903`) and the loop-carried header φ (bd `boi6`) are what keep
; the partition honest.
; ⚠ Rule 12(b): a `DS_Error` decline writes 0 bytes to stdout, so every IR-text
; negative a decline fixture could carry is VACUOUS. What pins "no silent
; lowering" is the `not` inversion on the RUN line (exit non-zero) plus the
; string, mirrored character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i1 @example(i32 %n) {
entry:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  %c1 = icmp sgt i32 %n, 3
  br i1 %c1, label %a1, label %a2
a1:
  br label %merge
a2:
  %c2 = icmp sgt i32 %n, 9
  br i1 %c2, label %a3, label %merge
a3:
  br label %merge
merge:
  %b1 = phi i1 [ %t, %a1 ], [ false, %a2 ], [ true, %a3 ]
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %t)
  ret i1 %m
}

; CHECK: cq controlled lowering: branch phase on a bare i1 condition under quantum control
