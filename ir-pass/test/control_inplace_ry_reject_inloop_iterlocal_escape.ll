; control_inplace_ry_reject_inloop_iterlocal_escape.ll — DECLINE, and it is the
; ONE clause of bd `test_C_libtooling-wx8g` that is a UNITARY fence rather than
; bookkeeping: R7-loop CLAUSE (c3), "no tainted value defined inside `L` may have
; a user outside `L`".
;
; The rotated register is ITERATION-LOCAL (a fresh `cq_theta(%u1, .25)` per trip,
; so clause (c2) is satisfied) but it is read AFTER the loop — `%m =
; cq_measure(%rm)` sits in `exit`. That escape is exactly what makes
; `LoopLowering::markIfRailLocal` refuse the iteration-local marking at its
; "an iteration-local temp escaping the loop" clause, and the whole-DAG spine
; then never places the body's `_unc`s.
;
; ⚠ MEASURED, NOT ARGUED (2026-09-14, subject build with clause (c3) ABSENT and
; nothing else changed). This module against its HAND-UNROLLED TWIN at two trips
; (`$SES/trackW/probes/ir/il_escape_{rolled,flat}.ll`):
;
;     rolled  19 trace lines   lshr; and; icmp; cry; icmp_unc; free(flag)   per trip
;     flat    27 trace lines   ... PLUS  and_unc; free; lshr_unc; free      per trip
;
; TWO entangled which-path records of `%q`'s bits leak per activation in the
; rolled form. `opt` exit 0 on both, `opt -verify` clean on both, and
; `free_pairing_check.py` reports `0 violation(s)` on both because it counts
; `cqrt_alloc` sites and a TEMPLATE-minted rail has none (its own header says so).
; ROLLED != UNROLLED — a DIFFERENT UNITARY, the 8h7d.5 F-4 / C-1 signature.
;
; THE CONTROL THAT MAKES IT A DISCRIMINATOR is the same module with the
; measurement moved INSIDE the body: that one is byte-identical to its twin and
; is the shipped accept `control_inplace_ry_inloop_iterlocal_base.ll`. One edge
; of difference, two dispositions.
;
; The condition is DERIVED (`(q >> i) & 1`) on purpose: a bare compare's flag is
; minted, stripped and freed by `emitInPlaceRotationRegion` itself, so it cannot
; witness a missing SPINE discharge. Only a derived chain can.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout, so an IR-text `CHECK-NOT`
; here would be VACUOUS; what pins "no silent lowering" is the `not` INVERSION on
; the RUN line plus the string below, mirrored character-for-character.
; CHECK: error{{.*}}control flow inside a loop body under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %rl = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %sh = lshr i32 %q, %i
  %an = and i32 %sh, 1
  %c = icmp eq i32 %an, 1
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %rl, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %rl, %loop ]
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 1
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
