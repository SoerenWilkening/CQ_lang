; control_swap_value_accept_nonclobber.ll — ACCEPT: single-link value arm on a
; NON-condition register (the §3c contrast witness; IMPLEMENTATION-4.2 §5f).
; Graduated at WI-4 from the 4.1/WI-3 defer (control_swap_defer_valuearm.ll) —
; same shape, now lowered by the method-B value path.
;
; Contrast partner of control_swap_reject_clobber.ll and
; control_swap_value_reject_clobber_active.ll: the arm value-changes a quantum
; variable %p that the condition does NOT read (the condition reads %q). The
; diamond's straight-through (Pred-edge) incoming is %p, which is NOT in the
; condition's taint provenance — `if(q>5){p=p+3}` ACCEPTS while the §3c clobber
; `if(q>5){q=q+3}` permanently rejects. A wrong §3c reject here would be a
; false positive conflating "rewrites a NON-condition var" with the §3c bind;
; a decline of any kind here would silently regress the WI-4 flip.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; Independent EXACT free-count scan (§8.3 probe): two cqrt_free, no third anywhere.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s --check-prefix=CNT
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %p1 = add i32 %p, 3        ; value op on a NON-condition quantum var (%p, not %q)
  br label %merge
merge:
  %pm = phi i32 [ %p1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; the §5d B-keep stream, single-link chain
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P:[a-zA-Z0-9_.]+]], i32 %[[T]])
; CHECK:     %[[V1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[T]], i32 3)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[V1]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[P]], i32 %[[OUT]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[V1]])
; CHECK:     %[[U1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl_inv(i32 %[[V1]], i32 3)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[U1]])
; CHECK:     call void @cqrt_free(i32 %[[U1]])
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; no third free (neither %out nor the restored source %p — hidden measurement)
; CHECK-NOT: call void @cqrt_free
; the §3c string must never fire on a non-condition-register write
; CHECK-NOT: arm rewrites a condition operand
; dephasing/shape guards
; CHECK-NOT: _controlled
; CHECK-NOT: phi i32

; Exact free count — two (work rail + flag), no third anywhere.
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
