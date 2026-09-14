; control_phase_kickback_reject_mergephi_nest.ll — DECLINE (bd `3qps` / bd
; `4aiu`, Track P). GREEN ON BOTH BINARIES, and that is the point: THE DEPTH-2
; PHASE NEST DID NOT GET THE φ, and the fence is that it never passes
; `AllowRailPhi`.
;
; This is the CLAUDE.md L2 row the widening owes ("when you WIDEN a set, ask what
; OTHER set was computed over the same closure") answered in the direction L3
; warns about — NOT always "widen it too". `collectCondTree`'s φ clause is gated
; by a per-caller flag, exactly as `AllowLogicalSelect` is, and exactly TWO
; callers pass it: `classifySelectRegion` and `classifyPhaseKickback`. The
; depth-2 nest (`classifyPhaseKickbackNest`), the Ry-stem angle select
; (`classifyAngleSelect`) and `Specialization`'s forward-only copy all see
; `false`, so their trees carry no φ, their `RailPhiLeaves` is EMPTY, and
; `CondTreeEmit`'s membership test hands them nothing they did not prove.
;
; Each of those is a filed follow-on with its own probe family, not an omission.
; ⚠ RETIREMENT TRIGGER: the increment that gives the NEST a φ leaf must flip this
; file and derive its stream from the pass output. Do not delete it.
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

define i1 @example(i1 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br i1 %b1, label %outer, label %done
outer:
  call void @cq_phi(double 9.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %inner, label %done
inner:
  call void @cq_phi(double 1.100000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %b1)
  ret i1 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
