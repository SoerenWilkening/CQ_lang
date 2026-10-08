; spec_intermediate_unc_warn_twin_unsynthesizable.ll — WARNING, LEFT ALLOCATED (bd
; test_C_libtooling-p3kd.13): the explicit policy when a clone result's Bennett twin
; CANNOT be synthesized. The warn twin of spec_intermediate_unc_user_helper.ll.
;
; THE SHAPE. `@inner`'s body carries an undef-derived SCRATCH computation
; (`%c = xor i32 undef, 7; %y = mul i32 %a, %c`, never returned). The forward clone
; reads `undef` once; a twin is a verbatim COPY of the body and would read it
; again, independently — the bd xy9n duplication hazard, refused by
; `findUndefOperandInBody` (CloneProducer.h (P3); for an INNER call `ensureTwin`
; declines it loudly, spec_reject_twin_undef_dup_scratch.ll). The return value
; itself is clean, so the bd 3p2a specialization fence lets the clone through.
;
; THE POLICY. The clone result is not owned: no twin is synthesized, no `_unc` is
; called, no `cqrt_free` is emitted (R5 — the rail is not provably |0>). That is
; main db4cf60a's stream for EVERY clone result, unchanged here; and a later
; non-diagonal gate on a register it records is reported by the M-A guard as
; before — `opt` exit 0 with a `warning:` (the owner's lyyf ruling). Building the
; twin for this shape (freeze-and-pass the scratch literal, or a twin that reads
; the forward's literal) is the follow-up the p3kd.13 report drafts.
;   @data_chain — `s = inner(q) * 5; measure(s); cq_theta(&q, .7)`.
;   @oracle     — bd ln16's d2 reproducer with this callee as the oracle:
;                 `if (inner(a) == 7) cq_phi(PI); cq_theta(&a, -0.5)` (S-dagger).
;                 The flag's compare chain IS discharged (its strip), the clone
;                 rail is not.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOTWIN < %t.ll

; WARN: warning: {{.*}}in function data_chain{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN: warning: {{.*}}in function oracle{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: warning

; CHECK-LABEL: define i32 @data_chain(
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call fastcc i32 @__cq_q_inner_1(i32 %[[H:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 5)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 0x3FE6666666666666)

; CHECK-LABEL: define i32 @oracle(
; CHECK:      %[[R2:[a-zA-Z0-9_.]+]] = call fastcc i32 @__cq_q_inner_1(i32 %[[H2:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[R2]], i32 7)
; CHECK:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[R2]], i32 7)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H2]], double -5.000000e-01)

; No twin anywhere, no call to one, and the clone rail is never freed.
; NOTWIN-NOT: __cq_q_inner_1_unc
; NOTWIN-NOT: call void @cqrt_free(i32 %r)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define internal fastcc i32 @inner(i32 %a) {
  %c = xor i32 undef, 7          ; undef-DERIVED scratch — an Instruction, not a literal
  %y = mul i32 %a, %c            ; never returned, never copied out
  %b = mul nsw i32 %a, 3
  %s = add nsw i32 %b, 1         ; the returned value: a CLEAN cone
  ret i32 %s
}

define i32 @data_chain(i32 %u) {
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r  = call fastcc i32 @inner(i32 %q)
  %s  = mul nsw i32 %r, 5
  %m  = call i32 @cq_measure_si32(i32 %s)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %t  = add nsw i32 %m2, %m
  ret i32 %t
}

define i32 @oracle(i32 %u) {
entry:
  %a = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call fastcc i32 @inner(i32 %a)
  %c = icmp eq i32 %r, 7
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %merge
merge:
  %a2 = call i32 @cq_theta_si32(i32 %a, double -5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %a2)
  ret i32 %m
}
