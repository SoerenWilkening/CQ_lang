; control_swap_reject_select_rail_alias_cond.ll — DECLINE (bd 7q3s). THE fixture
; the first four missed, and the reason this fence tests RAIL identity rather than
; SSA identity.
;
; The two condition operands are SSA-DISTINCT — `%q` and `%r = cq_phi(%q, .25)` —
; so InstCombine cannot fold the compare, unlike the `x == x` idiom. But `cq_phi`
; (Rz) is an IN-PLACE gate whose result RAUWs to its argument's i32 handle, so
; AFTER RotationLowering both operands ARE one rail. Pre-fence this lowered at
; EXIT 0 emitting
;     %h_cmp = call i32 @cq_template_icmp_slt_i32(i32 %h, i32 %h)
;     call void @cq_template_icmp_slt_i32_unc(i32 %h_cmp, i32 %h, i32 %h)
; — one rail in both slots of a two-register comparator, frozen into a golden.
;
; WHY IT MATTERS MORE THAN THE SSA FORM: this is reachable from FOUR LINES of
; ordinary C at the plain -O1 ship floor —
;     q = cq_theta(u,.5);  r = cq_phi(q,.25);  s = (q < r) ? 11 : 22;
; — whereas the SSA-identical form is non-canonical and appears nowhere in the
; corpus. The first draft of this fence tested `getOperand(0) == getOperand(1)`
; and justified itself with a corpus scan that, by construction, could only ever
; see the SSA form. The scan was correct and the conclusion did not follow.
;
; The `if (q < r) s = 11;` form lowers to this same select via -O1 if-conversion,
; so this fixture covers that route too.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control
; The hazard, stated so a mutant that reintroduces it cannot pass:
; CHECK-NOT: cq_template_icmp_{{[a-z]+}}_i32(i32 %h, i32 %h)
; CHECK-NOT: cqrt_copy_i32_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_phi_si32(i32 %q, double 2.500000e-01)  ; in-place Rz: SAME rail
  %c = icmp slt i32 %q, %r                                 ; SSA-distinct, one rail
  %s = select i1 %c, i32 11, i32 22
  %m = call i32 @cq_measure_si32(i32 %s)
  ret void
}
