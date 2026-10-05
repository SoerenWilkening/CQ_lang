; control_inplace_ry_cond_register_flag_kept.ll — ACCEPT: the arm's Ry rotates
; the condition's own register, and the condition flag is KEPT (bd
; test_C_libtooling-dm7f.4, owner ruling 2026-10-03, option (a)).
;
;     int q = u; cq_theta(&q, .5);
;     if (q > 5) cq_theta(&q, .9);
;     return cq_measure(q);
;
; DECLINE -> ACCEPT FLIP (was control_inplace_ry_reject_cond_register.ll, which
; pinned `condition predates a non-diagonal gate under quantum control`). That
; decline protected the FLAG STRIP, not the unitary (CLAUDE.md L5): the strip
; recomputes q > 5 on a register the Ry has just relabelled, so it cannot return
; the flag to |0>. The lowering now emits no strip and no free.
;
; SEMANTIC EVIDENCE (trace reasoning, R2). Write the state before the region as
; sum_x a_x |x>_q. The emitted stream is
;     f = icmp_sgt_hl(q, 5)          sum_x a_x |x>_q |[x>5]>_f
;     cry(f, q, .9)                  sum_x a_x (x>5 ? Ry(.9)|x> : |x>)_q |[x>5]>_f
; which is the source on every basis branch: the Ry fires exactly where the
; pre-Ry q exceeds 5 and nowhere else. The mint precedes the gate, so it reads
; the pre-Ry basis. The map |x> -> (x>5 ? Ry|x> : |x>) alone is not unitary on q
; (Ry|6> overlaps |5>), so a which-branch record must survive: that record is f.
; f is not provably |0> and is never freed (R5); no measurement is inserted. The
; leftover entanglement is the user's circuit (owner ruling lyyf), reported by
; M-A's late guard as `non-diagonal gate over a live derived record` at the gate
; (DS_Warning, `opt` exits 0). The user register q gets only the controlled Ry
; (nothing else non-diagonal under control) and is measured as written.
;
; ⚠ `CHECK-NEXT` from the mint to the measurement is the pin: a strip
; (`icmp_sgt_i32_hl_unc`) or a `cqrt_free` anywhere in that window fails it,
; and the two implicit negatives refuse either anywhere in the module.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s --implicit-check-not=cqrt_free --implicit-check-not=_unc < %t.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: error

; CHECK-LABEL: define i32 @example(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[H]], double 9.000000e-01)
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32
