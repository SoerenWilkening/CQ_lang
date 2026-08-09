; control_swap_reject_blockaddress_abort_arm.ll — DECLINE (bd 7udx).
; ARM: `declineAddressTakenBlocks` at the `AbortParkEmit` call site.
;
; The 7.2 controlled-`abort` park (epic 65wb) erases its sink arm inline in
; `AbortParkEmit`, a fourth independent teardown that does not go through
; `RegionFlatten`.
;
; NON-PERTURBING PROBE FORM, and this is the point of it: the body below is
; ir-pass/test/control_swap_abort_park.ll's VERBATIM, byte for byte. The only addition is a
; separate holder function whose `store ptr blockaddress(@slice, %abort)` takes the
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
; RED-GREEN: control_swap_abort_park.ll accepts on BOTH plugins and is
; kept as the reach control; this module accepts on the pre-change plugin and
; declines here. Corpus population of `blockaddress` is ZERO (0/966 fixtures,
; 0/257 e2e, 0/251 openlibm), so the guard costs nothing measurable — it is
; protecting a legal, clang-accepted input shape (`void *p = &&L;`) that CQ
; currently miscompiles silently instead of declining.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: address-taken block erased under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @slice() {
  %q = call i32 @cq_theta_si32(i32 5, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %abort, label %cont
abort:
  call void @abort()
  unreachable
cont:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

@cq_ba_slot = global ptr null

; The doomed block's address, taken from a function the lowering never touches.
define void @cq_ba_holder() {
  store ptr blockaddress(@slice, %abort), ptr @cq_ba_slot, align 8
  ret void
}
