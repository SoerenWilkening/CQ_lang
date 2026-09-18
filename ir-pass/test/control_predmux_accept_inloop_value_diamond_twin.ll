; control_predmux_accept_inloop_value_diamond_twin.ll — the ALREADY-SHIPPED
; spelling, and the baseline its `br` sibling inherits clearance from (bd
; test_C_libtooling-fn1q increment 3, E2's in-loop admission).
;
; The identical program written with plain `select`s — what `clang -O1` produces
; whenever it DOES if-convert the arm. It contains no tainted `br` at all, so
; `PredMuxFlatten` is never consulted for it and it lowers on the shipped path:
; the 4.4 `SelectMergeEmit` controlled-XOR copy merge, with the two carried
; values promoted to loop-carried handles by bd `zujr`. IT ACCEPTS ON THE
; PRE-INCREMENT ORACLE — that is the entire point of the file, and it is what
; makes the `diff` in the sibling an inheritance rather than a tautology.
;
; ⚠ THAT CLAIM IS MEASURED, NOT ARGUED, AND NO RUN LINE IN THIS FILE CAN ASSERT
; IT. The increment's corpus A/B (oracle `a0e31e03…` against the subject, all
; 2136 fixtures, null control run first and clean) reports this module as NOT A
; MOVER: same exit code, same emitted stream on both binaries. It is recorded in
; .../session-2026-09-24-orchestrator/MEASUREMENT_INC3.md §7.
;
; ⚠ THE POLARITY IS DELIBERATE AND IS NOT A SIMPLIFICATION TARGET. The compare
; is `sle` and the select arms are (straight-through, arm) in that order,
; because that is the FALSE-EDGE literal `PredMuxFlatten` builds for the
; sibling's `br i1 %c, label %arm, label %latch` under its no-NOT invariant.
; Writing the "natural" `sgt` with swapped arms describes the same unitary but
; emits `icmp_sgt` flags where the sibling emits `icmp_sle`, and the byte-level
; `diff` then fails for a reason that has nothing to do with this increment
; (measured at the increment: exactly that, 10 differing lines).
;
; ⚠ DO NOT "SIMPLIFY" THIS FILE. Its value is that it is NOT new.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The loop is still ROLLED — the back edge survives the lowering.
; CHECK: br i1 %{{.*}}, label %exit, label %head

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %in, %latch ]
  %a = phi i32 [ 5, %entry ], [ %an, %latch ]
  %b = phi i32 [ 6, %entry ], [ %bn, %latch ]
  %c = icmp sle i32 %q, 5
  %a1 = add i32 %a, -3
  %b1 = add i32 %b, -4
  %an = select i1 %c, i32 %a, i32 %a1
  %bn = select i1 %c, i32 %b, i32 %b1
  br label %latch
latch:
  %in = add i32 %i, 1
  %d = icmp eq i32 %in, 3
  br i1 %d, label %exit, label %head
exit:
  %m1 = call i32 @cq_measure_si32(i32 %an)
  %m2 = call i32 @cq_measure_si32(i32 %bn)
  %s = add i32 %m1, %m2
  ret i32 %s
}
