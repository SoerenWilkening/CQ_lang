; control_swap_reject_blockaddress_switch_arm.ll — DECLINE (bd 7udx).
; ARM: `declineAddressTakenBlocks` at the `RegionFlatten::flattenSwitchRegion` call site.
;
; `flattenSwitchRegion` (4.5) erases EVERY case arm and the merge. The doomed
; set is built from `R.SwitchArms` rather than a fixed arm/armFalse pair, so it is
; a genuinely separate call site from `flattenRegion`'s.
;
; NON-PERTURBING PROBE FORM, and this is the point of it: the body below is
; ir-pass/test/control_swap_switch_phase.ll's VERBATIM, byte for byte. The only addition is a
; separate holder function whose `store ptr blockaddress(@example, %a1)` takes the
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
; RED-GREEN: control_swap_switch_phase.ll accepts on BOTH plugins and is
; kept as the reach control; this module accepts on the pre-change plugin and
; declines here. Corpus population of `blockaddress` is ZERO (0/966 fixtures,
; 0/257 e2e, 0/251 openlibm), so the guard costs nothing measurable — it is
; protecting a legal, clang-accepted input shape (`void *p = &&L;`) that CQ
; currently miscompiles silently instead of declining.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: address-taken block erased under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1
                                i32 2, label %a2 ]
a0:
  %g0 = call i32 @cq_phi_si32(i32 0, double 1.000000e-01)
  br label %merge
a1:
  %g1 = call i32 @cq_phi_si32(i32 1, double 2.000000e-01)
  br label %merge
a2:
  %g2 = call i32 @cq_phi_si32(i32 2, double 3.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %g0, %a0 ], [ %g1, %a1 ], [ %g2, %a2 ]
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

@cq_ba_slot = global ptr null

; The doomed block's address, taken from a function the lowering never touches.
define void @cq_ba_holder() {
  store ptr blockaddress(@example, %a1), ptr @cq_ba_slot, align 8
  ret void
}
