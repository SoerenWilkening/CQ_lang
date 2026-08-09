; lowering_fp80_reject_blockaddress_markalive.ll — DECLINE (bd 7udx).
; ARM: `removeUnreachableBlocksChecked`'s OBSERVE-don't-PREDICT contract.
;
; *** THIS IS THE HOLE THE RULE-13 ROUND FOUND IN THE FIRST DRAFT OF GUARD 2. ***
; That draft PREDICTED `llvm::removeUnreachableBlocks`'s deletion set with a plain
; depth-first walk from the entry, on the reading that it deletes exactly the
; DFS-unreachable blocks. It does not. LLVM 19 runs `markAliveBlocks` FIRST — the
; symbol is in libLLVM with signature
; `markAliveBlocks(Function&, SmallPtrSetImpl<BasicBlock*>&, DomTreeUpdater*)`
; (verified with llvm-nm on this machine) — and that pass MUTATES: a non-volatile
; `store` to a null pointer, a call to a `noreturn` callee, or an
; `llvm.assume(false)` is rewritten to `unreachable`. Blocks that were reachable a
; moment earlier are then orphaned, so the true deletion set is a STRICT SUPERSET
; of the prediction.
;
; Here `%live_ba` is reachable from `%entry` through `%ub` in the CFG the predicting
; walk sees, so that draft reported "not doomed" — and `removeUnreachableBlocks`
; deleted it anyway, RAUWing `blockaddress(@f, %live_ba)` to
; `inttoptr (i32 1 to ptr)` MODULE-WIDE. Measured on both the pre-change plugin and
; that draft: `opt` exit 0, and the holder's store emerges as
; `store ptr inttoptr (i32 1 to ptr), ptr @slot`.
;
; THE FIX IS THE CONTRACT, NOT A BETTER MODEL. `removeUnreachableBlocksChecked`
; watches every block whose address is genuinely USED with a `WeakTrackingVH`,
; calls the real utility, and declines if a watched block actually died. Nothing is
; predicted, so nothing drifts when LLVM changes. THIS FIXTURE IS THE ONLY THING
; PINNING THAT: re-introduce any predictive reachability model and it goes red.
;
; Two more triggers reach the same site and are deliberately NOT given their own
; fixtures, because they exercise the identical arm through a different
; `markAliveBlocks` rule: a `noreturn` call, and `llvm.assume(i1 false)`. If this
; row ever needs widening, those are the shapes.
;
; `%foldme = add i32 1, 2` is load-bearing: `foldConstantConeAndBranches` only
; reaches its `removeUnreachableBlocks` call when it folded something, so without
; an all-constant instruction the site is never entered.
;
; RED-GREEN: the pre-change plugin ACCEPTS this module (`opt` exit 0) and emits the
; corrupted store. The reach control is
; lowering_fp80_accept_blockaddress_markalive_live.ll — the same module with the
; UB store replaced by a store to a real global, so `%live_ba` survives and its
; address stays intact.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: address-taken block erased under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

@slot = global ptr null
@sink = global i32 0

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %foldme = add i32 1, 2
  store i32 %foldme, ptr @sink, align 4
  %cc = icmp eq i32 %u0, 999
  br i1 %cc, label %ub, label %qhead

ub:
  store i32 0, ptr null, align 4
  br label %live_ba

live_ba:
  br label %qhead

qhead:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge

merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %qhead ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

define void @cq_ba_holder() {
  store ptr blockaddress(@f, %live_ba), ptr @slot, align 8
  ret void
}
