; control_phase_kickback_reject_irreducible_loop.ll — DECLINE. A kickback region
; on an IRREDUCIBLE cycle (PRD §6.3 row 6; the d8jl half of the 8h7d.5 ruling that
; was deliberately KEPT).
;
; The in-loop accept (P6) is gated on `flatRegionRollableInLoop`, whose FIRST
; clause is `LI.getLoopFor(R.Pred)` non-null — a REDUCIBLE `LoopInfo` loop. An
; irreducible cycle (two entries, reachable from a `clang -O1` `goto` into a loop
; body) has no `LoopInfo` loop at all, so every downstream loop guard in the pass
; is structurally blind to it: `LoopLowering`'s Case-A rail analysis,
; `markIfIterationLocal`, `FreePoint`'s back-edge live-range reject. Accepting
; here would put a mint/gate/strip/free quadruple inside a cycle NOBODY checks.
;
; That reasoning is the reason the irreducible half of d8jl was kept when the
; reducible half was narrowed — bd `dugh` measured that the FLATTEN itself does
; not break, so this is not a flattener limitation; it is that every guard which
; would adjudicate the result is `LoopInfo`-gated.
;
; The predicate is asked from the kickback classifier's own pre-peel, but it is
; the SAME function `handleBranchRegion` asks for a flat region (declared in
; `ControlShape.h` for exactly that reason, Rule 14) — so this message is the flat
; path's, character for character.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i1 %g) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %g, label %A, label %B
A:
  %qa = phi i32 [ %q0, %entry ], [ %qb, %B ]
  %c = icmp eq i32 %qa, 5
  br i1 %c, label %arm, label %Amerge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %Amerge
Amerge:
  br label %B
B:
  %qb = phi i32 [ %q0, %entry ], [ %qa, %Amerge ]
  br i1 %g, label %A, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %qb)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow inside a loop body under quantum control
