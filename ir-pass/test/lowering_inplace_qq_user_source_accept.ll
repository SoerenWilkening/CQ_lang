; lowering_inplace_qq_user_source_accept.ll — ACCEPT (bd r2j3.33 / dm7f.51 step 1,
; R11 round 1 findings A-F2 and B-F2).
;
;   @chained_user_source  `t += a; a ^= t; cq_theta(&a, .7);` (review_s1A/p1.c).
;       The second op's source `t` was written by an in-place gate that READ `a`,
;       and b12d4452's dependence walk followed that write and left `a ^= t` out
;       of place (old `a` kept beside `a'`, dephasing the Ry; a lyyf warning only).
;       `t` is the user's register, never uncomputed, so it is not a record of
;       `a`'s old value: the walk now stops at user data (E3 narrowed), and both ops
;       convert. Analytic: rail(t) = t + a, then rail(a) = a ^ (t + a) — the source's
;       two assignments in order — and nothing else stands.
;   @taped_prior_reader   `r = t + a; printf r; t ^= a * 3; printf t;` (review_s1B/p4.c).
;       b12d4452 failed loudly here. The result `t'` is only TAPED, and a tape
;       write copies it out: the spine then discharges the result right after the
;       write (measured on 435b3bc1). So the result does not SURVIVE, out of place is
;       exact, and the module lowers exactly as on 435b3bc1.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOWARN --allow-empty < %t.err
;
; CHECK-LABEL: define {{.*}}i32 @chained_user_source()
; CHECK:       %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 1)
; CHECK:       %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 2)
; CHECK-NEXT:  call void @cqrt_ry_i8(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT:  call void @cqrt_add_i8(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_xor_i8(i32 %[[T]], i32 %[[A]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i8(i32 %[[A]], double 0x3FE6666666666666)
; CHECK-NOT:   cq_template_
;
; CHECK-LABEL: define i32 @taped_prior_reader()
; CHECK:       %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(
; CHECK-NEXT:  call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[X]])
; CHECK-NEXT:  call void @cq_template_xor_i32_unc(i32 %[[X]],
; CHECK-NEXT:  call void @cqrt_free(i32 %[[X]])
; CHECK-NOT:   !cq.inplace.qq
;
; NOWARN-NOT: chained_user_source

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define range(i32 0, 511) i32 @chained_user_source() local_unnamed_addr {
  %1 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 1, double noundef 5.000000e-01)
  %2 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext 2, double noundef 4.000000e-01)
  %3 = add i8 %2, %1
  %4 = xor i8 %3, %1
  %5 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %4, double noundef 0x3FE6666666666666)
  %6 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %5)
  %7 = zext i8 %6 to i32
  %8 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %3)
  %9 = zext i8 %8 to i32
  %10 = add nuw nsw i32 %9, %7
  ret i32 %10
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr

define i32 @taped_prior_reader() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %3 = add nsw i32 %2, %1
  %4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %3)
  %5 = mul nsw i32 %2, 3
  %6 = xor i32 %5, %1
  %7 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %6)
  %8 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666)
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8)
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

