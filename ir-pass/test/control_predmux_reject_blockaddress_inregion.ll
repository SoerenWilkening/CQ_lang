; control_predmux_reject_blockaddress_inregion.ll — DECLINE (bd 7udx).
; ARM: `declineAddressTakenBlocks` (LiteralIntegrity.cpp), called at the PredMux
; region CLAIM in `flattenPredMuxRegions`.
;
; *** THIS IS THE MOST SERIOUS DEFECT THE bd u1rp ROUND FOUND, AND IT IS NOT A
; POISON BUG. The source program is WELL-DEFINED. There is no UB anywhere and no
; LangRef refinement argument applies, so nothing excuses the divergence — the
; compiler simply emits a different number than the source says. Every other
; member of that round's family leans on "poison permits any value"; this one
; cannot. ***
;
; Measured on the pre-change plugin: claims and flattens, `opt` exit 0, verify
; clean, free_pairing_check clean —
;
;   icmp sgt i32 %q, ptrtoint (ptr blockaddress(@probe, %arm) to i32)
;     lowered to  cq_template_icmp_sgt_i32_hl(%h, i32 1)
;
; MECHANISM. `BasicBlock::~BasicBlock()` (LLVM 19) does, for a block it destroys
; that `hasAddressTaken()`, `BA->replaceAllUsesWith(inttoptr (i32 1 to ptr))` and
; then destroys the `BlockAddress` constant. Folding that through the `ptrtoint`
; yields exactly `i32 1`. The PredMux flatten erases every block of `R.Topo`
; except `R.Entry`, so `%arm` goes — and the compare it fed silently becomes a
; comparison against 1.
;
; THE RAUW IS MODULE-WIDE, not region-local: it rewrites EVERY use of that
; `BlockAddress` anywhere in the module. So a bare `store ptr blockaddress(...)`
; in an unrelated block is corrupted by the same erase, which is why the guard is
; keyed on the BLOCKS ABOUT TO BE ERASED and not on where the uses appear. The
; `@cq_ba_holder` store below carries that second channel — an EARLIER draft of this
; header claimed it while `@slot` was in fact a dead global with no store at all,
; and the Rule-13 round caught that; the store is now really there, in a function
; the lowering never touches so it perturbs no proof.
;
; The accept control — a `blockaddress` naming a block OUTSIDE every claimed
; region, which nothing erases and whose address survives intact — is
; control_swap_accept_blockaddress_outside_region.ll. Without that control this
; guard would over-decline every function containing a computed `goto` and nobody
; would notice.
;
; DERIVATION, recorded because two hand-written shapes declined for unrelated
; reasons before this one reached: this module is
; control_predmux_accept_selectform_seed_flags_preserved.ll's body VERBATIM with
; exactly ONE change — the literal `3` in `%a = icmp sgt i32 %q, 3` replaced by
; the `ptrtoint`. The two merge phis, the shielded `select i1 %a, i1 %b, i1 false`
; and the curated `llvm.ctlz` in the cone are ALL load-bearing for reaching the
; claim; do not simplify them.
;
; RED-GREEN: the pre-change plugin ACCEPTS this module (`opt` exit 0) and emits
; the corrupted `i32 1`, so the decline below is genuinely new.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: address-taken block erased under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctlz.i32(i32, i1 immarg)

@slot = global ptr null

define i32 @probe(i32 %u, i32 %c) {
entry:
  %seed = add nsw nuw i32 %u, 1
  %q = call i32 @cq_theta_si32(i32 %seed, double 5.000000e-01)
  %a = icmp sgt i32 %q, ptrtoint (ptr blockaddress(@probe, %arm) to i32)
  %r = call i32 @llvm.ctlz.i32(i32 %q, i1 false)   ; TOTAL — defined at %q == 0
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  ; TWO merge phis, deliberately — the single-phi form dies at the W-witness gate
  ; before the region is ever claimed, and a probe that dies there proves nothing.
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; The second channel, in a function the lowering never touches: on the pre-change
; plugin this store emerges as `store ptr inttoptr (i32 1 to ptr), ptr @slot`.
define void @cq_ba_holder() {
  store ptr blockaddress(@probe, %arm), ptr @slot, align 8
  ret void
}
