; control_inplace_ry_crossblock_cond_inplace_add_after_loop.ll — ACCEPT, and it is the
; COMPANION of `control_inplace_ry_crossblock_cond_outofplace_add_in_gap.ll` (bd
; `test_C_libtooling-drbq.12`, 2026-09-17). The pair exists because either file alone
; would let a reader draw the wrong conclusion about the dtzb axis.
;
; Here the LICM-hoisted loop-invariant compare `%3 = icmp eq i32 %1, 5` sits in the
; entry block, the in-place-Ry arm is inside the ROLLED loop, and
;
;     %u = add nsw i32 %1, 1        ; in the EXIT block — AFTER the whole region
;
; acts on the condition's own register. It is the same instruction the companion has
; in the gap, moved past the loop.
;
; ⚠ HERE IT DOES CONVERT IN PLACE: the lowered module contains
; `call void @cqrt_addc_i32(i32 %h, i32 1)` — M-C's in-place ABI, permuting `%h`'s
; own rail. Check that literally below. **So the discriminator is not the opcode and
; not the rail: it is POSITION relative to the emitted stream.** In the gap the
; region's mint/strip/controlled gate are later uses of `%h` and G6 refuses in place
; (the companion measures that); here nothing of the region follows the add, G6
; admits it, and the permutation happens after every mint the source describes — the
; ordinary post-region gate case.
;
; ⚠ READ THE PAIR BEFORE CONCLUDING ANYTHING ABOUT THE dtzb GAP. "The add always
; lowers out of place" is FALSE (this file), and "an in-place add on the condition
; rail is a miscompile" is FALSE too (this file is correct). The true statement is
; the ORDER interlock: control emission runs BEFORE `lowerOps`, so an in-place
; candidate INSIDE the gap is exactly a candidate M-C refuses.
;
; RETIREMENT TRIGGER, shared with the companion and with
; `railCondWireDisposition`'s header: the day M-C's G6 admits an in-place op on a
; rail with a later read, re-derive BOTH files — the companion becomes an
; over-accept, and this one stops being the contrast that explains it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTADD %s < %t.cqd0.ll
; ---- MUTATION-MATRIX HARDENING (bd `test_C_libtooling-drbq.12`, 2026-09-17) ----
; Rule 12(c): a fixture is validated by MUTATION, not by re-reading its prefixes.
; The first injection-matrix run over this batch reported 21 MISSED over 9 accept
; fixtures — a stray `cqrt_ry` before the `ret`, a duplicated mint, a duplicated
; free, and a `cqrt_x` injected onto the USER REGISTER all slipped through, because
; no whole-file prefix counted those symbols here. The block below is the closure:
; an EXACT count per symbol (a `COUNT-n` followed by its own `-NOT`, which is what
; turns "at least n" into "exactly n"), ONE PREFIX PER SYMBOL because consecutive
; `COUNT`s under a shared prefix scan FORWARD and fall through to the trailing
; `declare` lines, and a pure-negative prefix for the two gates that must never
; appear. Counts are MEASURED off this fixture's own lowered output, never guessed.
; RUN: %filecheck --check-prefix=MXALLOC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRY %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRYC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXADDC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMEAS %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXNONE --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" --implicit-check-not="call void @cqrt_cnot(" %s < %t.cqd0.ll

; MXALLOC-COUNT-2: = call i32 @cqrt_alloc_
; MXALLOC-NOT: = call i32 @cqrt_alloc_
; MXRY-COUNT-2: call void @cqrt_ry_i32(
; MXRY-NOT: call void @cqrt_ry_i32(
; MXRYC-COUNT-1: call void @cqrt_ry_i32_controlled(
; MXRYC-NOT: call void @cqrt_ry_i32_controlled(
; MXMINT-COUNT-1: = call i32 @cq_template_icmp_
; MXMINT-NOT: = call i32 @cq_template_icmp_
; MXSTRIP-COUNT-1: call void @cq_template_icmp_
; MXSTRIP-NOT: call void @cq_template_icmp_
; MXFREE-COUNT-1: call void @cqrt_free(
; MXFREE-NOT: call void @cqrt_free(
; MXADDC-COUNT-1: call void @cqrt_addc_
; MXADDC-NOT: call void @cqrt_addc_
; MXMEAS-COUNT-2: = call i32 @cqrt_measure_
; MXMEAS-NOT: = call i32 @cqrt_measure_
; MXNONE-NOT: call{{.*}}@cq_theta_
; MXNONE-NOT: call{{.*}}@cq_measure_si32
; MXNONE-NOT: call{{.*}}@cq_phi


; ⚠ TEXTUAL BLOCK ORDER, NOT EXECUTION ORDER: `RegionFlatten` leaves the EXIT block
; printed above the header, so the in-place add appears before the loop body in the
; module text while running after it.
; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; THE PROPERTY: an IN-PLACE add, on the condition's own rail, after the region.
; CHECK: call void @cqrt_addc_i32(i32 %[[H]], i32 1)
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[F]])

; Exactly one in-place add, and no out-of-place twin beside it.
; CNTADD-COUNT-1: call void @cqrt_addc_i32(
; CNTADD-NOT: call void @cqrt_addc_i32(
; CNTADD-NOT: call i32 @cq_template_add_i32_hl(

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  br label %hdr

exit:                                             ; preds = %latch
  %u = add nsw i32 %1, 1
  %m1 = tail call i32 @cq_measure_si32(i32 noundef %merge) #2
  %m2 = tail call i32 @cq_measure_si32(i32 noundef %u) #2
  %sum = add nsw i32 %m2, %m1
  ret i32 %sum

hdr:                                              ; preds = %0, %latch
  %ivphi = phi i32 [ 0, %0 ], [ %ivnext, %latch ]
  %rphi = phi i32 [ %2, %0 ], [ %merge, %latch ]
  br i1 %3, label %arm, label %latch

arm:                                              ; preds = %hdr
  %armt = tail call i32 @cq_theta_si32(i32 noundef %rphi, double noundef 9.000000e-01) #2
  br label %latch

latch:                                            ; preds = %arm, %hdr
  %merge = phi i32 [ %armt, %arm ], [ %rphi, %hdr ]
  %ivnext = add nuw nsw i32 %ivphi, 1
  %exitc = icmp eq i32 %ivphi, 0
  br i1 %exitc, label %hdr, label %exit, !llvm.loop !6
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }

!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
