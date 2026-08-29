; lowering_uncompute_interior_leak_unrecorded_strip.ll — LEAK PROBE (M-B
; Increment 6, clause (d2)). THE ADMISSION IS MEMBERSHIP IN AN EMITTER-RECORDED
; SET, NEVER A NAME TEST — and this is the fixture that says so.
;
; `%a` has exactly the user profile clause (d2) admits: one forward template
; producer, and one `cq_template_*_unc` reading it in a shifted handle slot. The
; difference is that this `_unc` was HAND-WRITTEN into the input, so no control
; emitter recorded it in `TaintSet::DischargedFlagGates`. The rail is refused and
; left allocated.
;
; WHY THAT REFUSAL IS THE WHOLE FENCE. `_unc` is also the suffix of the Phase-5
; uncompute spine's own adjoints, of the 7.4 loop reverse-play, and of the
; Phase-4 value arm's method-B `emitInverseChain`. Those calls WRITE the rail in
; their slot 0 and read their operands as part of a reversal another owner is
; still executing; counting one of them as "a consumer that has finished with the
; rail" would let this partition discharge and FREE a register another
; partition's adjoint still reads — Rule 8's shared-prefix hazard, arriving from
; the other side. `isInteriorConsumer` therefore asks the plan, not the name, and
; `isUncHandleSlot` additionally refuses slot 0 (the written rail) so that even a
; recorded strip cannot launder its own flag into this partition.
;
; DISCRIMINATION: `%b`, whose only user is an ordinary forward producer, IS
; discharged in the same function — so the CHECK-NOTs below are not passing
; because the partition is inert.
;
; The `%a` side deliberately has NO measurement downstream of it. With one, the
; hand-written `_unc`'s out-slot rail becomes a dead terminal whose lineage is
; measured and the whole-DAG spine declines first
; ("cq uncompute: dead chain would free a measured register"), which would mask
; the clause this file exists to pin.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEA < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

define i32 @leak_unrecorded_strip(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  ; the REFUSED rail: forward producer + a hand-written, unrecorded `_unc`
  %a  = mul i32 %q, 3
  %ac = icmp slt i32 %a, 10
  %az = zext i1 %ac to i32
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %az, i32 %a, i32 10)
  ; the DISCRIMINATING rail: an ordinary interior chain on the same wire
  %b  = mul i32 %q, 7
  %bk = and i32 %b, 20
  %m2 = call i32 @cq_measure_si32(i32 %bk)
  ret i32 %m2
}

; CHECK-LABEL: define i32 @leak_unrecorded_strip(
; CHECK:      %[[A:.*]] = call i32 @cq_template_mul_i32_hl(i32 %{{.*}}, i32 3)
; CHECK:      %[[B:.*]] = call i32 @cq_template_mul_i32_hl(i32 %{{.*}}, i32 7)
; CHECK-NEXT: %[[BK:.*]] = call i32 @cq_template_and_i32_hl(i32 %[[B]], i32 20)
; the discrimination — the ordinary chain rail IS discharged:
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[B]], i32 %{{.*}}, i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])

; …and the rail read by the UNRECORDED `_unc` is never adjointed and never freed
; (window = the mul -> EOF, bd memory [filecheck-check-not-window-trap]):
; NOFREEA:     %[[A2:.*]] = call i32 @cq_template_mul_i32_hl(i32 %{{.*}}, i32 3)
; NOFREEA-NOT: @cq_template_mul_i32_hl_unc(i32 %[[A2]],
; NOFREEA-NOT: call void @cqrt_free(i32 %[[A2]])
