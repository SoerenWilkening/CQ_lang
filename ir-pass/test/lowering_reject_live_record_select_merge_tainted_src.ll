; lowering_reject_live_record_select_merge_tainted_src.ll — DECLINE: severance
; class 2 again, but with a TAINTED copy SOURCE rather than two constant
; ancillas (M-A Increment 3, bd test_C_libtooling-6uqc).
;
; The companion to lowering_reject_live_record_select_merge_out.ll. There the
; only rails reachable across the copy edge besides the flag were the two
; constant `cqrt_alloc_i32(10)/(20)` ancillas — product states whose decline is a
; deliberate over-decline. Here one arm of the merge is a real computed rail, so
; the copy SOURCE edge carries a genuinely entangled record and the decline does
; not depend on the constant-ancilla reading at all.
;
; SOURCE (a 4-way `switch` that `clang -O1` canonicalizes into arithmetic + a
; single `select` — the SSA below is verbatim what it emits):
;     int a = cq_theta(u0, 0.5);
;     switch (a) { case 0: m=11; case 1: m=22; case 2: m=33; default: m=44; }
;     int w = cq_theta(m, 0.25);
;     return cq_measure(w);
;
; HEAD stream (measured, `opt` exit 0 — the over-accept this closes):
;     %h_op  = cq_template_mul_i32_hl(%h, 11) ; cqrt_addc_i32(%h_op, 11)
;     %h_cmp = cq_template_icmp_ult_i32_hl(%h, 3)
;     %out   = cqrt_alloc_i32(0)
;     cqrt_copy_i32_controlled(%h_cmp, %h_op, %out)      <-- TAINTED src
;     cqrt_x(%h_cmp)
;     %selop = cqrt_alloc_i32(44) ; cqrt_copy_i32_controlled(%h_cmp,%selop,%out)
;     cqrt_x(%h_cmp)
;     cq_template_icmp_ult_i32_hl_unc(%h_cmp,%h,3) ; cqrt_free(%h_cmp)
;     cqrt_ry_i32(%out, 0.25)                            <-- T
; `%h_op` (= 11a+11) and `%h` are both live, dead-at-the-gate basis records of
; the wire `%out`; neither is uncomputed or freed. The Ry over them is dephased.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c  = icmp ult i32 %q, 3
  %t0 = mul nsw i32 %q, 11
  %t1 = add nsw i32 %t0, 11
  %m  = select i1 %c, i32 %t1, i32 44                          ; merge out, TAINTED true-arm
  %w  = call i32 @cq_theta_si32(i32 %m, double 2.500000e-01)   ; T
  %r  = call i32 @cq_measure_si32(i32 %w)
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
