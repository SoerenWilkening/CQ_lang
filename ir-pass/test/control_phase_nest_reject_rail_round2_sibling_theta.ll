; control_phase_nest_reject_rail_round2_sibling_theta.ll — DECLINE (bd
; test_C_libtooling-r9e5 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1 — THE 4.3 NEST
; CONSUMER). The round-2 taint window reached through the depth-2 homogeneous
; phase nest: `%y` is the 6.5 classical-call-arm `%out`, `%x = trunc %y` is
; CLASSICAL when the ladder is asked (round-1 taint) and TAINTED when
; `lowerRotations` decides chained-vs-source, so the OUTER level's condition `%b`
; and its SIBLING `%b3` ride ONE rail.
;
; ⚠ THE OUTER ARM CARRIES NO PHASE GATES, WHICH IS THE POINT: the only read of
; the user's register is then the CONJUNCTION toffoli, emitted by
; `SwapRouteEmit`'s direct `emitCondNode(Conj, …)` call and NOT by
; `emitCondNetwork`'s node loop. The first spelling of the fix recorded rail
; reads in that loop and would have missed this site entirely — with no
; diagnostic anywhere, the `markBranchPhaseGate` failure mode one epic later.
; The recording therefore lives inside `emitCondNode`, which is the ONE function
; both callers go through (probe `w5`).
;
; RED ON f8d29e8 (the round-1-fix checkpoint): rc=0, verify-clean, STRICT stage
; 2b `3 verified, 0 violation(s)`, emitting
;
;   call void @cqrt_ry_i1(i32 %h_cast, double 5.000000e-01)   <- %b
;   call void @cqrt_ry_i1(i32 %h_cast, double 9.000000e-01)   <- %b3, SAME RAIL
;   %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 7)
;   %g = call i32 @cqrt_alloc_i1(i1 false)
;   call void @cqrt_toffoli(i32 %h_cast, i32 %h_cmp2, i32 %g)  <- the read
;   call void @cqrt_rz_i1(i32 %g, double 0x3FE6666666666666), !cq.branchphase
;
; — the conjunction (and therefore the inner arm's phase) controlled on
; `Ry(0.9)Ry(0.5)|x>` while the outer branch condition names `Ry(0.5)|x>`.
;
; The ACCEPT twin — this module with `%b3` deleted — is
; `control_phase_nest_rail_round2_window_accept.ll`, byte-identical on both
; binaries.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @f(i32 %a) #0 { %s = add i32 %a, 100  ret i32 %s }
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 3
  br i1 %c0, label %arm, label %merge
arm:
  %r = call i32 @f(i32 4)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = call i32 @cq_measure_si32(i32 %y)
  br label %second
second:
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  br i1 %b, label %mid, label %join
mid:
  %ci = icmp sgt i32 %q, 7
  br i1 %ci, label %inner, label %join
inner:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %t = add i32 %zz, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
