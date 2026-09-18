; control_predmux_accept_rail_leaf_negation.ll — ACCEPT, and THE FIXTURE THAT
; EXISTS TO CATCH ONE SPECIFIC RELEASE-BUILD ABORT (bd test_C_libtooling-fn1q
; increment 2).
;
; The POLARITY TWIN of control_predmux_accept_rail_leaf_cond.ll: the identical
; program with the region's arm on the FALSE successor. `clang -O1` picks that
; polarity about half the time (Rule 9 — `if (u != k)` canonicalizes to
; `icmp eq; br eq, Merge, Arm`), so this is not an exotic spelling.
;
; *** WHY IT IS NOT OPTIONAL. *** On this edge the arm's predicate is ¬rail, and
; it goes through `buildNegation`. That function's tail is
;     auto *BO = cast<BinaryOperator>(V);
; — an UNCHECKED cast: an assert in a `+Asserts` build and a bad cast in the
; RELEASE build every gate in this tree runs. A rail is a `CallInst`. So admitting
; the rail leaf at E6 WITHOUT the matching `buildNegation` arm turns this module
; from a clean loud decline into an ABORT, which is the bd `11qv` round-4 (P4)
; failure verbatim — `opt` exit 134 where the oracle declined at exit 1.
;
; ⚠ THE TWO `CHECK-NOT`s IN THE `RAIL` PREFIX ARE WHAT TELL A DECLINE FROM AN
; ABORT. Both are non-zero exits and neither writes the stream; only a positive
; assertion on the emitted gates distinguishes "we lowered it" from either.
;
; ⚠ AND THE SECOND HALF OF THE FIX IS THE ARM SWAP, NOT THE `xor`. ¬ of an
; OPAQUE `i1` has no leaf compare to invert, so `buildNegation` spells it
; `xor %rail, true` — and `collectCondTree` refuses that node because its child is
; an `i1` CONSTANT. Without the `select(¬c,T,F) == select(c,F,T)` fold at the
; flatten's select site the module is CLAIMED, FLATTENED and only THEN declined at
; `SelectClassify`, where the oracle declined at `E6-condtree` before touching
; anything — same verdict, worse owner, and exactly what this file's own bd
; `3c6m.67` self-operand lesson says not to ship.
;
; THE WITNESS IS THE EXCHANGE. This stream is its polarity twin's with the two
; `cqrt_alloc_i32` LITERALS SWAPPED and nothing else moved: the arm value (2) is
; copied under ¬flag and the fall-through value (5/6/7/8) under flag, which is
; the same unitary with the controls relabelled. Read the two fixtures together.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NCOPY < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NFREE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RAIL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOXOR < %t.cqd0.ll
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @probe() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %b, label %merge, label %arm
arm:
  br label %merge
merge:
  %a4 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %b5 = phi i32 [ 2, %arm ], [ 6, %entry ]
  %c6 = phi i32 [ 2, %arm ], [ 7, %entry ]
  %d7 = phi i32 [ 2, %arm ], [ 8, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %m3 = call i32 @cq_measure_si32(i32 %c6)
  %m4 = call i32 @cq_measure_si32(i32 %d7)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s1 = add i32 %m1, %m2
  %s2 = add i32 %s1, %m3
  %s3 = add i32 %s2, %m4
  %s4 = add i32 %s3, %z
  ret i32 %s4
}

; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_ry_i1(i32 %[[R]], double 5.000000e-01)
; THE EXCHANGE: the FALL-THROUGH value (5) is now the flag-controlled copy and the
; ARM value (2) the X-bracketed one — the twin has these two the other way round.
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[R]], i32 %[[A]])
; CHECK:     %[[O:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[S0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[A]], i32 %[[S0]], i32 %[[O]])
; CHECK:     call void @cqrt_x(i32 %[[A]])
; CHECK:     %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 2)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[A]], i32 %[[S1]], i32 %[[O]])
; CHECK:     call void @cqrt_x(i32 %[[A]])
; CHECK:     call void @cqrt_cnot(i32 %[[R]], i32 %[[A]])
; CHECK:     call void @cqrt_free(i32 %[[A]])
; CHECK:     call i1 @cqrt_measure_i1(i32 %[[R]])

; ⚠ EACH COUNT IS CLOSED BY A WHOLE-FILE NEGATIVE, so it reads "EXACTLY 8" and
; not "at least 8" — Rule-13 round 1 (P3-1) measured an injected NINTH controlled
; copy being MISSED by an open-ended count.
; NCOPY-COUNT-8: call void @cqrt_copy_i32_controlled(
; NCOPY-NOT:     call void @cqrt_copy_i32_controlled(
; NFREE-COUNT-4: call void @cqrt_free(
; NFREE-NOT:     call void @cqrt_free(

; The rail is the user's register: read only as a control, never bracketed, never
; freed (Rule 6).
; ⚠ THE ANCHOR IS THE RAIL'S OWN PREPARATION, NOT ITS ALLOCATION, and that is what
; lets the negatives be total. Everything after the user's `cqrt_ry_i1` must touch
; the rail ONLY as a control: no second rotation of either kind, no bracket, no
; free. Rule-13 round 2 (P3-1) MEASURED the earlier, weaker form — anchored at the
; alloc and negating only `cqrt_x`/`cqrt_free` — MISSING an injected
; `cqrt_ry_i1(%rail,…)` and an injected `cqrt_rz_i1(%rail,…)`, which is the Rule-7
; class ("nothing non-diagonal ever touches a user register under control") this
; prefix claims in prose to be pinning.
; RAIL:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; RAIL-NEXT: call void @cqrt_ry_i1(i32 %[[R2]], double 5.000000e-01)
; RAIL-NOT: call void @cqrt_ry_i1(i32 %[[R2]],
; RAIL-NOT: call void @cqrt_rz_i1(i32 %[[R2]],
; RAIL-NOT: call void @cqrt_x(i32 %[[R2]])
; RAIL-NOT: call void @cqrt_free(i32 %[[R2]])

; ⚠ THE ARM SWAP LEFT NOTHING BEHIND. `buildNegation`'s `xor %rail, true` is dead
; the moment the fold takes its operand, and `sweepDead` must collect it — an
; orphan i1 op would lower to a forward `cq_template_xor_i1` gate that is never
; uncomputed and never freed, and `free_pairing_check.py` is structurally blind to
; a TEMPLATE-minted rail (bd `1739`), so this negative is the only thing watching.
; A pure whole-file negative prefix: no count, no positive.
; NOXOR-NOT: cq_template_xor
