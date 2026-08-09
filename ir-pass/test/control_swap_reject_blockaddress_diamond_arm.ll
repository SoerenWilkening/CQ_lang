; control_swap_reject_blockaddress_diamond_arm.ll — DECLINE (bd 7udx).
; ARM: `declineAddressTakenBlocks` at the `RegionFlatten::flattenRegion` call site.
;
; `flattenRegion` erases the arm, the false arm AND the merge block. It is
; the widest-reused of the three RegionFlatten entry points: 4.1 phase arms, 4.2
; value arms, the 4.5 eq-folded diamond, the 6.5 classical-call arm
; (ClassicalCallArmEmit) and the 7.6 I/O sink diamond (IOSinkLowering) all route
; through it, so this one fixture covers every one of those surfaces.
;
; NON-PERTURBING PROBE FORM, and this is the point of it: the body below is
; ir-pass/test/control_swap_diamond.ll's VERBATIM, byte for byte. The only addition is a
; separate holder function whose `store ptr blockaddress(@example, %arm)` takes the
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
; RED-GREEN: control_swap_diamond.ll accepts on BOTH plugins and is
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

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q,  double %a)
  %q2 = call i32 @cq_phi_si32(i32 %q1, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %q2, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

@cq_ba_slot = global ptr null

; The doomed block's address, taken from a function the lowering never touches.
define void @cq_ba_holder() {
  store ptr blockaddress(@example, %arm), ptr @cq_ba_slot, align 8
  ret void
}
