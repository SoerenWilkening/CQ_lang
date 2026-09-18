; control_predmux_accept_noreturn_degenerate_merge.ll — ACCEPT (bd fn1q
; increment 3, Rule-13 round 2 R2-7). A function with NO REACHABLE `ret`.
;
; ⚠ IT IS HERE BECAUSE THE INCREMENT SHIPPED A COMMENT SAYING THIS COULD NOT
; HAPPEN. `recoverRegion`'s bd-20xt.5(d) block used to say E2 declined infinite
; loops; the increment corrected that to "all four spellings still DECLINE …
; NOBODY HAS CONSTRUCTED ONE THAT CLAIMS". Round 2 constructed one. With no
; reachable `ret` the post-dominator sets never receive an exit seed, so
; `mergeIgnoringUnreachable` names the merge by its degenerate first-discovered
; rule — and the region is CLAIMED and flattened. ORACLE: rc=1, `gate=E2-cycle`,
; `control flow under quantum control`. SUBJECT: rc=0, stage 2b STRICT
; `2 verified, 0 violation(s), 0 unproven`.
;
; ⚠ THE SOUNDNESS ARGUMENT DOES NOT DEPEND ON THAT MERGE BEING THE REAL JOIN, and
; that is the whole point of pinning it. Whatever block the degenerate
; post-dominance names, E3 then demands successors within region+merge, every
; non-entry predecessor in region, and every merge predecessor in region; the
; Kahn proof demands acyclicity. Together those force a genuinely single-entry
; single-exit acyclic region, so the flatten is the same rewrite it always is.
; The `select` spelling of this same program already compiles on the ORACLE.
;
; ⚠ WHAT IS NOT ESTABLISHED: nobody has tried to build a non-returning function
; where the arbitrary merge is NOT the real join and E3 still passes. The
; argument above says it cannot exist; it has not been attacked. If you are
; widening E3, that is the probe to write first.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK: cqrt_alloc
declare i32 @cq_theta_si32(i32, double)
define void @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %H
H:
  %a = phi i32 [ 5, %entry ], [ %an, %A ]
  %b = phi i32 [ 6, %entry ], [ %bn, %A ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %A, label %B
A:
  %an = phi i32 [ %a, %H ], [ %a1, %B ]
  %bn = phi i32 [ %b, %H ], [ %b1, %B ]
  br label %H
B:
  %a1 = add i32 %a, -3
  %b1 = add i32 %b, -4
  br label %A
}
