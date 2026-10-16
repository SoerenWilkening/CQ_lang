; lowering_inplace_qq_taped_result_accept.ll — ACCEPT (bd r2j3.33 / dm7f.51 step 1,
; R11 round 2 finding F1; repro review_s1R2/p3.c, and review_s1B/p4.c's shape).
;
; Source (clang -O1 -include CQ.h), in BOTH `main` and a noinline helper:
;   int t = 0, a = 0; cq_theta(&t,.3); cq_theta(&a,.5);
;   t ^= a; printf("%d\n", t); cq_theta(&a,.7); return cq_measure(a);
;
; The result is only TAPED. Whether it then survives is the SPINE's answer at that
; site, asked of its own `computeFreePoint` (R12), never predicted. Since bd r2j3.7
; (owner ruling owner-ruling-r2j3-7-main-dead-record-2026-10-16) BOTH sites follow
; ONE reference, the dead-record discipline: `Insert`, the taped temporary is
; reversed/discharged right after the print (`_unc` + free), BEFORE the later Ry on
; `a`, which equals in place followed by that discharge. Analytic (independent of
; `t`'s angle): P(a=0) = cos^2(.25)cos^2(.35) + sin^2(.25)sin^2(.35) = 0.835606.
; HISTORY: until r2j3.7, `main` followed FreePoint §2.6's live-to-exit register
; file (`Escaped`: converted in place, never undone; P(a=0) = 0.789941 at these
; angles —
; the delegated ruling ruling-dm7f51-main-vs-helper-2026-10-15 kept both; the owner
; replaced it). `main` now also reverse-plays the dead `t` root (`Ry(-.3)`, left
; allocated: a dead register's local unitary, R5).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @taped_helper()
; CHECK:       %[[X:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(
; CHECK-NEXT:  call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[X]])
; CHECK-NEXT:  call void @cq_template_xor_i32_unc(i32 %[[X]],
; CHECK-NEXT:  call void @cqrt_free(i32 %[[X]])
; CHECK-NOT:   !cq.inplace.qq
;
; CHECK-LABEL: define i32 @main()
; CHECK:       %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 3.000000e-01)
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 5.000000e-01)
; CHECK-NEXT:  %[[MX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(i32 %[[T]], i32 %[[A]])
; CHECK-NEXT:  call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[MX]])
; CHECK-NEXT:  call void @cq_template_xor_i32_unc(i32 %[[MX]], i32 %[[T]], i32 %[[A]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[MX]])
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double -3.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 0x3FE6666666666666)
; CHECK-NOT:   !cq.inplace.qq

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define i32 @taped_helper() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %3 = xor i32 %2, %1
  %4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %3)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define i32 @main() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %3 = xor i32 %2, %1
  %4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %3)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 0x3FE6666666666666)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %7 = tail call i32 @taped_helper()
  %8 = add nsw i32 %7, %6
  ret i32 %8
}

