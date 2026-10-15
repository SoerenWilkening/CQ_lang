; control_phase_nest_rail_round2_window_accept.ll — ACCEPT (bd
; test_C_libtooling-r9e5 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1's NEST-side
; DISCRIMINATOR). `control_phase_nest_reject_rail_round2_sibling_theta.ll` with
; the SIBLING theta deleted and nothing else changed: the outer level's condition
; is still the 6.5 `%out`-derived rail that only ROUND 2 taints — the same window
; — but nothing else touches the register, so the nest is correct and must keep
; lowering.
;
; GREEN ON BOTH BINARIES, lowered modules BYTE-IDENTICAL (measured with `diff` on
; the two `-S` outputs). The stream is the shipped rail nest: the register read
; ONLY as a `cqrt_toffoli` control (never a `cqrt_x` on it, never a free of it),
; the inner arm's phase on the conjunction ancilla `%g`, and the exact LIFO
; teardown — second toffoli, `cqrt_free(%g)`, then the inner leaf's `_unc` strip
; and its free.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.ll
; RUN: %filecheck %s --check-prefix=TFCNT < %t.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.ll

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
  br i1 %b, label %mid, label %join
mid:
  %ci = icmp sgt i32 %q, 7
  br i1 %ci, label %inner, label %join
inner:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mm = call i1 @cq_measure_i1(i1 %b)
  %zz = zext i1 %mm to i32
  %t = add i32 %zz, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }

; ORD: %h_cast = call i32 @cq_template_trunc_i32_to_i1(i32 %out)
; ORD-NEXT: call void @cqrt_ry_i1(i32 %h_cast, double 5.000000e-01)
; ORD-NEXT: %[[HC2:h_cmp[0-9]*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 7)
; ORD-NEXT: %g = call i32 @cqrt_alloc_i1(i1 false)
; ORD-NEXT: call void @cqrt_toffoli(i32 %h_cast, i32 %[[HC2]], i32 %g)
; ORD-NEXT: call void @cqrt_rz_i1(i32 %g, double 0x3FE6666666666666), !cq.branchphase
; ORD-NEXT: call void @cqrt_toffoli(i32 %h_cast, i32 %[[HC2]], i32 %g)
; ORD-NEXT: call void @cqrt_free(i32 %g)

; EXACTLY ONE rotation on the register and EXACTLY TWO conjunction gates
; (forward + its self-inverse undo), whole file.
; RYCNT-COUNT-1: call void @cqrt_ry_i1(
; RYCNT-NOT: call void @cqrt_ry_i1(
; TFCNT-COUNT-2: call void @cqrt_toffoli(
; TFCNT-NOT: call void @cqrt_toffoli(

; Nothing non-diagonal and nothing freed on the user's register.
; NOX-NOT: call void @cqrt_x(i32 %h_cast)
; NOX-NOT: call void @cqrt_free(i32 %h_cast)
; NOX-NOT: @cqrt_cswap
; NOX-NOT: call i1 @cq_theta
