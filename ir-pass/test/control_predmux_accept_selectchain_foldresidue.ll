; control_predmux_accept_selectchain_foldresidue.ll — ACCEPT (bd 20xt.5.1
; blocker (e), the atan2l residual i32 select-chain).
;
; A NESTED tainted region (outer `%c1` + inner `%c2`) is claimed and flattened by
; PredMux. Inside an arm a classical special-case guard is an ALL-CONSTANT
; compare (`icmp eq i32 7, 9`, the stand-in for atan2l's `x==1.0` test with x a
; positive classical constant) that the flatten's `foldConstantConeAndBranches`
; collapses to `false` — but ConstantFold is all-or-nothing, so it leaves the
; PARTIAL-constant residue `and i1 false,%t3` feeding a `select`. WITHOUT the
; post-flatten residue fold, `collectCondTree` hits that `false` ConstantInt leaf
; and declines (see the companion control_predmux_leave_selectchain_offgrammar.ll
; for the exact message). WITH the fold, `and i1 false,%t3 → false`, the dead
; `select i1 false,…` collapses to its false arm, and the surviving data merge
; lowers via the 4.4 controlled-XOR copy path.
;
; The --implicit-check-not directives scan the WHOLE lowered output (not just the
; tail after the last positive CHECK), so any residual control flow left in the
; flattened region body — or the DCE'd dead residue compare `icmp eq %q,3` — fails
; the test even if opt still exits 0.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s  --implicit-check-not='select i1' --implicit-check-not='phi i32'  --implicit-check-not='br i1' --implicit-check-not='cq_template_icmp_eq' < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
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
  %kfold = icmp eq i32 7, 9                 ; ALL-CONST -> ConstantFold -> false
  %t3    = icmp eq i32 %q, 3
  %dcond = and i1 %kfold, %t3               ; -> residue `and i1 false, %t3`
  %va    = select i1 %dcond, i32 100, i32 %q  ; dead: -> %q after the fold
  br label %ijoin
ib:
  %vb = add i32 %q, 7
  br label %ijoin
ijoin:
  %vj = phi i32 [ %va, %ia ], [ %vb, %ib ]
  br label %merge
merge:
  %r  = phi i32 [ %vj, %ijoin ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; The theta rail allocates; the flattened region's genuine merges lower to flag
; mint (icmp) + controlled-copy; the dead residue select leaves NO trace, and its
; now-orphaned tainted compare `icmp eq %q,3` is DCE'd (no cq_template_icmp_eq),
; so no entangled which-path flag is left dangling (Rule 6/8).
; CHECK:     call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-DAG: call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK-DAG: call i32 @cq_template_icmp_slt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 100)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call i32 @cqrt_measure_i32(
