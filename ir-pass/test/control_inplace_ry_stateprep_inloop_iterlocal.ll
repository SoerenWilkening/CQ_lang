; control_inplace_ry_stateprep_inloop_iterlocal.ll — ACCEPT (bd
; `test_C_libtooling-wx8g`, R7-loop CLAUSE (c) on the CONTROLLED STATE PREP
; branch): the ITERATION-LOCAL spelling — `int r = 0;` INSIDE the body, so the
; merge phi's Pred incoming IS the `Constant` and F1 is satisfied — lowered
; ROLLED, one fresh `|SEED>` per activation.
;
;     for (int i = 0; i < 3; i++) { int r = 0; if (q == 5) { r = 0; cq_theta(&r, .9); } … }
;                                                          // probe `p18c`, from C
;
; ⚠ THIS FILE SHIPPED AS A DECLINE UNTIL 2026-09-14 and is REWRITTEN IN FULL.
; Its old header is worth reading against this one, because its diagnosis was
; EXACTLY RIGHT and its conclusion was wrong:
;
;   "R4/R6's closures are SKIPPED for a state prep (§14.5's trap …), so
;    `BaseWireOrder` is EMPTY, so clause (b) — 'some member of the base's rail
;    closure is a PHINode in `L`'s header' — finds no member, `Rollable` stays
;    false, and the region declines."
;
; TRUE, and clause (c) is what asks the question that class CAN answer: for a
; state prep the rail is minted by the HOISTED `T` ITSELF, so clause (c2) is
; asked with `MintSeed = T` rather than with `RotBase` (which is the seed
; `Constant`). `railChainRootMint(T, …)` returns `T` — a classical-arg-0
; `cq_theta` in `GateCalls` — and `L->contains(T->getParent())` holds.
;
;   "⚠ AND THE DEFERRED ITEM … `railPhiRootMint`'s mint vocabulary is EXACTLY
;    what a hoisted state-prep `T` is. The obstruction is POSITIONAL: the hoisted
;    `T` sits INSIDE the loop body, so `DT.dominates(Mint, L->getHeader())` fails
;    and the rail is re-minted every trip. A rolled in-loop state prep would need
;    the alloc hoisted OUT of the loop — a real transformation with its own
;    per-activation reset question (trip 2's `f=0` component would read a rail
;    trip 1 may have rotated) — i.e. a different capability, not a fence
;    relaxation."
;
; THE POSITIONAL READING IS CORRECT AND THE CONCLUSION INVERTS IT. The reset
; question is a property of HOISTING, which clause (c) does not do and must not:
; "the rail is re-minted every trip" is not the obstruction, it IS THE PROOF.
; Leaving `cqrt_alloc_i32(0)` INSIDE the body makes every trip's `f=0` component
; read a FRESH |0>, which is precisely what the hand-unrolled twin's second block
; does. `railPhiRootMint`'s `dominates` test is not a general requirement on rail
; mints — it is clause (b')'s half of a dichotomy, and clause (c2) is the other
; half, over the one shared body `railChainRootMint`.
;
; ITS SIBLING `control_inplace_ry_reject_stateprep_inloop_carried.ll` — the
; LOOP-CARRIED spelling (`int r = 0;` OUTSIDE the loop) — IS UNCHANGED AND STILL
; DECLINES, at F1, with `state prep merged with a quantum register`. It never
; reaches R7 at all: on trip 2 the straight-through value is whatever trip 1 left
; in `r`, which is not |SEED> and is a no-cloning mux (Rule 8). "In-loop state
; prep" sounds like one thing and is two; now one of the two lowers.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: loop:
; CHECK: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; THE ALLOC IS INSIDE THE LOOP — the whole of clause (c2), and the answer to the
; old header's per-activation reset question:
; CHECK-NEXT: %h1 = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.0
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
; CHECK-NEXT: %m = call i32 @cqrt_measure_i32(i32 %h1)
; CHECK: br i1 %done, label %exit, label %loop
;
; ⚠ COUNTS IN THEIR OWN WHOLE-FILE PREFIX (Rule 12 hygiene (a)).
; COUNT-COUNT-2: call i32 @cqrt_alloc_i32(
; COUNT-NOT: call i32 @cqrt_alloc_i32(
; COUNT-COUNT-1: call void @cqrt_ry_i32_controlled(
; COUNT-NOT: call void @cqrt_ry_i32_controlled(
; COUNT-COUNT-1: call void @cqrt_free(
; COUNT-NOT: call void @cqrt_free(
;
; ⚠ A PURE NEGATIVE PREFIX. The prepped rail is FROZEN (never reverse-played,
; never freed — the only `cqrt_free` above is the FLAG's), and there is no route.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: @cq_theta_
;
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %t = phi i32 [ 0, %entry ], [ %tn, %merge ]
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %loop ]
  %mm = call i32 @cq_measure_si32(i32 %rm)
  %tn = add i32 %t, %mm
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %tn
}
