; control_swap_eqfold_classical_between.ll — ACCEPT, and THE CRASH REGRESSION PIN
; for `ControlRegion::RoutedBase` (round-1 Rule-13 review of bd
; test_C_libtooling-drbq Inc 1, lens L4 §1).
;
;     int q = cq_theta(3, .5);
;     if (q == 5) q = cq_phi(q, .2);   /* region 1: eq-fold phase diamond      */
;     if (cc)     g();                 /* a CLASSICAL branch between them      */
;     if (q == 6) q = cq_phi(q, .3);   /* region 2: eq-fold, base = region 1's */
;     return cq_measure(q);            /*           MERGE φ                    */
;
; THE DEFECT (measured from this exact C at `clang -O1`; a SIGSEGV under
; `DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib`, stack
; `emitRoute` → `IRBuilder::CreateCall` → `llvm::CallInst::Create`):
;
; `EqFoldArm` records `Region.RoutedBase` AT DETECTION, and for region 2 that is
; region 1's merge φ. `lowerControlRegions` emits region 1 first, which does
; `MergePhi->replaceAllUsesWith(q); MergePhi->eraseFromParent()`. A raw `Value *`
; is NOT a use, so the RAUW did not update it and the erase left it DANGLING;
; the phase emitter then dereferenced it to read `Q->getType()`.
;
; WHY THE bd hcrg PRE-FLIGHT DOES NOT CATCH IT, which is the lesson: that
; precedence graph reasons about BASIC BLOCK identities (`doomedBlocks`,
; `sequentialChainAlias`), and the classical `if (cc) g();` makes region 2's pred
; a THIRD block rather than region 1's merge block — so it correctly finds no
; block alias, creates no edge, and declines nothing. The dependency it does not
; model is a VALUE one. `RoutedBase` is now a `llvm::WeakTrackingVH`: it FOLLOWS
; the RAUW, so after region 1 collapses its merge φ the field names region 1's
; base — the correct routed handle. (Erased with no replacement is a separate,
; LOUD decline; see `ControlPlan.h`.)
;
; DELETE THE CLASSICAL BRANCH and the same two regions chain through the hcrg
; ordering and always lowered — that pair is the controlled experiment, and it is
; why this fixture keeps the middle block.
;
;
; 3qlq(prep_a2): the FileCheck assertions below were RE-DERIVED from this
; fixture's own output under the Inc-1 (register-free `void @cq_phi(double)`)
; binary.  The pre-Inc-1 pin — a `cqrt_rz_<W>` or `cqrt_rz_<W>_controlled` on
; the user's REGISTER — asserted the gate PRD §1 shows is the identity on the
; marked branch (`cqrt_rz_<W>` is TENSORED, so a routed W-bit Rz applies
; `(-1)^popcount(target)` and can never mark |0..0>).  The stream now pinned is
; the KICKBACK: the flag is minted into a |0> ancilla, the phase lands on the
; FLAG with an UNCONTROLLED `cqrt_rz_i1`, the ordinary compare `_unc` returns
; the flag to |0> on every branch, and the flag is freed.  The fixture's
; PURPOSE (its header above) is unchanged.
;
; ORIGINAL negatives REMOVED.  Each was MEASURED to fire on this fixture's
; own Inc-1 output, so keeping it would assert something false.  A `-NOT`
; that used to sit AFTER a positive of its prefix was WINDOWED to the text
; past that positive; re-measuring it whole-file is a strictly stronger
; question, and where the pattern is one of the counted ones the
; `-COUNT-n` + `-NOT` pair below pins `exactly n` — stronger than the
; window it replaces, not weaker.
;   * call i32 @cqrt_alloc_i32(
;
; 8 line(s) of prose that annotated the OLD CHECK block were removed with
; it — they described the pre-Inc-1 gate stream line by line.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=MDCNT < %t.cqd0.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @g()

define i32 @example(i32 %cc) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %t1 = icmp eq i32 %q, 5
  br i1 %t1, label %arm1, label %merge1
arm1:
  ; `clang -O1` const-folds the arm's `q` to the literal 5 — the eq-fold shape
  ; whose whole point is that the emitter must re-anchor on `RoutedBase`.
  call void @cq_phi(double 2.000000e-01)
  br label %merge1
merge1:
  %cz = icmp eq i32 %cc, 0
  br i1 %cz, label %cjoin, label %cbody
cbody:
  call void @g()
  br label %cjoin
cjoin:
  %t2 = icmp eq i32 %q, 6
  br i1 %t2, label %arm2, label %merge2
arm2:
  call void @cq_phi(double 3.000000e-01)
  br label %merge2
merge2:
  %r = call i32 @cq_measure_si32(i32 %q)
  ret i32 %r
}

; ===========================================================================
; THE EMITTED STREAM, IN ORDER — DERIVED from this fixture's own pass output
; (prep_a2, bd test_C_libtooling-3qlq Inc 1).  Every `%name` below is bound at
; its DEFINITION and referenced afterwards, so the chain asserts operand
; IDENTITY — the strip and the free name the SAME flag the mint produced
; (bd 8txa: the golden itself must witness the pairing).  Handle names are
; DERIVED, never typed (bd drbq Inc 4: 9 of 20 accepts named a %h1 the pass
; never emits).  Trailing `!cq.branchphase` metadata is stripped here because
; its NUMBER is LLVM's, not ours; its presence and count are MDCNT's job.
; CHECK: define i32 @example(i32 %cc) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[H_CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP]])
; CHECK-NEXT: %[[CZ:[a-zA-Z0-9_.]+]] = icmp eq i32 %cc, 0
; CHECK-NEXT: br i1 %[[CZ]], label %cjoin, label %cbody
; CHECK: cbody:                                            ; preds = %entry
; CHECK-NEXT: call void @g()
; CHECK-NEXT: br label %cjoin
; CHECK: cjoin:                                            ; preds = %cbody, %entry
; CHECK-NEXT: %[[H_CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 6)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[H_CMP1]], double 3.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[H_CMP1]], i32 %[[H]], i32 6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H_CMP1]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
; CHECK-NEXT: }

; ---------------------------------------------------------------------------
; WHOLE-FILE, PURE-NEGATIVE.  No positive directive may enter this prefix: a
; positive WINDOWS every negative after it, which is how an injected gate
; escaped 20 of 20 blocks in bd drbq Inc 3 (F-L6-1) and again in Inc 4.
; NOROUTE-NOT: cqrt_cswap
;   ^ the swap route is retired — no work rail, so no Fredkin
; NOROUTE-NOT: cqrt_copy
;   ^ method-B copy on a phase arm dephases the answer (Rule 7)
; NOROUTE-NOT: _controlled
;   ^ the kickback gate is UNCONTROLLED, on the flag ancilla
; NOROUTE-NOT: call void @cqrt_rz_{{(i8|i16|i32|i64|f16|f32|f64|f80)}}(
;   ^ the TENSORED per-register Rz is the defect this increment removes (PRD §1). ONE complement pattern, not an enumeration of six — the shipped ABI has NINE widths and f16/f80 were absent from every pre-Inc-1 NOROUTE block (round-1 findings F-L6-4/F-L8-1/F-L4-2). The trailing `(` is load-bearing: `cqrt_rz_i1` is a textual prefix of `cqrt_rz_i16`.
; NOROUTE-NOT: call void @cq_phi(
;   ^ a surviving phase call is lowered or deleted, never left for the linker
; NOROUTE-NOT: cq_phi_
;   ^ the register form is a RESERVED NAME and declines (round-1 F-L6-1)

; ---------------------------------------------------------------------------
; COUNTS — ONE PATTERN PER PREFIX.  Two counts in one prefix silently become
; an ORDER assertion, and a `-NOT` after a count in the same prefix is
; windowed to the text past the count.  `-COUNT-n` then `-NOT` of the SAME
; pattern is the only spelling that pins `exactly n`.
; ACNT-COUNT-2: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
;
; Every `cqrt_rz_i1` the pass emits must carry `!cq.branchphase`, or the
; whole-DAG spine reads it as a reclaimable in-place rotation and emits
; `cqrt_rz_i1(f, -theta)`, cancelling the user's phase EXACTLY (round-1
; F-L7-1, a CONFIRMED silent miscompile found by three lenses).  The two
; counts are asserted SEPARATELY and must agree: 2 and 2 here.
; MDCNT-COUNT-2: !cq.branchphase
; MDCNT-NOT:     !cq.branchphase
