; control_regcond_inplace_mc_rail_marker_accept.ll — ACCEPT (bd
; test_C_libtooling-dm7f.77, R11 round 2 F1; hand IR review_s2R2/h2.ll):
;   x = a ^ b   (b dead: in place, CNOT(a, b));
;   c = !x      (x dead, a FRESH register condition: M-C in place, xorc on b's rail);
;   if (c) prep t;  measure(a, t, c)
; THE OVER-DECLINE THIS PINS (2123517b, rc 1): M-C copied the condition's COMMIT
; tag onto the rail it wrote, which here is the QQ template `x`, and the late QQ
; round read that copy as `x`'s own commit ("fresh, yet eligible and kept") and
; refused it loudly; 348e245f accepted. One meaning per metadata kind: the rail
; now takes only the `!cq.regcond.rail` marker (ChainWalk row (c′)), never the
; commit. Hand-derived stream (register semantics, Ry(θ)|0> = cos|0> + sin|1>):
; Ry(a,.4); Ry(b,.3); CNOT(a,b); X-by-xorc on b (now holding c = !(a^b));
; t = |0>, cRy(c -> t, .5); `c` is measured, so its rail is kept (no discharge);
; no metadata tag reaches the output.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=NOTAG < %t.ll
; NOERR-NOT: error
; NOTAG-NOT: cq.regcond
; CHECK-LABEL: define i32 @main()
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[A]], double 4.000000e-01)
; CHECK-NEXT:  %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[B]], double 3.000000e-01)
; CHECK-NEXT:  call void @cqrt_cnot(i32 %[[A]], i32 %[[B]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_xorc_i1(i32 %[[B]], i1 true)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT:  call void @cqrt_ry_i1_controlled(i32 %[[B]], i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call i1 @cqrt_measure_i1(i32 %[[A]])
; CHECK-NEXT:  call i1 @cqrt_measure_i1(i32 %[[T]])
; CHECK-NEXT:  call i1 @cqrt_measure_i1(i32 %[[B]])
; CHECK-NOT:   cqrt_free

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main() {
entry:
  %a = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 4.0e-01)
  %b = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 3.0e-01)
  %x = xor i1 %a, %b
  %c = xor i1 %x, true
  br i1 %c, label %T, label %M
T:
  %t = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.0e-01)
  br label %M
M:
  %tp = phi i1 [ %t, %T ], [ false, %entry ]
  %m1 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %a)
  %m2 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %tp)
  %m3 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %c)
  %r1 = and i1 %m1, %m2
  %r = and i1 %r1, %m3
  %z = zext i1 %r to i32
  ret i32 %z
}
declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
