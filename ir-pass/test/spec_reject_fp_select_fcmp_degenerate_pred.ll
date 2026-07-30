; spec_reject_fp_select_fcmp_degenerate_pred.ll — DECLINE (bd tkmn Inc 1 decline
; matrix). The widening admits the 14 fcmp predicates the YAML `fcmp` predicate
; set ships; LLVM's other two — the degenerate always-true `fcmp true` and
; always-false `fcmp false`, which perform no comparison — are deliberately OUT
; (OpcodeSupport.cpp::compareInScope), so no template exists and the shape must
; loud-decline rather than `getOrInsertFunction` a phantom
; `cq_template_fcmp_true_f64_hl` symbol.
;
; WHICH GATE FIRES (measured): the `scanBody` DATA-OP whitelist rejects the
; `fcmp true` INSTRUCTION ("unsupported compare predicate") before
; `isLiftableFpSelect`'s own `comparePredLowerable` clause is consulted — the
; condition compare is an instruction in the body, so the data-op gate reaches it
; first. Both gates route through the SAME `compareInScope` policy (Rule 14), so
; they cannot drift apart into disagreement.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported compare predicate)
; CHECK-NOT: cqrt_copy_f64_controlled
; CHECK-NOT: cq_template_fcmp_true
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @mhelper(i32 %n) {
  %x = sitofp i32 %n to double
  %c = fcmp true double %x, 0.000000e+00
  %a = select i1 %c, double 1.000000e+00, double %x
  %r = fptosi double %a to i32
  ret i32 %r
}
define void @example(i32 %u0) {
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @mhelper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
