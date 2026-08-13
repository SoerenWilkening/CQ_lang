; spec_accept_blockaddress_clone_artifact.ll — ACCEPT (bd 7udx).
; ARM: `declineAddressTakenBlocks`'s USE test, and the only thing pinning it.
;
; *** THE FIRST DRAFT DECLINED THIS, ON A MODULE THE PRE-CHANGE PLUGIN LOWERS
; CORRECTLY WITH THE ADDRESS INTACT. *** Two independent Rule-13 lenses found it;
; one measured 31 of 1460 injected corpus variants flipping from a correct BASE
; lowering to a loud decline.
;
; `BasicBlock::hasAddressTaken()` is a REFCOUNT, not a use test. And
; `llvm::CloneFunctionInto` deliberately does, for every source block whose address
; is taken,
;     VMap[BlockAddress::get(OldFunc, &BB)] = BlockAddress::get(NewFunc, CBB);
; (its own comment: "we want to map block addresses from the old function to block
; addresses in the clone"). CONSTRUCTING that second `BlockAddress` bumps the CLONE
; block's refcount — so every block of a Phase-6 clone whose original had its address
; taken reports `hasAddressTaken()` while the constant lives only in the mapper's
; table and has ZERO USERS. `~BasicBlock()` then RAUWs nothing, so erasing such a
; block corrupts nothing.
;
; The guard therefore asks `BlockAddress::lookup(BB)` and requires a NON-EMPTY use
; list. A block whose address cannot be observed cannot be corrupted.
;
; Here `@helper`'s `%then` has a real, used address (the holder's store), so `@helper`
; itself is untouched and the store must come through intact — while the CLONE
; `@__cq_q_helper_1`, which carries only the artifact, must still lower.
;
; GREEN ON BOTH plugins by design, so absent from the differential; its power is
; arm-kill — drop the `use_empty()` test and it goes red.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The real address, intact — never the `i32 1` placeholder:
; CHECK: store ptr blockaddress(@helper, %then), ptr @slot
; The clone still gets lowered rather than declined:
; CHECK: define internal i32 @__cq_q_helper_1
;
; RUN: %filecheck %s --check-prefix=NOCORRUPT < %t.cqd0.ll
; NOCORRUPT-NOT: inttoptr (i32 1 to ptr)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

@slot = global ptr null

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %c1 = icmp sgt i32 %b, 5
  br i1 %c1, label %then, label %else
then:
  %a1 = add i32 %b, 1
  %d1 = add i32 %b, 2
  br label %merge
else:
  %a2 = add i32 %b, 3
  %d2 = add i32 %b, 4
  br label %merge
merge:
  %pa = phi i32 [ %a1, %then ], [ %a2, %else ]
  %pd = phi i32 [ %d1, %then ], [ %d2, %else ]
  %r  = xor i32 %pa, %pd
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %p = call i32 @cq_phi_si32(i32 %r, double 3.140000e+00)
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; The address is REALLY used, in a function the lowering never touches.
define void @cq_ba_holder() {
  store ptr blockaddress(@helper, %then), ptr @slot, align 8
  ret void
}
