; control_classical_call_arm_accept_onward_ctl_spec_replan.ll — ACCEPT (bd afmv, the
; CHAINED onward-control -> spec RE-PLAN; a CRITICAL silent-miscompile fix discovered by the
; 9paa Rule-13 workflow). TWO chained 6.5 classical-call arms: region 1 `if(q>5) y=f(a)`
; builds %out1 (a round-1 rail); region 2 `if(%out1>50) w=f(a)` (its condition reads %out1,
; CLASSICAL at round-1 detect) survives round-1 flattening and is lowered by yn71's
; `detectAndLowerOnwardControl` in round 2 to %out2 (a genuine i32 quantum rail). `gg(w,q)`
; is a ROUND-1 Phase-6 Pending candidate — it reads the theta handle `q`, so its mask was
; frozen 0b10 at `detectSpecializations` (step 127) while `w` (region-2 merge) was still
; data-untainted.
;
; THE MISCOMPILE (pre-afmv): `replanReseedSpecialization` re-planned only candidates reading
; the reseed set FROZEN before the yn71 control fixpoint, so the yn71-produced %out2 rail was
; not in it and `gg`'s stale 0b10 mask was never re-widened. `declineTaintEscapes` CARVED gg
; (shouldSpecialize=true, it is Pending) rather than declining it, so the step-262 driver
; cloned `@__cq_q_gg_10` with `cq_template_mul_i32_hl(q, %out2)` — reading the superposed
; %out2 rail's i32 HANDLE-TAG as a classical literal (`q * 7`, a verify-clean wrong unitary).
;
; THE FIX (afmv): the reseed set is computed AFTER `detectAndLowerOnwardControl` (so it
; includes the %out2 rails via the grown `UntaintedMergeRails`), and the re-plan/re-detect run
; against it — so gg's mask is re-widened 0b10 -> 0b11 and the driver clones `@__cq_q_gg_11`
; with a bare-QQ `cq_template_mul_i32` over TWO quantum handles (%out2 read as a HANDLE).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
; bd wve8 — DEFINED, not declared. The 6.5 arm HOISTS this call out of its
; quantum guard, so it now needs a TOTALITY proof as well as a purity one, and a
; visible pure body is what supplies it (`isSpeculatablePureCallee`). The old
; opaque `declare` carried no evidence of totality and now DECLINES — see
; control_classical_call_arm_reject_opaque_callee.ll (the crash it shipped) and
; control_classical_call_arm_reject_partial_callee.ll (a VISIBLE partial body,
; also declined). Nothing else in this fixture changes; the body is inert.
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
; the ROUND-1 Phase-6 candidate body (reads q -> round-1 Pending, mask 0b10).
define i32 @gg(i32 %a, i32 %b) {
entry:
  %s = mul i32 %a, %b
  ret i32 %s
}

define void @example(i32 %u0, i32 %aa) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %merge1
arm1:
  %r1 = call i32 @f(i32 %aa)
  br label %merge1
merge1:
  %out1 = phi i32 [ %r1, %arm1 ], [ 5, %entry ]   ; region-1 merge -> round-1 rail
  %c2 = icmp sgt i32 %out1, 50                     ; region-2 cond reads %out1 (classical @ round1)
  br i1 %c2, label %arm2, label %merge2
arm2:
  %r2 = call i32 @f(i32 %aa)
  br label %merge2
merge2:
  %out2 = phi i32 [ %r2, %arm2 ], [ 6, %merge1 ]   ; region-2 merge -> yn71 %out2 rail
  %z = call i32 @gg(i32 %out2, i32 %q)             ; round-1 Pending gg; 0b10 -> RE-WIDENED 0b11
  %m = call i32 @cq_measure_si32(i32 %z)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }

; The yn71 %out2 rail (built by controlled copies under the icmp(%out1,50) flag) is passed
; as gg's arg0 to the MASK-11 clone — a HANDLE, never an _hl literal.
; CHECK:     %[[OUT1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT1]], i32 50)
; CHECK:     %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_gg_11(i32 %[[OUT2]], i32 %[[H:[a-zA-Z0-9_.]+]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Z]])
;
; Clone: BOTH params quantum handles; mul lowers bare-QQ (NOT _hl — the miscompile is gone).
; CHECK:     define internal i32 @__cq_q_gg_11(i32 %a, i32 %b)
; CHECK:     call i32 @cq_template_mul_i32(i32 %a, i32 %b)
;
; The stale-mask _hl-over-the-rail miscompile is GONE, and the region accepts.
; CHECK-NOT: @__cq_q_gg_10
; CHECK-NOT: cq_template_mul_i32_hl
; ACC-NOT: under quantum control
; ACC-NOT: unknown callee
