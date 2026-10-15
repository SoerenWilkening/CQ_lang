; control_predmux_accept_i1phi_cond_fp.ll — ACCEPT (3c6m.14 L6 Inc 2): the
; tanh/expm1 argument-reduction idiom in miniature — fcmp conditions, an i1
; phi at an internal merge feeding the CONDITION of an fp constant-data select
; (`(xsb==0) ? 0.5 : -0.5`), whose result flows through fp arithmetic into a
; post-merge fptosi. The i1 phi converts to boolean algebra (∨ᵢ EP(eᵢ)∧vᵢ) so
; the select condition stays an and/or-over-fcmp-leaves tree (kjd1 fcmp flag
; mints); the fp data merge rides the kjd1 controlled-copy family.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare i64 @cq_measure_sl(i64)

define i64 @probe(double %u0) {
entry:
  %q  = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c1 = fcmp ogt double %q, 1.000000e+00
  br i1 %c1, label %inner, label %merge
inner:
  %c2 = fcmp olt double %q, 4.000000e+00
  br i1 %c2, label %ia, label %ib
ia:
  %ca = fcmp oeq double %q, 2.000000e+00
  br label %ijoin
ib:
  %cb = fcmp ogt double %q, 8.000000e+00
  br label %ijoin
ijoin:
  %flag = phi i1 [ %ca, %ia ], [ %cb, %ib ]
  %half = select i1 %flag, double 5.000000e-01, double -5.000000e-01
  %s  = fadd double %q, %half
  %k  = fptosi double %s to i64
  br label %merge
merge:
  %rm = phi i64 [ %k, %ijoin ], [ 0, %entry ]
  %m  = call i64 @cq_measure_sl(i64 %rm)
  ret i64 %m
}

; %flag = or(and(c1∧c2, ca), and(c1∧¬c2, cb)); ¬c2 = NaN-correct uge:
; CHECK: %u0.stable = freeze double %u0
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0.stable)
; CHECK-DAG: call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 1.000000e+00)
; CHECK-DAG: call i32 @cq_template_fcmp_olt_f64_hl(i32 %[[Q]], double 4.000000e+00)
; CHECK-DAG: call i32 @cq_template_fcmp_oeq_f64_hl(i32 %[[Q]], double 2.000000e+00)
; CHECK-DAG: call i32 @cq_template_fcmp_uge_f64_hl(i32 %[[Q]], double 4.000000e+00)
; CHECK-DAG: call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 8.000000e+00)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_xorc_f64_controlled(
; CHECK:     call i32 @cq_template_fptosi_f64_to_i64(
; CHECK:     call i64 @cqrt_measure_i64(
; CHECK-NOT: br i1
; CHECK-NOT: phi i64
; CHECK-NOT: phi i1
; CHECK-NOT: select i1
