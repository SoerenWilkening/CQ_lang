; lowering_uncompute_interior_leak_unrecorded_strip_reads_parent.ll — LEAK PROBE
; (bd test_C_libtooling-7xsh; the membership neighbour of
; control_nested_phase_inner_reads_chain_source.ll).
;
; bd 7xsh taught clause (d) of the M-B interior discharge (`borrowedParentsUnmoved`
; → `preservesBorrowedParent` row (4)) that an EMITTER-RECORDED flag strip reading
; the borrowed parent outside its slot-0 flag leaves the parent's label alone. The
; admission is MEMBERSHIP in `TaintSet::DischargedFlagGates`, never the `_unc`
; name — the spine's own adjoints, the 7.4 reverse-play and hand-written calls wear
; the same suffix. This file holds that line on the BORROWED-PARENT side (its
; sibling lowering_uncompute_interior_leak_unrecorded_strip.ll holds it on the
; owned-rail side, clause (c) of `isInteriorConsumer`).
;
; `%a = q*3` is an interior chain (`%a & 20` feeds a measured sum) whose window
; [the mul, the `and`] contains a HAND-WRITTEN, unrecorded
; `cq_template_icmp_slt_i32_hl_unc(%z, %q, 9)` reading the borrowed parent `%q` in
; slot 1. Clause (d) refuses it, and the `%a` chain is LEFT ALLOCATED (Rule 6),
; never adjointed or freed — MEASURED: deleting the hand-written call discharges
; it (`mul_i32_hl_unc(%a, %q, 3)` + `cqrt_free`), so the call is the only refusal.
;
; DISCRIMINATION: `%b = q*7` is minted AFTER the hand-written call, so its window
; does not contain it, and it IS discharged in the same function — the NOFREEA
; negatives do not pass because the partition is inert.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEA < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

define i32 @leak_unrecorded_reader(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a  = mul i32 %q, 3                      ; interior chain; window opens here
  %c  = icmp slt i32 %q, 9
  %z  = zext i1 %c to i32
  ; an UNRECORDED `_unc` reading the borrowed parent %q INSIDE %a's window
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %z, i32 %q, i32 9)
  %ak = and i32 %a, 20                     ; %a's last reader; window closes here
  %b  = mul i32 %q, 7                      ; the discriminating chain, minted after
  %bk = and i32 %b, 12
  %s  = add i32 %ak, %bk
  %m  = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m
}

; CHECK-LABEL: define i32 @leak_unrecorded_reader(
; CHECK:       %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK-NEXT:  %[[BK:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[B]], i32 12)
; the discrimination — the chain minted after the call IS discharged:
; CHECK:       call void @cq_template_and_i32_hl_unc(i32 %[[BK]], i32 %[[B]], i32 12)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[BK]])
; CHECK-NEXT:  call void @cq_template_mul_i32_hl_unc(i32 %[[B]], i32 %{{[a-zA-Z0-9_.]+}}, i32 7)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[B]])

; …and the chain whose window holds the unrecorded reader is never adjointed and
; never freed (window = its mint -> EOF):
; NOFREEA:     %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; NOFREEA-NOT: @cq_template_mul_i32_hl_unc(i32 %[[A]],
; NOFREEA-NOT: call void @cqrt_free(i32 %[[A]])
