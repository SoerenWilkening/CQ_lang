; control_angle_select_ry_nested_mux_both_arms.ll — ACCEPT (bd test_C_libtooling-dm7f.54,
; item E): a NESTED angle mux with an inner member in EACH arm, one of them under
; a compound (logical-and) condition, on a fresh target.
;
;     t = a ? (b ? .1 : .2) : ((b && c) ? .3 : .4)        (select form)
;
; (`-O1` turns this C spelling into a branch with an angle φ, a separate shape
; that still declines and is filed; this module is the select form `-O1`
; produces for a right-nested ternary, the reporter's t4 line 3.)
;
; THE STREAM (each leaf angle in exactly ONE controlled gate):
;   fa = cnot-copy(a)
;   [a = 1]  fb = cnot-copy(b); p = |0>; toffoli(fa, fb, p); ry_c(p, t, .1);
;            toffoli(fa, fb, p); x(fb); toffoli(fa, fb, p); ry_c(p, t, .2);
;            toffoli(fa, fb, p); x(fb); free(p); un-copy fb
;   x(fa)
;   [a = 0]  g = toffoli(b, c); p' = |0>; toffoli(fa, g, p'); ry_c(p', t, .3); ...
;            x(g) ... ry_c(p', t, .4) ...; free(p'); toffoli(b, c, g); free(g)
;   x(fa); un-copy fa
; ANALYTIC: p = a ∧ b -> .1; a ∧ ¬b -> .2; ¬a ∧ (b ∧ c) -> .3; ¬a ∧ ¬(b ∧ c)
; -> .4: the four path predicates partition the basis, each ancilla returns to
; |0> through its own toffoli pair (its controls are unchanged in between), and
; every free is proven-|0>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @example() {
entry:
  %a = call i1 @cq_theta_i1(i1 false, double 1.000000e+00) #0
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01) #0
  %c = call i1 @cq_theta_i1(i1 false, double 6.000000e-01) #0
  %s1 = select i1 %b, double 1.000000e-01, double 2.000000e-01
  %bc = select i1 %b, i1 %c, i1 false
  %s2 = select i1 %bc, double 3.000000e-01, double 4.000000e-01
  %ang = select i1 %a, double %s1, double %s2
  %t = call i1 @cq_theta_i1(i1 false, double %ang) #0
  %ma = call i1 @cq_measure_i1(i1 %a)
  %mt = call i1 @cq_measure_i1(i1 %t)
  %za = zext i1 %ma to i32
  %zt = zext i1 %mt to i32
  %s = add i32 %za, %zt
  ret i32 %s
}

attributes #0 = { nomerge nounwind }

; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[A]], double 1.000000e+00)
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[B]], double 5.000000e-01)
; CHECK-NEXT: %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[C]], double 6.000000e-01)
; CHECK-NEXT: %[[FA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[FA]])
; CHECK-NEXT: %[[FB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[B]], i32 %[[FB]])
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[P]])
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[P]], i32 %[[T]], double 1.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FB]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[P]], i32 %[[T]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FB]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[P]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[B]], i32 %[[FB]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[FB]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FA]])
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[B]], i32 %[[C]], i32 %[[G]])
; CHECK-NEXT: %[[P2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[G]], i32 %[[P2]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[P2]], i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[G]], i32 %[[P2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[G]], i32 %[[P2]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[P2]], i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[G]], i32 %[[P2]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[P2]])
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[B]], i32 %[[C]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[FA]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[A]], i32 %[[FA]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[FA]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[A]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[T]])

; NEG-NOT: = select
; NEG-NOT: cq_theta_
