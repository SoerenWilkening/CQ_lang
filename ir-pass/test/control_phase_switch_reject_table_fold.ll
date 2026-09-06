; control_phase_switch_reject_table_fold.ll — DECLINE. WHAT `clang -O1` ACTUALLY
; DOES TO A PLAIN-C PHASE SWITCH, pinned as a loud decline (prep-b OQ-4; bd
; test_C_libtooling-3qlq Inc 1 part B, finding F-0).
;
; This module is the VERBATIM `-O1` output of
;
;     switch (q) { case 0: cq_phi(.1); case 1: cq_phi(.2); case 2: cq_phi(.3); }
;
; and it is not a switch at all. A phase arm's ONLY possible content is
; `call void @cq_phi(double)`, so every arm is identical modulo one `double`
; operand — and SimplifyCFG turns that into a `@switch.table` of ANGLES plus a
; single call whose argument is a LOAD INDEXED BY THE TAINTED SCRUTINEE. Seven
; spellings were measured (dense/sparse case values, 1/2/3/4-gate arms, an empty
; arm, per-arm `volatile double` angles, an `if/else if` chain): `-O1` produces
; either this table or a CASCADE of blocks joined by `phi double` angles. NEITHER
; is the P5 shape, so P5 has NO plain-C customer and is exercised from hand IR —
; the same footing the if/else kickback arm has had since part A.
;
; ⚠ THE DECLINE HERE IS NOT P5's, AND THAT IS THE POINT OF PINNING IT. The
; tainted-index const-global read is refused UPSTREAM, by the 7.5 QRAM in-bounds
; proof, before any control classifier sees the branch. So the failure mode a
; reader should worry about — "the compiler quietly emitted a phase controlled by
; a table load it could not prove" — is closed twice over: the QRAM gate refuses
; the read, and if it ever admitted one the angle would then be TAINTED and Rule
; 3's angle fence would refuse it. Both are loud; `opt` exits non-zero.
;
; A recognizer for the table fold (per-entry eq-flags derived from a CONSTANT
; table) is a real capability — the table is `private unnamed_addr constant` and
; its entries are `ConstantFP`, so the N angles ARE statically known — and needs
; an owner ruling before anyone builds it. Filed, not done.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

@switch.table.main = private unnamed_addr constant [3 x double] [double 1.000000e-01, double 2.000000e-01, double 3.000000e-01], align 8

define i32 @example() {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01)
  %2 = icmp ult i32 %1, 3
  br i1 %2, label %3, label %7

3:                                                ; preds = %0
  %4 = zext nneg i32 %1 to i64
  %5 = getelementptr inbounds [3 x double], ptr @switch.table.main, i64 0, i64 %4
  %6 = load double, ptr %5, align 8
  tail call void @cq_phi(double noundef %6)
  br label %7

7:                                                ; preds = %0, %3
  %8 = tail call i32 @cq_measure_si32(i32 noundef %1)
  ret i32 %8
}

; CHECK: cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)
