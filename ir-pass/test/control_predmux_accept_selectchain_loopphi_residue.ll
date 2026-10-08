; control_predmux_accept_selectchain_loopphi_residue.ll — ACCEPT / crash
; regression (bd 20xt.5.1 blocker (e), Rule-13 re-review DCE-safety finding).
;
; The residue fold's operand-cone DCE (RecursivelyDeleteTriviallyDeadInstructions)
; must be iterator-safe. A LOOP PHI's back-edge incoming value need NOT dominate
; the phi (it dominates only the incoming block terminator), so it can be defined
; AFTER the fold site in the same block — exactly at the `make_early_inc_range`
; lookahead cursor. Folding `and i1 %loopphi, false -> false` orphans the phi and
; cascades to its back-edge operand (`%J`, the next instruction), which an inline
; delete would free out from under the cursor (a UAF crash on valid IR). The
; two-pass worklist (collect residues, then fold+DCE over a WeakTrackingVH list —
; no block iterator held during deletion) makes this lower cleanly instead of
; crashing. This fixture covers BOTH deletion-safety paths: the back-edge value
; `%J` is ITSELF a residue (`and i1 %cnd, false`), so it is a LATER worklist entry
; that the cascade deletes while processing `%I` — exercising the WeakTrackingVH
; null-out + `dyn_cast_or_null` skip (a raw `Instruction*` worklist would UAF
; here too). A claimable nested-tainted diamond makes the whole-function sweep run.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
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
  %va = add i32 %q, 1
  br label %ijoin
ib:
  %vb = add i32 %q, 7
  br label %ijoin
ijoin:
  %vj = phi i32 [ %va, %ia ], [ %vb, %ib ]
  br label %merge
merge:
  %r   = phi i32 [ %vj, %ijoin ], [ %q, %entry ]
  %cnd = icmp eq i32 %q, 3
  br label %loophdr
loophdr:
  ; %P's back-edge value %J is defined AFTER %P and after the fold site %I:
  %P = phi i1 [ false, %merge ], [ %J, %loophdr ]
  %I = and i1 %P, false                    ; residue -> folds; DCE cascade -> %P -> %J
  %J = and i1 %cnd, false                   ; residue AND = getNextNode() AND a later
                                            ; worklist entry cascade-deleted here
  br i1 %I, label %loophdr, label %lexit
lexit:
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; Lowers without crashing: the theta rail allocates and the measure fires.
; CHECK: %u0.stable = freeze i32 %u0
; CHECK: call i32 @cqrt_alloc_i32(i32 %u0.stable)
; CHECK: call i32 @cqrt_measure_i32(
