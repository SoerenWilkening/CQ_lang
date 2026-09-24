; lowering_reject_railbank_dynamic_narrow_index.ll — DECLINE (bd test_C_libtooling-xdu2.4, Rule-13 review B F-B5).
;
; Hand IR (clang on x86-64 always indexes with i64): a runtime `alloca i32, i16 %n`
; walked by an i16 {0,+,1} index. The gep SIGN-extends the index while the alloca
; ZERO-extends the extent, so "the walk visits cells 0..n-1" fails for n >= 2^15.
; The carve now requires the cell index to be as wide as the address arithmetic.
; Kills injection mutant R5 (the width conjunct deleted), under which this ACCEPTED.
; ⚠ A DS_Error decline writes 0 bytes to stdout; the property is pinned by the `not` inversion (Rule 12 (b)).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: cq rail bank: cell index is not an injective per-iteration index
; CHECK-NOT: tainted value stored to memory

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
define i32 @slice(i16 %n) {
entry:
  %g = icmp ugt i16 %n, 0
  br i1 %g, label %ph, label %exit0
ph:
  %b = alloca i32, i16 %n, align 16
  br label %w
w:
  %i = phi i16 [0,%ph],[%in,%w]
  %p = getelementptr inbounds i32, ptr %b, i16 %i
  %s = load i32, ptr %p, align 4
  %t = call i32 @cq_theta_si32(i32 %s, double 0.5)
  store i32 %t, ptr %p, align 4
  %in = add nuw i16 %i, 1
  %c = icmp eq i16 %in, %n
  br i1 %c, label %rph, label %w
rph:
  br label %r
r:
  %j = phi i16 [0,%rph],[%jn,%r]
  %acc = phi i32 [0,%rph],[%acc2,%r]
  %q = getelementptr inbounds i32, ptr %b, i16 %j
  %v = load i32, ptr %q, align 4
  %m = call i32 @cq_measure_si32(i32 %v)
  %acc2 = add i32 %acc, %m
  %jn = add nuw i16 %j, 1
  %c2 = icmp eq i16 %jn, %n
  br i1 %c2, label %out, label %r
out:
  ret i32 %acc2
exit0:
  ret i32 0
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
