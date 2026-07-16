; spec_reject_bitcast_fp128_body.ll — DECLINE PIN (bd vqlq, the value-bitcast
; carve boundary): a same-width fp128<->i128 bitcast in a spec-candidate
; callee body is NOT "the ninth relabel" — fp128 has no ABI width, so the
; width gate declines it source-located BEFORE castInScope is consulted (and
; castInScope would decline it too: only the eight shipped same-width fp<->int
; pairs f16/f32/f64/f80 pass). The carve routes non-pointer bitcasts to these
; gates instead of the categorical "pointer cast" reject; everything off the
; shipped grid keeps declining loudly.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %y = call i32 @w(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

define i32 @w(i32 %0) {
  %z = zext i32 %0 to i128
  %f = bitcast i128 %z to fp128   ; fp128: no ABI width — decline HERE
  %g = bitcast fp128 %f to i128
  %t = trunc i128 %g to i32
  ret i32 %t
}

; CHECK: error{{.*}}in function w{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported width)
; CHECK-NOT: __cq_q_w
