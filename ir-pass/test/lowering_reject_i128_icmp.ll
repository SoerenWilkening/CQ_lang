; lowering_reject_i128_icmp.ll — Phase 7.1 follow-up n0ui (Tier-1) DECLINE probe
; (Rule 12, mirrors the i128 accept). `icmp` is OUT of the i128 frozen surface
; (no cq_template_icmp_*_i128 — Prime Directive over-decline; a straight-line
; i128 compare-to-data is an unusual construct and the freeze surface stays
; minimal). A tainted i128 data-position compare must loud-decline, never mint a
; phantom compare template. CompareLowering's explicit `AbiWidth == "i128"` fence
; keeps the decline now that abiWidthFromType recognizes i128.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define void @ex(i64 %u0) {
  %q = call i64 @cq_theta_sll(i64 %u0, double 0.25)
  %w = zext i64 %q to i128
  %c = icmp ugt i128 %w, 100        ; i128 compare-as-data: NOT shipped
  %z = zext i1 %c to i64
  %m = call i64 @cq_measure_sll(i64 %z)
  ret void
}

; CHECK: error{{.*}}no template for opcode 'icmp i1' in tainted context
; CHECK-NOT: cq_template_icmp{{.*}}i128
