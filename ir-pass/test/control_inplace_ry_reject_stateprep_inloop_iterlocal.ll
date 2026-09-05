; control_inplace_ry_reject_stateprep_inloop_iterlocal.ll — DECLINE (R7-loop
; (b)): the ITERATION-LOCAL spelling — `int r = 0;` INSIDE the body, so the merge
; φ's Pred incoming IS the `Constant` and F1 is satisfied.
;
;     for (int i = 0; i < 3; i++) { int r = 0; if (q == 5) r = cq_theta(0, .9); … }
;                                                        // probe `p18c`, from C
;
; This is the real Inc-4-shaped in-loop program, and it dies at R7's loop half.
; The mechanism is worth stating because it is INDIRECT: R4/R6's closures are
; SKIPPED for a state prep (§14.5's trap — handing `railWireClosure` a
; module-uniqued `Constant` enumerates unrelated users), so `BaseWireOrder` is
; EMPTY, so clause (b) — "some member of the base's rail closure is a PHINode in
; `L`'s header" — finds no member, `Rollable` stays false, and the region
; declines `control flow inside a loop body`.
;
; ⚠ EVEN IF (b) WERE SATISFIED, (b') WOULD REFUSE IT: `railPhiRootMint` requires
; the header φ's EXTERNAL incoming to peel, through in-place steps, to a
; classical-arg-0 `cq_theta` MINT DOMINATING THE HEADER. Here that incoming is
; the `Constant` seed, `peelInPlaceBase` returns it unchanged, and the
; `dyn_cast<CallInst>` is null.
;
; ⚠ AND THE DEFERRED ITEM, RECORDED SO IT IS NOT MISTAKEN FOR A FENCE
; RELAXATION: `railPhiRootMint`'s mint vocabulary is EXACTLY "a classical-arg-0
; `cq_theta` in `GateCalls` dominating the header" — which is PRECISELY what a
; hoisted state-prep `T` is. The obstruction is POSITIONAL: the hoisted `T` sits
; INSIDE the loop body, so `DT.dominates(Mint, L->getHeader())` fails and the
; rail is re-minted every trip. A rolled in-loop state prep would need the alloc
; hoisted OUT of the loop — a real transformation with its own per-activation
; reset question (trip 2's `f=0` component would read a rail trip 1 may have
; rotated) — i.e. a different capability, not a fence relaxation.
; PRD §14.5 — R7's LOOP half is UNCHANGED by Inc 4 and refuses both in-loop
; spellings, FOR TWO DIFFERENT REASONS, which is why both are pinned: "in-loop
; state prep" sounds like one thing and is two.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

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
