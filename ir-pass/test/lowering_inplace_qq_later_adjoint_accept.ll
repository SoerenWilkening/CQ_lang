; lowering_inplace_qq_later_adjoint_accept.ll — ACCEPT (bd r2j3.33 / dm7f.51 step 1,
; R11 round 2b finding N1; repro review_s1R2b/q4.c).
;
; Source (clang -O1 -include CQ.h), in a noinline helper so the spine discharges:
;   int a,b,c,t (rotated); int tmp = a * b; t ^= (c + tmp);
;   int r = t & tmp; int s = r * 7; measure s, t, c, a, b
;
; `t ^= c + tmp` converts in place; `r = t & tmp` is a FORWARD read of the NEW `t`
; AFTER the gate, and the spine's `cq_template_and_i32_unc(r, tmp, t)` re-reads
; that same new `t`. d5c26b12's postcondition counted every handle of every
; `_unc` as a record and failed loudly here (an over-decline: 634f64b4 accepted
; it). An adjoint is stale only when its FORWARD — located by EmitInverse's own
; recipe (`forwardOfAdjoint`) — predates the gate.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define {{.*}}@g()
; CHECK:       call void @cqrt_ry_i32(i32 %[[T:[a-zA-Z0-9_.]+]], double 6.000000e-01)
; CHECK:       call void @cqrt_xor_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T]])
; CHECK:       call void @cq_template_and_i32_unc(i32 %[[R]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[R]])

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @g() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 6.000000e-01)
  %5 = mul nsw i32 %2, %1
  %6 = add nsw i32 %3, %5
  %7 = xor i32 %4, %6
  %8 = and i32 %7, %5
  %9 = mul nsw i32 %8, 7
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %12 = add nsw i32 %11, %10
  %13 = tail call i32 @cq_measure_si32(i32 noundef %3)
  %14 = add nsw i32 %12, %13
  %15 = tail call i32 @cq_measure_si32(i32 noundef %1)
  %16 = add nsw i32 %14, %15
  %17 = tail call i32 @cq_measure_si32(i32 noundef %2)
  %18 = add nsw i32 %16, %17
  ret i32 %18
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @g()
  ret i32 %1
}

