; lowering_reject_i80_sext.ll — bd 3c6m.51 DECLINE (the i80 cast fence): i80 is a
; bitcast-only extraction width — never BUILT by widening a narrower integer. A
; tainted `sext i32 -> i80` (or `zext ... -> i80`) has no `cq_template_sext_*_to_i80`
; template; castInScope excludes i80 from sext/zext in BOTH directions
; (`fromW != "i80" && toW != "i80"`), so `rewriteCast` declines rather than mint a
; phantom. i80 ships ONLY the narrowing `trunc i80 -> {i1..i64}` + the f80<->i80
; bitcast (Prime Directive: over-decline is safe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_measure_sll(i64)

define i64 @sext_i80() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %s = sext i32 %q to i80                        ; OUT OF SCOPE: i80 is not a sext dest
  %t = trunc i80 %s to i64
  %m = call i64 @cq_measure_sll(i64 %t)
  ret i64 %m
}

; CHECK: error{{.*}}no template for opcode 'sext i80' in tainted context
; CHECK-NOT: cq_template_sext_i32_to_i80
