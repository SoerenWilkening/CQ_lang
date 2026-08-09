; lowering_fp80_reject_blockaddress_unreachable.ll — DECLINE (bd 7udx).
; ARM: `removeUnreachableBlocksChecked`, the `Fp80Union` call site — the ONE erase
; site whose doomed set is never NAMED by its caller.
;
; *** THE FIRST BODY OF THIS FIXTURE DID NOT PIN THIS SITE. *** It used an fp80-union
; multiblock shape, and the Rule-13 round's arm-kill showed that deleting the
; `Fp80Union` guard call left the fixture GREEN — some other site's guard was
; satisfying it, so the row proved nothing about the site its own header named. The
; body below is the round's replacement probe, MEASURED to reach: with the guard call
; deleted this fixture is the one that goes red.
;
; What makes it reach is that the ONLY block erasure in the module happens here.
; `br i1 false` is a CLASSICAL constant-foldable branch, so `ConstantFoldTerminator`
; drops the dead edge and `%dead` — whose address is taken — is reaped by
; `removeUnreachableBlocks`, not by any region flatten. The quantum diamond below it
; (`%live`/`%arm`/`%merge`) lowers normally and its blocks are not address-taken, so
; no other guard site can fire first.
;
; Reached from BOTH `promoteFp80Union` and `foldConstantConesInFunction`, and PredMux
; calls the latter after EVERY flatten — so despite the file name this is not an
; fp80-only path.
;
; MEASURED on the pre-change plugin: `opt` exit 0, and the holder's store emerges as
; `store ptr inttoptr (i32 1 to ptr), ptr @cq_ba_slot` on a WELL-DEFINED source.
;
; The `markAliveBlocks` variant of this same site — where the deletion set is a
; strict superset of plain reachability — is
; lowering_fp80_reject_blockaddress_markalive.ll, with its own accept control. This
; row pins that the site is guarded AT ALL; that row pins that the guard OBSERVES
; the deletion set rather than predicting it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq literal integrity: address-taken block erased under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 false, label %dead, label %live          ; CLASSICAL constant-foldable

dead:                                            ; address-taken, becomes unreachable
  br label %live

live:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %live ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

@cq_ba_slot = global ptr null

define void @cq_ba_holder() {
  store ptr blockaddress(@example, %dead), ptr @cq_ba_slot, align 8
  ret void
}
