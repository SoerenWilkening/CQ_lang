; lowering_reject_i80_sitofp.ll — bd 3c6m.51 DECLINE (the i80 cross-domain fence):
; i80 ships ONLY the bit-pattern ops (and/lshr/or/shl/icmp/trunc-from/zext-to/
; bitcast), never int<->fp — mirror the i128 cross-domain exclusion. A tainted
; `sitofp i80 -> double`
; has no template; castInScope excludes i80 from every cross-domain cast
; (`fromW != "i80"` on sitofp/uitofp, `toW != "i80"` on fptosi/fptoui), so
; `rewriteCast` declines rather than mint a phantom.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare double @cq_measure_f64(double)

define double @sitofp_i80() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFE8000000000000000, double 5.000000e-01)
  %bc = bitcast x86_fp80 %q to i80
  %f = sitofp i80 %bc to double                  ; OUT OF SCOPE: i80<->fp is fenced
  %m = call double @cq_measure_f64(double %f)
  ret double %m
}

; CHECK: error{{.*}}no template for opcode 'sitofp double' in tainted context
; CHECK-NOT: cq_template_sitofp_i80
