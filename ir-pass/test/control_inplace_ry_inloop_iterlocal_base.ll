; control_inplace_ry_inloop_iterlocal_base.ll — ACCEPT (bd
; `test_C_libtooling-wx8g`, R7-loop CLAUSE (c)): the rotated register is
; ITERATION-LOCAL — minted inside the loop body, so its rail does NOT cross the
; back edge — and the loop lowers ROLLED, one fresh rail per activation.
;
; ⚠ THIS FILE SHIPPED AS A DECLINE UNTIL 2026-09-14 and is REWRITTEN IN FULL.
; Its old header made two claims; the first is unchanged and the second is
; CORRECTED BY MEASUREMENT, which is the reason this header is long.
;
;   1. "THIS IS R7-loop CLAUSE (b), AND IT IS A SCOPING CLAUSE, NOT A SAFETY
;      ONE." — TRUE, and it is exactly why clause (c) is an ADDITION rather than
;      a relaxation. Clause (b) asks "does the rail cross the back edge, and will
;      round 2 CLAIM its header phi?"; there is no header phi here, so (b) could
;      never fire and every such program declined BY CONSTRUCTION, forever.
;      Clause (c) asks the complementary question — "is the rail RE-MINTED every
;      trip?" — by calling `railChainRootMint`, the same clean-rail-mint body
;      `railPhiRootMint` calls, with `L->contains(Mint->getParent())` where (b')
;      has `DT.dominates(Mint, header)`.
;
;   2. "IT IS ALSO MEASURABLY NOT TWIN-IDENTICAL … the merge escapes the region
;      into a `cq_measure` inside the body, so `markIfRailLocal` refuses the
;      iteration-local marking and the ROLLED form leaks the condition chain once
;      per trip while the hand-unrolled twin discharges it." — THE MECHANISM IS
;      REAL AND THIS MODULE IS NOT AN INSTANCE OF IT. Measured 2026-09-14 on the
;      scaffolded subject with clause (c3) absent: the divergence needs the
;      per-trip register to ESCAPE `L` (be read AFTER the loop), and here it is
;      measured INSIDE the body, so nothing tainted defined in `L` has a user
;      outside it. The escaping spelling diverges 19 rolled vs 27 unrolled trace
;      lines and is pinned as a DECLINE by
;      control_inplace_ry_reject_inloop_iterlocal_escape.ll, whose header carries
;      the numbers. One edge of difference, two dispositions — that pair is what
;      makes clause (c3) a fence rather than a comment.
;
; WHAT MUST BE IN THE OUTPUT: a per-activation stream INSIDE the loop block —
; the FRESH rail mint (`cqrt_alloc_i32(%u1)` + `cqrt_ry_i32`), the flag mint, the
; controlled Ry, the flag strip, the flag free, the measurement — and no route.
; The per-trip register is MEASURED, so the user owns it and nothing frees it
; (`Ry(θ)|0> != |0>`, Rule 6).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; The loop SURVIVES (rolled) and the ALLOC IS INSIDE IT — that placement is the
; whole of clause (c2): K activations mint K rails, exactly as K copies would.
; CHECK: loop:
; CHECK: %h1 = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h1, double 2.500000e-01)
; CHECK-NEXT: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.0
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
; CHECK-NEXT: %m = call i32 @cqrt_measure_i32(i32 %h1)
; CHECK: br i1 %done, label %exit, label %loop
;
; ⚠ COUNTS IN THEIR OWN WHOLE-FILE PREFIX (Rule 12 hygiene (a)). ONE of each per
; activation — a second alloc or a second controlled Ry would mean the body was
; duplicated, and a second FREE would mean the per-trip register was freed dirty.
; COUNT-COUNT-2: call i32 @cqrt_alloc_i32(
; COUNT-NOT: call i32 @cqrt_alloc_i32(
; COUNT-COUNT-1: call void @cqrt_ry_i32_controlled(
; COUNT-NOT: call void @cqrt_ry_i32_controlled(
; COUNT-COUNT-1: call void @cqrt_free(
; COUNT-NOT: call void @cqrt_free(
;
; ⚠ A PURE NEGATIVE PREFIX — no route, no bracket, no surviving front-end gate.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_x(
; NOROUTE-NOT: @cq_theta_
;
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %rl = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %rl, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %rl, %loop ]
  %mm = call i32 @cq_measure_si32(i32 %rm)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %mm
}
