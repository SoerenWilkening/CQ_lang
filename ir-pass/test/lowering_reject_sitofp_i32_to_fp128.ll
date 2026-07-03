; lowering_reject_sitofp_i32_to_fp128.ll — DECLINE (bd 3c6m.5 adversarial floor):
; lifting the cross-domain int<->f80 fence must NOT admit int<->fp128. fp128 (IEEE
; quad) has no sound c_type on this x86-64 build (`long double` == fp80 here), so
; it is NOT in fpBits — abiWidthFromType(fp128) returns "" => castInScope's `tf`/
; `ff` are 0 => every cross-domain branch is false regardless of the i128/i1
; guards. So `sitofp i32 to fp128` (the C `(long double)i` on an AArch64-style
; quad target, or an explicit __float128) loud-declines, never minting a phantom
; cq_template_sitofp_i32_to_f128. This pins that the 3c6m.5 fence removal is f80-
; ONLY (Prime Directive — over-declining is safe; f128 stays deferred to 3c6m.6).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare double @cq_measure_f64(double)

define double @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)  ; tainted i32
  %big = sitofp i32 %q to fp128                               ; fp128 NOT in scope
  %d = fptrunc fp128 %big to double
  %m = call double @cq_measure_f64(double %d)
  ret double %m
}

; CHECK: error{{.*}}no template for opcode 'sitofp fp128' in tainted context
; CHECK-NOT: cq_template_sitofp_i32_to_f128
