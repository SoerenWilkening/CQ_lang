; spec_accept_clone_consumes_chain_rail.ll — ACCEPT, DISCHARGED (bd
; test_C_libtooling-rhk5; family member `f02`). The OWNED-rail half of the same
; defect: the clone call reads the chain rail `p = 3q` ITSELF (`s = h(m, p)`), so it
; is a CONSUMER of a rail the M-B interior partition owns, not a user of the
; borrowed parent. `ChainWalk::isInteriorConsumer` listed "a `__cq_q_*` clone call"
; among the consumers that DISQUALIFY a rail, so `p` could never be interior; the
; component that owns `u = p ^ q` then had `p` as a BORROWED parent whose user — the
; same clone call — clause (d) refused, and both rails leaked, entangled, across the
; second Ry. MEASURED ON THE ORACLE (main 9a230646): the lyyf-(B) warning, no
; `xor_i32_unc`, no `mul_i32_hl_unc`. The hand-inlined twin (`s = p + 1`) reads `p`
; with a template producer — clause (b) — and discharges both.
;
; Both predicates now ask the ONE proof, `cloneCallPreservesArg` (ChainWalk.h):
; clause (b′) of `isInteriorConsumer` (the clone reads `p` and never writes it, and
; `p` is in a slot the specializer recorded as a HANDLE) and clause (3) of
; `preservesBorrowedParent`. The positional half — the call has run before the
; discharge point and never re-reads `p` — is the driver's, unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @slice(i32 %m) {
entry:
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %u = xor i32 %p, %q
  %s = call i32 @h(i32 %m, i32 %p)
  %c = icmp eq i32 %u, 10
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double 3.141590e+00)
  br label %merge

merge:
  %ms = call i32 @cq_measure_si32(i32 %s)
  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %r = add nsw i32 %mq, %ms
  ret i32 %r
}

define i32 @h(i32 %a, i32 %k) {
  %r = add nsw i32 %k, 1
  ret i32 %r
}

; SILENT-NOT: warning
; SILENT-NOT: error
;
; LOWER-LABEL: define i32 @slice(
; LOWER: %h_op = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
; LOWER-NEXT: %h_op1 = call i32 @cq_template_xor_i32(i32 %h, i32 %h_op)
; The clone READS the chain rail `3q`.
; LOWER-NEXT: %s = call i32 @__cq_q_h_10(i32 0, i32 %h_op)
; LOWER-NEXT: %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cqrt_rz_i1(i32 %h_cmp, double 3.141590e+00), !cq.branchphase
; LOWER-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op1)
; `3q` is discharged AFTER its last reader, the clone call, and before the Ry.
; LOWER-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_cmp)
; LOWER-NEXT: %m2 = call i32 @cqrt_measure_i32(i32 %s)
; LOWER-NEXT: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
