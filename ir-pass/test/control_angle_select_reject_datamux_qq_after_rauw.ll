; control_angle_select_reject_datamux_qq_after_rauw.ll — DECLINE (the EMITTER's
; step-0 S4 re-ask): a PRECEDING region's emission turns the angle select's
; compare from Q+C into Q+Q, and the plan no longer describes the IR.
;
; ROUND-1 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lens L4-1). The shape:
;
;   * the `switch i32 %q` with the all-`ConstantInt` merge phi `%rm` is a 4.5
;     SwitchDataMux region;
;   * `%c = icmp ne i32 %qx, %rm` has EXACTLY ONE tainted operand at DETECTION
;     (`%qx`), so S4 passes and an `AngleSelectRegion` is pushed;
;   * `lowerControlRegions` then emits the data-mux region FIRST, and
;     `SwitchDataMuxEmit` RAUWs `%rm` to its freshly minted TAINTED `%out` rail;
;   * by the time `emitAngleSelectRegion` runs, in the SAME loop, the compare is
;     Q+Q — a shape S4 explicitly refuses and this emitter has no mint for.
;
; WHAT WENT WRONG, AND IT IS AN ORDER FACT, NOT A SHAPE FACT: step 0 re-validated
; the plan by SSA IDENTITY (is `%ang` still the consumer's angle, is `%c` still
; its condition) but never re-asked the SEMANTIC half (how many operands of `%c`
; are tainted NOW). Steps 1 and 2 then emitted the `fsub` and the unconditional
; twin — and inserted the twin into `taint.Tainted` / `BirthOrder` / `ThetaCalls`
; — before step 3's `lowerCompareToFlag` returned null and bailed MID-STREAM, with
; the MISLABELLED message `no template for opcode 'icmp i1' in tainted context`.
; That is loud today only because `DS_Error` calls `exit(1)`, i.e. because the
; process dies before anyone can look at the half-emitted module. The header's
; claim that "every bail precedes the FIRST emitted instruction" was FALSE.
;
; THE FIX: step 0 now re-asks EXACTLY what S4 asked — exactly one tainted compare
; operand, `comparePredLowerable`, `compareFlagMintable` — and declines
; `control flow` (a plan/IR mismatch, the string every other step-0 bail uses)
; BEFORE `CreateFSub`. The null checks in steps 3 and 5 are KEPT and their
; comments corrected: they are unreachable by the step-0 lockstep re-ask, not
; "pre-emission".
;
; THE MESSAGE CHANGING IS THE RED-GREEN. Before the fix this file died with
; `no template for opcode 'icmp i1' in tainted context`; after it, with
; `control flow under quantum control`. The CONTROLS are lens L4's `Q3` (the same
; module with no select at all — still ACCEPTS, the data mux is unaffected) and
; `Q5` (a compare with a genuinely classical second operand — still ACCEPTS and
; emits the intended stream).
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: control flow under quantum control
; NEW: cq controlled lowering: control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; 3qlq: migrated from register cq_phi (angle select -> void call on the select (PRD P2))

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qx = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ]
  %c = icmp ne i32 %rm, %qx
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %qx)
  ret i32 %m
}
