; control_swap_eqfold_classical_between.ll — ACCEPT.
;
; ⚠⚠ THIS FIXTURE NO LONGER PINS THE EQUALITY-FOLD RE-ANCHOR. Its old header
; described `tryEqFoldArm`'s D1-D8 ladder and the 4.5 §5 const-fold re-anchor
; scrub, and every word of that is now FALSE OF THIS FILE. The header is rewritten
; rather than left standing, because a green fixture whose header claims a
; property it does not exercise is the FALSE-GREEN class this whole migration
; exists to stop -- and this one was found by the Rule-13 flips lens
; ($SP/progress/review_flips.md, FINDING F1), not by the suite.
;
; WHY THE PROPERTY IS GONE. `EqFoldArm.cpp`'s D2 requires the phase spine to
; bottom at a `ConstantInt`, and the ONLY construct that ever produced one was
; `cq_phi_<sfx>(i32 k, theta)` -- `-O1` substituting the value the equality edge
; pins into the gate's ARG-0. `void cq_phi(double)` HAS NO ARG-0, so no spine can
; bottom at a constant and D2 can never fire. Measured four ways by the lens:
;   1. the retired `cq_phi_<sfx>` spelling declines BEFORE analysis (reserved
;      name, round-1 F-L6-1), and `opt` writes NO module at all -- so nothing that
;      path computes can become an accepted lowering;
;   2. the `cq_theta_si32(i32 k, theta)` spelling is intercepted EARLIER, by drbq
;      Inc-4's F1 (`state prep merged with a quantum register`), ON BOTH BINARIES
;      -- so it never was an eq-fold customer;
;   3. the last conceivable route -- a `ConstantInt` MERGE INCOMING with
;      register-free phases in the arm -- declines `control flow` in BOTH
;      polarities, because D6's pure-spine walk is itself built on `isPhiCall`;
;   4. the wrong unitary D8 fenced CANNOT BE EMITTED: `rzRtFn(` has 4 call sites,
;      all `"i1"`, and `controlledRotationFn(` has 2, both `RotStem::Ry`. No
;      minter of a controlled Rz remains anywhere in the pass.
; `tryEqFoldArm` D1-D8 and `straightThroughConstFoldHandle` are therefore
; STRUCTURALLY UNREACHABLE and are listed in MIGRATION_REPORT.md §13.3a as
; freeze-time dead-code candidates. They are NOT deleted in this increment.
;
; WHAT THIS FILE PINS NOW (measured on `build/ir-pass/cq-opt`; the CHECK lines
; below were DERIVED from that output):
;   TWO SEQUENTIAL tainted regions separated by a CLASSICAL diamond that is left
;   completely untouched. Region 1's quadruple is emitted in `entry`; the
;   classical `br i1 %cz` / `cbody` / `cjoin` CFG SURVIVES verbatim; region 2's
;   mint, gate, strip and free are emitted in `cjoin`, on the SAME rail `%h`.
;   That is the surviving property and it is worth keeping: detection keys
;   strictly on condition TAINT, so a classical branch between two quantum
;   regions must neither be flattened nor break the second region's anchoring.
;   Unitary `e^{i(0.2·[q==5] + 0.3·[q==6])}`.
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
  ; (this comment used to say `-O1` const-folds the arm's `q` to the literal 5,
  ; "the eq-fold shape whose whole point is the re-anchor". A register-free
  ; `cq_phi` has no arg-0 to fold, so there is nothing to re-anchor — see the
  ; header.)
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
; NOROUTE-NOT: call void @cqrt_rz_{{[a-z0-9]+}}_controlled(
;   ^ ⚠ NARROW TWIN of the blanket `_controlled` above, and it exists because the blanket one is DROPPED from any fixture that legitimately emits a controlled Ry or a controlled copy — and dropping it took the only catch for a controlled Rz with it. MEASURED: 4 of the 104 re-derived accepts were BLIND to an injected `cqrt_rz_i32_controlled` — the exact pre-Inc-1 TENSORED gate this increment removes — until this line was added. The width complement above cannot cover it either: it requires `(` immediately after the width, and `cqrt_rz_i32_controlled(` has `_controlled` in between.
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
