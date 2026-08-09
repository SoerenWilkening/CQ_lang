; lowering_qram_reject_blockaddress_guarded_arm.ll — DECLINE (bd 7udx).
; ARM: `declineAddressTakenBlocks` at the `GuardedStoreArmEmit` call site.
;
; The 7.5 guarded Shadow-store arm (iw81.7) is emitted and torn down by
; `GuardedStoreArmEmit`, which never calls into `RegionFlatten` — it erases its
; own `ArmBB` inline. Note its MERGE survives (measured), unlike
; `flattenRegion`'s, which is exactly why the guard takes a per-site doomed set
; instead of a blanket "the whole region".
;
; NON-PERTURBING PROBE FORM, and this is the point of it: the body below is
; ir-pass/test/lowering_qram_guarded_store.ll's VERBATIM, byte for byte. The only addition is a
; separate holder function whose `store ptr blockaddress(@guarded, %arm)` takes the
; doomed block's address. So no proof, gate or classifier inside the lowered
; function is perturbed — the ONLY thing that changed is that a `BlockAddress`
; now exists. A probe that edits the region body instead can decline for an
; unrelated reason and prove nothing.
;
; MEASURED on the pre-change plugin: `opt` exit 0, verify clean, and the holder's
; store emerges as `store ptr inttoptr (i32 1 to ptr), ptr @cq_ba_slot` — the
; address silently rewritten to 1 on a WELL-DEFINED source. `BasicBlock::
; ~BasicBlock()` RAUWs every `BlockAddress` of a destroyed block to
; `inttoptr (i32 1 to ptr)`, MODULE-WIDE, so the corruption is not confined to
; the region or even to quantum operands: here it lands in ordinary classical
; pointer data in a different function entirely. The worst reachable form of this
; is a live computed `goto` whose destination is erased — the program then jumps
; to address 1, `opt` exit 0.
;
; RED-GREEN: lowering_qram_guarded_store.ll accepts on BOTH plugins and is
; kept as the reach control; this module accepts on the pre-change plugin and
; declines here. Corpus population of `blockaddress` is ZERO (0/966 fixtures,
; 0/257 e2e, 0/251 openlibm), so the guard costs nothing measurable — it is
; protecting a legal, clang-accepted input shape (`void *p = &&L;`) that CQ
; currently miscompiles silently instead of declining.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: address-taken block erased under quantum control

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @guarded(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %f = icmp slt i32 %q, 3
  br i1 %f, label %arm, label %merge

arm:                                              ; the side-effect-only store arm
  %si = sext i32 %i to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %si
  store i32 7, ptr %g, align 4                    ; arr[i] = 7 — tainted index, guarded
  br label %merge

merge:
  %sq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sq
  %v = load i32, ptr %gq, align 4                 ; arr[q] — unconditional (post-dominates)
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

@cq_ba_slot = global ptr null

; The doomed block's address, taken from a function the lowering never touches.
define void @cq_ba_holder() {
  store ptr blockaddress(@guarded, %arm), ptr @cq_ba_slot, align 8
  ret void
}
