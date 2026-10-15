; lowering_inplace_qq_chain_accept.ll — ACCEPT: the in-place quantum-source
; round (bd test_C_libtooling-r2j3.33, dm7f.51 step 1) composed with what is
; around it.
;
;   @chain  `t ^= a; t += b; t -= a;` — clang -O1 reassociates the last two into
;           `t' = (t ^ a) + (b - a)` (a fold, kept: owner-ruling-dicke-acceptance-
;           folded-2026-10-14). BOTH QQ updates of `t` convert, in program order
;           (the second's target is the first's relabelled rail); `b - a` is a
;           temporary, out of place, and is DISCHARGED right after the gate that
;           reads it (`isInteriorConsumer` (b‴): the gate is a finished reader of
;           its source) — before the later Ry on `a`, so `a` and `b` are not
;           dephased by a standing `b - a` record. Analytic: rail(t) ends at
;           (t ^ a) + (b - a) = the source's t; rail(b - a) returns to |0>.
;   @derived_src  `t ^= q * 3;` — the source is a derived template, discharged
;           after the gate, before the Ry on `q` (the same (b‴) row).
;   @region_reader_settled  `if (t * 3 == 6) cq_phi(.3); t ^= a;` — a PRIOR
;           reader of `t` (the region's compare, folded to `t == 2`) whose strip
;           and free are inline before the xor is settled (M-C G7 arm (d)), so
;           the xor still converts.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOWARN --allow-empty < %t.err
;
; CHECK-LABEL: define i32 @chain()
; CHECK:       %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT:  call void @cqrt_xor_i32(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32(i32 %[[B]], i32 %[[A]])
; CHECK-NEXT:  call void @cqrt_add_i32(i32 %[[D]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cq_template_sub_i32_unc(i32 %[[D]], i32 %[[B]], i32 %[[A]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 0x3FE6666666666666)
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[T]])
;
; CHECK-LABEL: define i32 @derived_src()
; CHECK:       %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT:  call void @cqrt_xor_i32(i32 %[[M]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cq_template_mul_i32_hl_unc(i32 %[[M]], i32 %[[Q]], i32 3)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[M]])
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[Q]], double 0x3FE6666666666666)
; CHECK:       call i32 @cqrt_measure_i32(i32 %[[T]])
;
; CHECK-LABEL: define i32 @region_reader_settled()
; CHECK:       %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:       call void @cq_template_icmp_eq_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[T]], i32 2)
; CHECK-NEXT:  call void @cqrt_free(
; CHECK-NEXT:  call void @cqrt_xor_i32(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NOT:   cq_template_xor_
;
; No standing record of the rotated parents: the M-A live-record warning that a
; leaked `b - a` / `q * 3` would raise is absent.
; NOWARN-NOT: non-diagonal gate over a live derived record

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @chain() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %4 = xor i32 %3, %1
  %5 = sub i32 %2, %1
  %6 = add i32 %5, %4
  %7 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 2.000000e-01)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %10 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %11 = add nsw i32 %10, %9
  %12 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %13 = add nsw i32 %11, %12
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define i32 @derived_src() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = mul nsw i32 %1, 3
  %4 = xor i32 %2, %3
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

define i32 @region_reader_settled() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = icmp eq i32 %2, 2
  br i1 %3, label %4, label %5

4:                                                ; preds = %0
  tail call void @cq_phi(double noundef 3.000000e-01)
  br label %5

5:                                                ; preds = %4, %0
  %6 = xor i32 %2, %1
  %7 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %10 = add nsw i32 %9, %8
  ret i32 %10
}

declare void @cq_phi(double noundef) local_unnamed_addr

