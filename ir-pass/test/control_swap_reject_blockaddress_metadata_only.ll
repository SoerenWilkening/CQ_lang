; control_swap_reject_blockaddress_metadata_only.ll — DECLINE (bd 7udx).
; ARM: the `isUsedByMetadata()` half of the observability test in
; `declineAddressTakenBlocks`, and the only row that pins it.
;
; *** `use_empty()` ALONE IS THE WRONG QUESTION, and the Rule-13 delta round said so
; before this was measured. *** The guard skips a block whose `BlockAddress` has no
; users, on the stated invariant that "nothing can observe the erase". A
; `BlockAddress` referenced ONLY FROM METADATA has no Uses at all — and the erase
; rewrites that reference anyway.
;
; MEASURED, and it settles a point the round left open. The delta lens reported this
; as a scope gap it could NOT turn into an executable divergence, and downgraded it to
; a style finding. On the pre-change plugin this module lowers (`opt` exit 0) and the
; metadata node comes out as
;
;   !0 = !{ptr inttoptr (i32 1 to ptr)}
;
; so the IR-level corruption is real and demonstrable even though no runtime semantics
; attach to a metadata reference. That is enough: the source is well-defined, the
; emitted module says something different from what the source said, and a consumer of
; that metadata would read address 1. The clause stays.
;
; This is the ONLY fixture that can pin it. Every other blockaddress row carries a real
; Use (a `store`, a `ptrtoint` in a compare, a global initializer), so `use_empty()` is
; already false there and removing the metadata clause leaves them all green — an
; earlier draft of the arm-kill driver aimed the D8 arm at
; control_swap_reject_blockaddress_diamond_arm.ll and would have reported a
; MISMATCH-free pass while pinning nothing.
;
; It cannot re-open the over-decline the use-test fixed: `CloneFunctionInto`'s
; VMap-only `BlockAddress` is neither used NOR metadata-referenced, which
; spec_accept_blockaddress_clone_artifact.ll keeps green.
;
; RED-GREEN: the pre-change plugin ACCEPTS this module and emits the corrupted node.
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

; NO instruction and NO global initializer references the address — the ONLY
; reference is the metadata node below, which is not a Use.
!cq.ba = !{!0}
!0 = !{ptr blockaddress(@example, %arm)}
