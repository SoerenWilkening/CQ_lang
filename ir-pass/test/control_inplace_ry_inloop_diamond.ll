; control_inplace_ry_inloop_diamond.ll — ACCEPT: a control-in-place ROTATION arm
; inside a classically-bounded loop, lowered ROLLED (control-in-place-PRD §13,
; bd test_C_libtooling-drbq Increment 3).
;
;     for (i = 0; i <= 3; i++) { if (q > 5) cq_theta(&r, .9); }
;
; THIS FILE SHIPPED AS A DECLINE UNTIL 2026-09-04 and its whole header was an
; Inc-3 to-do list; it is rewritten in full rather than edited. Its decline
; sibling is RE-HOMED onto the shape that still declines for the reason R6 was
; written for — control_inplace_ry_reject_inloop_alias.ll, the same CFG with the
; carry made an IDENTITY and the merge escaping.
;
; SHAPE S2 (PRD §13.3) — the IDENTITY-CARRY case, and the one M-β exists for.
; There is NO post-region gate on `r`, so the loop's carry after the emitter's
; rewire is `%r = phi [%r0, entry], [<the hoisted gate>, merge]`. Under the
; PRE-Inc-3 convention (`RAUW(merge φ → Base)`) that carry would have been the
; ZERO-HOP identity `phi [%r0, entry], [%r, latch]`, which
; `LoopLowering::recordRefreshedByDef` correctly calls FROZEN — so
; `railGateBetween` would take no cut and this very module would decline
; `rail record read past an in-place gate on the same rail`. M-β RAUWs to the
; hoisted gate instead, making it a chain MEMBER, and every round-2 predicate
; then reads the truth with no exemption.
;
; `q` IS LOOP-INVARIANT HERE AND THAT IS FINE **IN HAND IR**, which is worth
; saying because it is not fine from C. The compare is written inside the loop
; block, so `condWireDisposition`'s P4 precondition (`Cond->getParent() ==
; R.Pred`) holds and R7 is the only wall. From C, `clang -O1` LICM-hoists a
; loop-invariant compare into the preheader and the same source declines on P4 —
; PRD §13.2 row W, an over-decline pinned by
; control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll.
;
; WHAT MUST BE IN THE OUTPUT: the four-call per-activation stream (flag mint,
; controlled Ry, flag strip, free) INSIDE the loop block, and NO route at all —
; the cswap route cannot carry an Ry (`Ry|0> != |0>` leaves the inactive work
; rail dirty and entangled, Rules 6/8), which is why this is the MECHANISM and
; not a peephole.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; The loop SURVIVES (rolled, one copy of the body) and the region is flattened
; into it:
; CHECK: loop:
; CHECK: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.0
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
; CHECK: br i1 %done, label %exit, label %loop
;
; No route and no work rail anywhere in the module, and every front-end rotation
; is lowered (the two entry-block `cqrt_ry_i32` state preps are the SOURCE's own
; and are deliberately not excluded here).
;
; THESE TWO ARE A SEPARATE `NOROUTE` PREFIX, NOT TRAILING `CHECK-NOT`s, AND THE
; DIFFERENCE IS THE WHOLE ASSERTION (bd drbq Inc 3, round-1 lens L6, F-L6-1). A
; `CHECK-NOT` after the last positive `CHECK` scans only from THAT match to EOF —
; here the exit block and the declares — so injecting a `cqrt_cswap` and a stray
; `cq_theta` INTO THE LOOP BODY left this file GREEN, while its own header
; claimed "anywhere in the module". A `--check-prefix` with no positive directive
; scans the whole file, which is what the header says.
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: @cq_theta_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
