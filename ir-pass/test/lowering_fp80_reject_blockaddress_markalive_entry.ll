; lowering_fp80_reject_blockaddress_markalive_entry.ll — DECLINE (bd 7udx).
; ARM: `removeUnreachableBlocksChecked`'s `!dbg` ANCHOR LIFETIME.
;
; *** THIS FIXTURE PINS A DETERMINISTIC SIGSEGV THE RULE-13 JUDGE FOUND IN THE FIX
; ITSELF. *** The first draft of `removeUnreachableBlocksChecked` held the anchor
; instruction as a raw `Instruction *` across its `removeUnreachableBlocks(F)` call.
; `markAliveBlocks` reaches `changeToUnreachable(I)`, which ERASES `I` — and
; `Fp80Union` passes the ENTRY BLOCK'S FIRST INSTRUCTION as the anchor. When the
; markAlive trigger IS that first instruction (a store to null, or an
; `llvm.assume(i1 false)`), the anchor is freed by the call and the diagnostic then
; reads freed memory: `opt` exit 139, 3/3 runs, on VALID input. The fix holds the
; anchor in a `WeakTrackingVH` and re-derives it after the call.
;
; WHY lowering_fp80_reject_blockaddress_markalive.ll DOES NOT COVER THIS: there the
; trigger is a store-to-null in a NON-entry block (`%ub`), so the anchor survives and
; that row passes on the crashing draft too. The distinguishing feature here is the
; trigger's POSITION, not its kind.
;
; THIS ROW IS GENUINELY RED ON THE CRASHING DRAFT: LLVM's `not` (without `--crash`)
; FAILS on a signal death, so the fixture discriminates a crash from a decline rather
; than accepting both.
;
; The `noreturn` trigger deliberately has no fixture of its own — there
; `changeToUnreachable` is applied to the call's SUCCESSOR, so the entry anchor
; survives and the shape is already covered by the non-entry row. Any future change
; to the anchor handling must be re-tested against the STORE-TO-NULL and
; `llvm.assume` spellings specifically.
;
; RED-GREEN: the pre-change plugin ACCEPTS this module (`opt` exit 0) and emits the
; corrupted `store ptr inttoptr (i32 1 to ptr)`.
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
  store i32 0, ptr null, align 4          ; <-- FIRST insn of entry == the Anchor == the markAlive trigger
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %foldme = add i32 1, 2
  store i32 %foldme, ptr @sink, align 4
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
