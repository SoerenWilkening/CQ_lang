; control_classical_call_arm_accept_speculatable_decl.ll — ACCEPT via LLVM's own
; totality answer (bd wve8): an OPAQUE declaration is admitted by the 6.5
; classical-call arm if and only if it carries `speculatable`.
;
; This module is control_classical_call_arm_reject_opaque_callee.ll with
; `speculatable` ADDED to attribute group #0 and NOTHING ELSE changed. That file
; DECLINES; this one lowers. The pair is the arm-kill for the totality gate: it
; isolates the one token that answers "may this call be executed on a path the
; source did not take", and proves the decline over there is not about opacity,
; the diamond shape, the argument, or purity.
;
; WHY `speculatable` IS THE RIGHT TOKEN AND NOTHING WEAKER IS. LangRef: "indicates
; that the function does not have any effects besides calculating its result and
; does not have undefined behavior ... If the function is incorrectly marked as
; speculatable and really does exhibit undefined behavior, the undefined behavior
; may be observed even if the call site is dead code." LLVM's own
; `isSafeToSpeculativelyExecute` demands exactly this attribute for a call, over
; the comment "the called function could have undefined behavior or side-effects,
; even if marked readnone nounwind" — which is bd wve8's finding in LLVM's words.
;
; REACH, STATED HONESTLY: C has NO spelling for `speculatable`
; (`__attribute__((const))` grants only `memory(none) nounwind willreturn`), so
; this row has ZERO population in any CQ corpus and is expected to keep it. It is
; here because it is the correct standard and because naming it is what stops a
; future reader from concluding CQ invented one. The row with real reach is the
; VISIBLE-BODY proof (`isSpeculatablePureCallee`) — every one of the twelve 6.5
; accept sites in the e2e layer is body-proved, not attribute-proved.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @spec_f(i32) #0

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @spec_f(i32 0)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) speculatable }

; the full §5a controlled-XOR copy merge stream, with the call hoisted ahead of
; the flag mint:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 0.000000e+00)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @spec_f(i32 0)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[RH]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; clone-orthogonal, and no surviving diamond:
; CHECK-NOT: @__cq_q_
; CHECK-NOT: phi i32
; ACC-NOT: under quantum control
