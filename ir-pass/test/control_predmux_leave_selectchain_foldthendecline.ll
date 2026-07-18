; control_predmux_leave_selectchain_foldthendecline.ll — LEAVE→DECLINE
; (bd 20xt.5.1 blocker (e), the "fold FIRES then still declines" over-accept fence).
;
; Unlike control_predmux_leave_selectchain_offgrammar.ll (where the residue fold
; never fires), here the fold DOES fire — it collapses the real residue
; `and i1 false,%t1` and its dead `select i1 false,…` in block %ia — yet a SECOND
; select in the same flattened region has a genuinely off-grammar `xor i1 %t2,true`
; (a boolean NOT) condition. The fold is scoped to constant-operand i1 and/or +
; constant-condition/same-arm selects (Rule 14, InstSimplify over a gated shape),
; so it CANNOT touch the `xor`, and `collectCondTree` still declines it. This
; proves a fold that DOES do work never exposes an off-grammar operand into an
; accept (Prime Directive: over-accepting is the one unforgivable miscompile).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %inner, label %merge
inner:
  %c2 = icmp slt i32 %q, 100
  br i1 %c2, label %ia, label %ib          ; nested tainted branch -> PredMux claim
ia:
  %t1    = icmp eq i32 %q, 3
  %dcond = and i1 false, %t1               ; residue -> the fold FIRES (-> false)
  %va    = select i1 %dcond, i32 100, i32 %q  ; dead select -> collapses to %q
  %t2    = icmp eq i32 %q, 7
  %off   = xor i1 %t2, true                ; off-grammar NOT (fold cannot touch)
  %w     = add i32 %va, 5                  ; distinct from %va, so %vb is NOT same-arm
  %vb    = select i1 %off, i32 %va, i32 %w ; STILL declines (xor leaf in the tree)
  br label %ijoin
ib:
  %vc = add i32 %q, 7
  br label %ijoin
ijoin:
  %vj = phi i32 [ %vb, %ia ], [ %vc, %ib ]
  br label %merge
merge:
  %r  = phi i32 [ %vj, %ijoin ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
