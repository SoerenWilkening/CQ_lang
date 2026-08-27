; control_predmux_accept_positive_tree_orphan_armkill.ll — ACCEPT (bd qesi).
; ARM: the ARM-KILL for the two `..._no_orphan_*` rows. Byte-identical to
; `control_predmux_accept_negated_tree_no_orphan_leaves.ll` except that the two
; branch successors are SWAPPED, so the gate arm is the TRUE successor.
;
; WHY THIS FILE IS COMMITTED RATHER THAN LEFT AS A ONE-OFF. Without it, the sibling
; rows' `CHECK-NOT: cq_template_icmp_sgt` could pass for the wrong reason and nobody
; would know — a future change that stops claiming the region at all, or that renames
; a symbol, satisfies a CHECK-NOT trivially. This row pins the OPPOSITE: with the
; arm as the TRUE successor the ORIGINAL predicates `sgt`/`slt` are the ones that
; survive and are USED, because there is no negation to perform. So the sibling rows
; assert absence of symbols this row proves are otherwise present and load-bearing.
;
; AND IT LOCATES THE CAUSE PRECISELY, which the bd qesi title initially overstated as
; "any REBUILT condition tree". MEASURED — orphan counts by spelling and polarity.
; *** READ THE SCOPE LINE: the two `select` rows hold for a shield that IS THE BRANCH
; CONDITION (root-level) ONLY. *** An earlier draft of this header stated them
; unscoped, which was false — see below.
;     plain  `and i1`,      arm = TRUE   (canonicalizePred, NO rebuild)   0 orphans
;     plain  `and i1`,      arm = FALSE  (buildNegation)                  2 orphans
;     ROOT shielded select, arm = TRUE   (canonicalizePred, DOES rebuild) 0 orphans
;     ROOT shielded select, arm = FALSE  (buildNegation)                  2 orphans
; So REBUILDING is not the cause of THIS row's defect — at root level
; `canonicalizePred` rebuilds and orphans nothing, because it REUSES the original
; compare leaves so only the shield node dies, and that node is already `track()`ed
; as the branch condition (`track(BI->getCondition())` in `run()`).
; `buildNegation` is the place that REPLACES a leaf (with a fresh inverse-predicate
; compare), which is what strands the original.
;
; *** ONE HONEST LIMIT ON THE TABLE, because a committed "MEASURED" table that
; overreaches is worse than no table: the two `select` rows were measured on scratch
; files that are NOT committed — `grep -c 'select i1'` on THIS file is 0, its body
; being `%sc = and i1 %a, %b`. So nothing in the tree pins them here. ***
;
; *** AND THE SECOND LIMIT WAS A REAL DEFECT, NOW FIXED — bd kqqv. *** Unscoped, row
; 3 was FALSE. For a NON-root shield (`%inner = select i1 %b, i1 %c, i1 false`
; feeding `%sc = and i1 %a, %inner`) the arm=TRUE route emitted an ENTIRE DEAD 4.4
; controlled-copy select merge: an `%out = cqrt_alloc_i1(false)` written by two
; `cqrt_copy_i1_controlled` and NEVER READ, a never-freed `%selop`, and a
; never-uncomputed `icmp_ne`. 9 rail mints / 5 left allocated, against 7 / 3 at
; arm=FALSE. `canonicalizePred` now opens with `trackCondCone(V)`, and the cell this
; header could not cover is covered by three fixtures of its own:
; control_predmux_accept_nonroot_shield_no_orphan.ll (which carries the DEPTH table
; that supersedes rows 3-4 above), its `_armkill` twin, and
; control_predmux_accept_shield_under_shield_no_orphan.ll.
; When that fix landed, a census of all 1062 fixtures had found ZERO carrying a
; non-root shielded select, accept or reject — the cell had never been covered by
; anything, which is why re-measuring rather than re-reading was what found it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll --check-prefix=NOINVERSE

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %b = icmp slt i32 %q, 100
  %sc = and i1 %a, %b
  br i1 %sc, label %arm, label %merge      ; arm = TRUE successor (the only change)

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; The ORIGINAL predicates survive and are the ones the flag tree consumes — each
; minted, then uncomputed, then freed. That is the shape the sibling rows require of
; the inverse predicates:
; CHECK: cq_template_icmp_sgt_i32_hl
; CHECK: cq_template_icmp_slt_i32_hl
; CHECK: cqrt_copy_i32_controlled
; CHECK: cq_template_icmp_slt_i32_hl_unc
; CHECK: cqrt_free

; No negation was performed, so no inverse-predicate compare exists at all — which
; is what makes this the arm-kill rather than a second copy of the same assertion:
; NOINVERSE-NOT: cq_template_icmp_sle
; NOINVERSE-NOT: cq_template_icmp_sge
; NOINVERSE-NOT: cq_template_and_i1
