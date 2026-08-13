; control_swap_value_diamond_polarity.ll — ACCEPT spec, SUCCESSOR-SWAPPED value
; diamond (Rule 9 polarity probe; IMPLEMENTATION-4.2 §8.4).
;
; Same §5d value diamond as control_swap_value_diamond.ll, but the chain arm is
; the FALSE successor: `br i1 %c, label %merge, label %arm`, with the merge
; phi's entry-incoming listed FIRST — exactly what `clang -O1` produces for an
; `if (u != k)`-style condition (it swaps the branch targets and the phi edge
; order). A lowering that assumed "successor 0 is the taken arm" or "phi
; incoming 0 is the arm value" would route the WRONG arm and miscompile
; (verify-clean). Detection resolves the arm by merge-phi incoming IDENTITY
; (ControlDetect sets ArmNegated); the emitter routes on ¬flag via the
; self-inverse `cqrt_x(flag)` bracket around ALL FOUR cswaps — route-in,
; route-back, route-back-dagger, route-in-dagger (the R-dagger brackets are the
; literal adjoints of the forward ones, same polarity). The copy-out placement,
; reverse-play threading, frees, and icmp_inv flag-strip are all
; polarity-independent. EXACTLY TWO frees — the X-bracket adds cqrt_x calls,
; never extra frees.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; Independent EXACT free-count scan (§8.3 probe): two cqrt_free, no third anywhere.
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %merge, label %arm     ; SWAPPED: chain arm is the FALSE successor
arm:
  %v1 = mul i32 %p, 5
  %v2 = add i32 %v1, 15
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v2, %arm ]   ; entry-incoming FIRST (edge order swapped)
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; 1: mint the flag, then route the value register in — on ¬flag (the chain arm
; is the FALSE successor), so every cswap is X-bracketed.
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P:[a-zA-Z0-9_.]+]], i32 %[[T]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; 4: arm chain VERBATIM on the rail (uncontrolled HL templates)
; CHECK:     %[[V1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[T]], i32 5)
; CHECK:     %[[V2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[V1]], i32 15)
; 5: route back (adjoint of the split, same ¬flag bracket) — p holds the answer
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[V2]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; 6: B-keep copy-out (after route-back, before R-dagger — interlock §6.4)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[P]], i32 %[[OUT]])
; 7: reverse-play R-dagger — bracketed route-back-dagger, chain adjoint in reverse
;    via the void `_unc` forms (out=forward result, src=live forward operand),
;    bracketed route-in-dagger on the WORK RAIL %[[T]] (the chain head → |0>)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[V2]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_add_i32_hl_unc(i32 %[[V2]], i32 %[[V1]], i32 15)
; CHECK:     call void @cq_template_mul_i32_hl_unc(i32 %[[V1]], i32 %[[T]], i32 5)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[P]], i32 %[[T]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; 8: rail free consumes the WORK RAIL %[[T]] (|0> after route-in-dagger; the
;    `_unc`-zeroed intermediates leak — accepted WI-3 leak, never freed dirty)
; CHECK:     call void @cqrt_free(i32 %[[T]])
; 9: strip the boolean + reclaim the flag (polarity-independent: p untouched)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; the merge phi RAUWs to %out — the measure reads the copied answer
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; no third free (neither %out nor the restored source %p — hidden measurement)
; CHECK-NOT: call void @cqrt_free
; dephasing/shape guards: zero controlled gates, no surviving data mux
; CHECK-NOT: _controlled
; CHECK-NOT: phi i32

; Exact free count — two (work rail + flag), no third anywhere.
; CNT-COUNT-2: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
