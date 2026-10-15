; control_angle_select_ry_nested_mux.ll — ACCEPT (bd test_C_libtooling-dm7f.54,
; item E; reporter t4.c line 3, CQ_FINDINGS F4):
;
;     c = q0 + q1;  cq_theta(&q2, c == 0 ? 0.1 : (c == 1 ? 0.2 : 0.4));
;
; `-O1` rewrites the inner `c == 1` (given `c != 0`) as `q0 ^ q1` and keeps the
; nested SELECT form (this body is t4's stage-1 IR, minimised). Each select is a
; member of ONE angle mux (`collectAngleMux` / `angleMuxRoot`); the root region
; mints a flag per member and gives every LEAF angle exactly one controlled gate
; through a PATH PREDICATE ancilla (Bennett.jl `_and_wire!`, src/lowering/
; phi.jl:4), the per-level X-bracket form of the owner ruling:
;   f = (c == 0); ry_c(f, t, .1); x(f)
;   g = q0 ⊕ q1; p = toffoli(f, g); ry_c(p, t, .2); undo p
;   x(g); p = toffoli(f, g); ry_c(p, t, .4); undo p; x(g); free(p); strip g
;   x(f); strip f
; ANALYTIC: c == 0 -> Ry(.1); c != 0 ∧ q0⊕q1 (c == 1) -> Ry(.2); c != 0 ∧
; ¬(q0⊕q1) (c == 2) -> Ry(.4) — the source's three cases, on a fresh |0> target.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q0 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  %q1 = call i1 @cq_theta_i1(i1 false, double 5.000000e-01) #0
  %z0 = zext i1 %q0 to i32
  %z1 = zext i1 %q1 to i32
  %c = add nuw nsw i32 %z1, %z0
  %c0 = icmp eq i32 %c, 0
  %x = xor i1 %q0, %q1
  %in = select i1 %x, double 2.000000e-01, double 4.000000e-01
  %ang = select i1 %c0, double 1.000000e-01, double %in
  %t = call i1 @cq_theta_i1(i1 false, double %ang) #0
  %mt = call i1 @cq_measure_i1(i1 %t)
  %mc = call i32 @cq_measure_si32(i32 %c)
  %zt = zext i1 %mt to i32
  %s = add i32 %zt, %mc
  ret i32 %s
}

attributes #0 = { nomerge nounwind }

; CHECK:      %[[Q0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[Q1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[C]], i32 0)
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %[[T]], double 1.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[Q0]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[Q1]], i32 %[[G]])
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F]], i32 %[[G]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[P]], i32 %[[T]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F]], i32 %[[G]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F]], i32 %[[G]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[P]], i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F]], i32 %[[G]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[P]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[Q1]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[Q0]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[C]], i32 0)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; NEG-NOT: = select
; NEG-NOT: cq_theta_
