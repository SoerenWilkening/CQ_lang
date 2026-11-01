; cq-0umd (166, rule 26 with rules 3, 18, §1.4): an aggregate result { i32, double } whose i32 leaf is
; -O1's coercion of struct { short, short } (zext / shl 16 / or disjoint in the callee, trunc / lshr 16 /
; trunc in the caller). The leaf crosses as its two fields: the clone returns { i32, i32, double }
; (handle, handle, classical), no packing or unpacking gate on either side.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
; CHECK top: call { i32, i32, double } @__cq_q_mk_100(
; CHECK top: call i32 @cq_template_add_i16(
; CHECK-COUNT top: cq_template_lshr 0
; CHECK-COUNT top: cq_template_trunc 0
; CHECK-COUNT __cq_q_mk_100: cq_template_or 0
; CHECK-COUNT __cq_q_mk_100: cq_template_shl 0
; CHECK-COUNT __cq_q_mk_100: cq_template_zext 0
define double @top(i16 %x0, double %th, i16 %c, double %w) {
  %x = tail call i16 @cq_theta_si16(i16 %x0, double %th)
  %r = tail call { i32, double } @mk(i16 %x, i16 %c, double %w)
  %p = extractvalue { i32, double } %r, 0
  %d = extractvalue { i32, double } %r, 1
  %lo = trunc i32 %p to i16
  %h = lshr i32 %p, 16
  %hi = trunc nuw i32 %h to i16
  %s = add i16 %hi, %lo
  %f = sitofp i16 %s to double
  %t = fadd double %d, %f
  %m = tail call double @cq_measure_f64(double %t)
  ret double %m
}
define internal { i32, double } @mk(i16 %x, i16 %c, double %w) noinline {
  %a = add i16 %x, %c
  %b = mul i16 %x, %c
  %ww = fmul double %w, 3.0
  %zb = zext i16 %b to i32
  %sb = shl nuw i32 %zb, 16
  %za = zext i16 %a to i32
  %p = or disjoint i32 %sb, %za
  %1 = insertvalue { i32, double } poison, i32 %p, 0
  %2 = insertvalue { i32, double } %1, double %ww, 1
  ret { i32, double } %2
}
declare i16 @cq_theta_si16(i16, double)
declare double @cq_measure_f64(double)
