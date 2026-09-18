; control_predmux_accept_rail_leaf_cond.ll — ACCEPT (bd test_C_libtooling-fn1q
; increment 2; closes bd test_C_libtooling-s9xi).
;
; A tainted-condition diamond whose merge carries FOUR phi and whose condition is
; a BARE RAIL — the user's own `_Bool` register, a `cq_theta_i1` result, with no
; compare anywhere. This is `wide4.c` (the s9xi exhibit) at the IR level:
;
;     int A=5,B=6,C=7,D=8; bool b = cq_theta(b, 0.5);
;     if (b) { A -= 3; B -= 4; C -= 5; D -= 6; }
;
; `clang -O1` const-folds all four arms to 2 and then REFUSES to if-convert,
; because four phi exceeds its speculation budget — so the `br` survives. Its
; TWO-variable sibling (`wide2.c`) is if-converted to plain `select`s and has
; lowered since Phase 4.4. Same program, two spellings, and `-O1` picks.
;
; WHY IT DECLINED. `PredMuxFlatten` is the stage that owns a multi-phi tainted
; merge — its W witness is literally `NumMergePhis >= 2` — but E6 asked
; `isSupportedCondTree`, whose grammar is compare leaves and and/or/xor/select
; nodes over them. A bare rail is none of those, so the region left at
; `E6-condtree`; `MergePhiPeel` then peeled all four phi (they are all
; pred-available constants), leaving an EMPTY tainted diamond with ZERO phi that
; `recoverRegion` labels `OffPattern`, and the catch-all declined `control flow`.
;
; ⚠ THE RAIL LEAF IS NOT A NEW CONCEPT AND THIS FIXTURE MUST NOT READ AS ONE.
; `isCondRailLeaf` (SelectClassify.h) is the ONE spelling of "the `_Bool`
; register IS the condition", shipped since bd 3qlq.4, and `collectCondTree`
; already carries such a leaf into the 4.4 select substrate as a `RailLeaves`
; entry that mints NO flag — the register is read only as a CONTROL. E6 was the
; last consumer that had not been told. Rule 14: this increment CALLS that
; predicate, it does not re-derive it.
;
; ⚠ AND IT IS NOT A ONE-LINE WIDENING. `buildNegation` ends in an UNCHECKED
; `cast<BinaryOperator>(V)` — an assert in +Asserts and a bad cast in the Release
; build every gate here runs. The false-edge predicate of a rail-conditioned
; region goes straight through it, so the leaf arm (`xor %rail, true`) is part of
; the same change. `control_predmux_accept_rail_leaf_negation.ll` is the fixture
; that pins it and it is the one to read first.
;
; THE EMITTED STREAM IS THE SHIPPED IDIOM, FOUR TIMES: per phi, a fresh `|0>`
; ancilla, a CNOT copy of the rail onto it, a fresh `|0>` target, two
; X-bracketed `cqrt_copy_i32_controlled`, the CNOT restored and the ancilla freed
; at a proven |0>. The rail itself is never `cqrt_x`-bracketed and never freed
; (Rule 6) — it is measured by the user.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NCOPY < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NFREE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RAIL < %t.cqd0.ll
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @probe() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br i1 %b, label %arm, label %merge
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

; The rail itself is the flag: allocated and rotated, then read ONLY as a control.
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_ry_i1(i32 %[[R]], double 5.000000e-01)
; One merge per phi, each a CNOT-copied ancilla + two X-bracketed controlled
; copies into a fresh |0> target, the CNOT restored and the ancilla freed at a
; proven |0> (x XOR x = 0). This is the FIRST of the four, in order.
; CHECK:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[R]], i32 %[[A]])
; CHECK:     %[[O:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[A]], i32 %{{.*}}, i32 %[[O]])
; CHECK:     call void @cqrt_x(i32 %[[A]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[A]], i32 %{{.*}}, i32 %[[O]])
; CHECK:     call void @cqrt_x(i32 %[[A]])
; CHECK:     call void @cqrt_cnot(i32 %[[R]], i32 %[[A]])
; CHECK:     call void @cqrt_free(i32 %[[A]])
; and the user's rail is measured, never freed:
; CHECK:     call i1 @cqrt_measure_i1(i32 %[[R]])

; FOUR merges, so eight controlled copies and four frees. ⚠ EACH COUNT GETS ITS
; OWN WHOLE-FILE PREFIX, and that is not style: two ordered counts in ONE prefix
; made this fixture fail its own subject on the first writing, because the second
; count only scans the text AFTER the last match of the first (CLAUDE.md Rule 12
; hygiene defect (a), in its positive form).
;
; ⚠ AND EACH COUNT IS CLOSED BY A WHOLE-FILE NEGATIVE, so it reads "EXACTLY 8" and
; not "at least 8". Rule-13 round 1 (P3-1) MEASURED the difference with an
; injection matrix: an injected NINTH `cqrt_copy_i32_controlled` was MISSED by all
; four prefixes, because an open-ended count is satisfied by the first 8 and
; nothing scans past the last positive match. The same matrix confirms the RAIL
; negatives are non-vacuous — an injected `cqrt_x` or `cqrt_free` ON THE USER'S
; RAIL is CAUGHT, and a dropped `cqrt_free` is caught by CHECK and NFREE.
; NCOPY-COUNT-8: call void @cqrt_copy_i32_controlled(
; NCOPY-NOT:     call void @cqrt_copy_i32_controlled(
; NFREE-COUNT-4: call void @cqrt_free(
; NFREE-NOT:     call void @cqrt_free(

; ⚠ THE NEGATIVE THAT MATTERS, and it is about RULE 6. The rail is the USER'S
; register: it is read only as a control, so it is never `cqrt_x`-bracketed (the
; brackets go on the ancilla, whose x-XOR-x return is what makes its free a
; proven-|0> one) and it is NEVER FREED — the user measures it. One anchor, then
; pure negatives to end of file; no count lives in this prefix.
; RAIL:     %[[R2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; RAIL-NOT: call void @cqrt_x(i32 %[[R2]])
; RAIL-NOT: call void @cqrt_free(i32 %[[R2]])
