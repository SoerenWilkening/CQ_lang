; lowering_uncompute_interior_leak_loop_rail.ll — ⚠ THE NAME IS HISTORY: THIS FILE
; NO LONGER LEAKS. It was the M-B Increment-5a LEAK PROBE (bd
; `test_C_libtooling-6uqc`) pinning "§2.9 AT-MOST-ONCE, applied per candidate: no
; rail minted inside a loop enters the interior partition", and its own header
; closed with *"the 7.3 iteration-local group is the ONE in-loop reversal in the
; tree and it has its own affirmative proof (`IterationLocalBlocks`); Inc 5 does
; not extend it, and a loop-aware interior partition is tracked as later work."*
; bd `test_C_libtooling-tu9q` (2026-09-15) is that later work, and this loop now
; HAS the affirmative proof: `%q = cq_theta(%u0, 0.5)` is a ROOT MINT whose arg 0
; is a function ARGUMENT (classical), so `invariantRegisterRoots` admits it and
; `lowerLoops` hands the loop to `markIfRailLocal`. Every gate this file used to
; leak is minted IN the body and adjointed IN the body — one adjoint per forward
; execution, which is the property §2.9 was protecting, reached by placing the
; discharge in-body instead of at function scope.
;
; ⚠ NOT RENAMED, DELIBERATELY (bd `test_C_libtooling-gahu`, `CLAUDE.md` L8): a
; `git mv`'d fixture can be resurrected by a merge into one module under two names
; with contradictory verdicts. Renaming is owed as its own change.
;
; ⚠ WHAT IS **NOT** RETIRED, AND THE DISTINCTION IS THE WHOLE FENCE. The §2.9
; per-candidate backstop still refuses every in-loop rail in an UNMARKED body, and
; the sibling leak probes that pin it are UNMOVED and must stay so:
; `lowering_uncompute_interior_leak_irreducible_mint.ll` (an irreducible cycle can
; never be marked — the marker is `LoopInfo`-gated), and the QRAM / literal-slot
; probes, which fail `isInteriorTerminalHandle` for reasons that have nothing to do
; with loops. What changed is which BODIES carry the mark, not the backstop.
;
; ⚠ WHY THE MARK IS SOUND HERE rather than "the backstop was relaxed": `%q` lowers
; to `cqrt_alloc_i32` + `cqrt_ry_i32`, and `ChainWalk::isInteriorTerminalHandle`
; clause (I1) excludes an alloc-minted rail from the interior partition OUTRIGHT —
; so the one hazard `markIfRailLocal`'s own comment names ("a recovered gate in the
; PREHEADER (does not repeat) with `At` in a body marked here (repeats K times)
; would emit K adjoints against ONE forward gate") is UNBUILDABLE with a root mint
; as the invariant read. Every gate recovered below is minted in the body, so the
; multiplicity is 1:1 by construction.
;
; THE ORDER IS THE RULE-6 ARGUMENT, and `CHECK-NEXT` pins it: each rail's `_unc`
; runs BEFORE its `cqrt_free`, and the two rails are discharged in REVERSE program
; order (`icmp` then `mul`), so every borrowed parent still holds the value its
; forward gate read. The measured `%h_cast` is `cq_measure`'s and is freed by
; NEITHER form; `%h` is the user register and is never freed at all.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=COUNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @leak_loop(
; CHECK: %h = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; CHECK: %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
; CHECK-NEXT: %h_cmp = call i32 @cq_template_icmp_slt_i32_hl(i32 %h_op, i32 10)
; CHECK-NEXT: %h_cast = call i32 @cq_template_zext_i1_to_i32(i32 %h_cmp)
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp, i32 %h_op, i32 10)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %h_op)
; CHECK-NEXT: %m{{[0-9]*}} = call i32 @cqrt_measure_i32(i32 %h_cast)
;
; WHOLE-FILE COUNTS in their OWN prefix (Rule 12 hygiene (a)): exactly two frees,
; and never of the measured rail or of the user register.
; ⚠ COUNTS AND NEGATIVES IN SEPARATE PREFIXES — a positive `CHECK-COUNT` WINDOWS
; every negative after it (Rule 12 fixture-hygiene defect (a); Track T finding T-4
; caught that hole in `loop_leak_dephase_accept_pertrip_dead.ll`).
; COUNT-COUNT-2: call void @cqrt_free(
; COUNT-NOT: call void @cqrt_free(
;
; NEG-NOT: call void @cqrt_free(i32 %h)
; NEG-NOT: call void @cqrt_free(i32 %h_cast)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leak_loop(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i2, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %m, %loop ]
  %a = mul i32 %q, 3
  %c = icmp slt i32 %a, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  %i2 = add i32 %i, 1
  %e = icmp slt i32 %i2, 4
  br i1 %e, label %loop, label %out
out:
  ret i32 %acc
}

