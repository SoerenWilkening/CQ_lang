; control_inplace_ry_alias_after_region.ll — ACCEPT spec: a diagonal alias minted
; AFTER the region, off the MERGE φ (control-in-place-PRD §4 R6; bd
; test_C_libtooling-drbq Inc 1, finding J's second positive control).
;
;     if (q > 5) r = cq_theta(r, .9);
;     int mark = cq_phi(r, .1);            // `r` here is the POST-region name
;     use(cq_measure(mark));
;
; The mirror image of ..._reject_stale_diag_alias_forward.ll, and the reason R6
; is a POSITION rule and not an alias BAN: this alias hangs off the merge φ, which
; the emitter RAUWs to the base, so it reads the register AFTER the controlled Ry
; relabelled it — exactly what the source means. The φ is deliberately NOT a
; member of the wire closure (the forward walk crosses `cq_phi`/`cq_theta`/in-place
; `add`/`sub`/`xor` users and NOTHING else), so its descendants are never asked the
; staleness question at all.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm   = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %mark = call i32 @cq_phi_si32(i32 %rm, double 1.000000e-01)
  %d    = call i32 @cq_measure_si32(i32 %mark)
  ret i32 %d
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; the alias is minted AFTER the gate, on the register the gate relabelled
; CHECK:      call void @cqrt_rz_i32(i32 %[[R]], double 1.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NOT:  cqrt_cswap
; CHECK-NOT:  phi i32
