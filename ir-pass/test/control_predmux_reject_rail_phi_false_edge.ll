; control_predmux_reject_rail_phi_false_edge.ll — DECLINE, and ⚠ A P1 REGRESSION
; PIN FOR A COMPILER CRASH (bd fn1q increment 5a, Rule-13 round 1 F1).
;
; THE DEFECT. Increment 5a's E6 rail-φ admission (`isStructuralRailPhi`) is checked
; BEFORE the `dyn_cast<PHINode>` arm of `isSupportedCondTree`, so the φ never
; reaches `isConvertiblePhiCond` and is never RECORDED in `S->Recorded`.
; `convertPhis` therefore never converts it, and the moment the FALSE-EDGE LITERAL
; is demanded, `literal()` hands a raw `PHINode` to `buildNegation`, whose terminal
; `cast<BinaryOperator>(V)` is UNCHECKED. Measured on the defective binary:
; **exit 139, SIGSEGV**, with an LLVM crash dump, where the ORACLE declines loudly.
;
; ⚠ IT WAS REACHABLE FROM PLAIN C AT THE DOCUMENTED `-O1` FLOOR — the owner's own
; program with ONE OPERATOR CHANGED (`if (!b0[i] && Z > 1)`). A 32-cell polarity
; matrix crashed in 12 cells; the trigger is simply "the false-edge literal is
; demanded", which `clang -O1` makes true about HALF the time (Rule 9), and which
; increment 2 had already written at the crash site in those words.
;
; ⚠ RULE 1's "NO THIRD PATH" WAS VIOLATED, WHICH IS WHY THIS IS P1 AND NOT "JUST A
; CRASH": no `DiagnosticInfoUnsupported`, no `!dbg`, no source location — a decline
; became a crash report. And the bad cast is UNDEFINED BEHAVIOUR in the Release
; build every gate here runs, not a guaranteed trap: NULL is what was observed;
; nothing guarantees NULL rather than a garbage `Value*` that builds a WRONG
; PREDICATE. Precedent: CLAUDE.md §4f, where gate (P4)'s first spelling did exactly
; this and was filed P1.
;
; ⚠ THE ARM ON THE **FALSE** SUCCESSOR IS THE WHOLE FIXTURE. Swap the two labels of
; the `br i1 %rp` below and this module takes the other polarity, never demands the
; false-edge literal, and passes on the DEFECTIVE binary. Do not "normalise" it.
;
; THE FIX HAD TWO HALVES AND BOTH ARE REQUIRED: `buildNegation` takes a rail φ
; through the rail-LEAF route (`¬x = xor x, true`), and the ARM-SWAP FOLD at the
; flatten's select site accepts a rail-φ operand so the `xor` is removed before
; `collectCondTree` — which refuses an `xor` with a constant operand — ever sees
; it. Widening the arm alone would turn this into a claim-then-decline.
;
; NON-VACUITY, MEASURED BY MUTATION: with half 1 reverted and the tree rebuilt,
; this module exits **139**. With the fix, it declines. Both directions run.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; ⚠ `not` TREATS A SIGNAL AS A FAILURE TOO, so the RUN line alone does NOT separate
; a decline from a crash — the CHECK below is what does, because a crashing run
; prints an LLVM stack dump and never prints this string.
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: PLEASE submit a bug report
; CHECK-NOT: Stack dump

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %c = icmp sgt i32 %u, 0
  br i1 %c, label %prep, label %join
prep:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %join
join:
  %rp = phi i1 [ %b, %prep ], [ false, %entry ]
  ; ⚠ THE ARM IS ON THE **FALSE** SUCCESSOR — the polarity that demands the
  ; false-edge literal and therefore routes %rp through buildNegation.
  br i1 %rp, label %merge, label %arm
arm:
  br label %merge
merge:
  %a4 = phi i32 [ 2, %arm ], [ 5, %join ]
  %b5 = phi i32 [ 3, %arm ], [ 6, %join ]
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %mb = call i1 @cq_measure_i1(i1 %rp)
  %z = zext i1 %mb to i32
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
