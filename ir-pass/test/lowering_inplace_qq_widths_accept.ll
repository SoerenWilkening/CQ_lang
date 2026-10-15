; lowering_inplace_qq_widths_accept.ll — ACCEPT: quantum-quantum `x ^= y`,
; `x += y`, `x -= y` whose OLD `x` is dead lower IN PLACE at every in-place
; width (bd test_C_libtooling-r2j3.33, dm7f.51 step 1; owner ruling
; owner-ruling-dm7f51-inplace-qq-2026-10-14 Q1-Q3; design V6 at i32 and its
; add/sub analogues). New hand-maintained core ABI (runtime/cq_runtime.h):
; cqrt_{xor,add,sub}_<W>(src, dst), dst ^=/+=/-= src.
;
; Source (clang -O1 -include CQ.h), per function:
;   T a = 0, t = 0; cq_theta(&a, .5); cq_theta(&t, .4);
;   t OP= a; cq_theta(&a, .7); return cq_measure(a) + cq_measure(t);
; (The both-dead `long r = t + a` shape this file carried in b12d4452 now fails
; loudly — ruling-dm7f51-both-dead-loud-2026-10-15 — and is pinned by
; lowering_inplace_qq_decline_both_dead.ll.)
;
; WHAT IS PINNED, per function:
;   * the TARGET is chosen by liveness, never by spelling: -O1 writes the dead
;     `t` on the LEFT (`xor %2, %1`, `add nsw %2, %1`); BirthOrder put it in
;     template slot 1; the emitted gate's DESTINATION is `t`'s rail either way;
;   * `sub` keeps its direction: `t - a` is `cqrt_sub_<W>(h_a, h_t)` (dst -= src);
;   * no out-of-place template, nothing freed (rotated user data is never freed).
; Analytic, the 2-bit model of the dm7f.51 step-1 scratch analytic.py (one Ry per
; bit): in place xor P(a=0,t=0)=0.5866, add 0.6069, sub 0.5866 — the textbook
; circuits; the old out-of-place streams gave 0.6336 / 0.6334 / 0.6336.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOTPL < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @xor32()
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 5.000000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT:  call void @cqrt_xor_i32(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 0x3FE6666666666666)
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[A]])
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[T]])
;
; CHECK-LABEL: define i32 @add32()
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 5.000000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT:  call void @cqrt_add_i32(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 0x3FE6666666666666)
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[A]])
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[T]])
;
; CHECK-LABEL: define i32 @sub32()
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 5.000000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 4.000000e-01)
; CHECK-NEXT:  call void @cqrt_sub_i32(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[A]], double 0x3FE6666666666666)
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[A]])
; CHECK-NEXT:  call i32 @cqrt_measure_i32(i32 %[[T]])
;
; CHECK-LABEL: define signext i16 @xor16()
; CHECK:       %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i16(i16 0)
; CHECK:       %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i16(i16 0)
; CHECK:       call void @cqrt_xor_i16(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK:       call i16 @cqrt_measure_i16(i32 %[[T]])
;
; CHECK-LABEL: define signext i8 @sub8()
; CHECK:       %[[A:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK:       %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK:       call void @cqrt_sub_i8(i32 %[[A]], i32 %[[T]]), !cq.inplace.qq
; CHECK:       call i8 @cqrt_measure_i8(i32 %[[T]])
;
; NOTPL-NOT: cq_template_
; NOTPL-NOT: cqrt_free
; NOTPL-NOT: cq.qq.dead

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @xor32() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = xor i32 %2, %1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3)
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

define i32 @add32() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = add nsw i32 %2, %1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3)
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

define i32 @sub32() local_unnamed_addr {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 4.000000e-01)
  %3 = sub nsw i32 %2, %1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 0x3FE6666666666666)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %3)
  %7 = add nsw i32 %6, %5
  ret i32 %7
}


declare i64 @cq_theta_sl(i64 noundef, double noundef) local_unnamed_addr

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr

define signext i16 @xor16() local_unnamed_addr {
  %1 = tail call signext i16 @cq_theta_si16(i16 noundef signext 0, double noundef 5.000000e-01)
  %2 = tail call signext i16 @cq_theta_si16(i16 noundef signext 0, double noundef 4.000000e-01)
  %3 = xor i16 %2, %1
  %4 = tail call signext i16 @cq_theta_si16(i16 noundef signext %1, double noundef 0x3FE6666666666666)
  %5 = tail call signext i16 @cq_measure_si16(i16 noundef signext %4)
  %6 = tail call signext i16 @cq_measure_si16(i16 noundef signext %3)
  %7 = add i16 %6, %5
  ret i16 %7
}

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr

define signext i8 @sub8() local_unnamed_addr {
  %1 = tail call signext i8 @cq_theta_si8(i8 noundef signext 0, double noundef 5.000000e-01)
  %2 = tail call signext i8 @cq_theta_si8(i8 noundef signext 0, double noundef 4.000000e-01)
  %3 = sub i8 %2, %1
  %4 = tail call signext i8 @cq_theta_si8(i8 noundef signext %1, double noundef 0x3FE6666666666666)
  %5 = tail call signext i8 @cq_measure_si8(i8 noundef signext %4)
  %6 = tail call signext i8 @cq_measure_si8(i8 noundef signext %3)
  %7 = add i8 %6, %5
  ret i8 %7
}

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr

declare signext i8 @cq_measure_si8(i8 noundef signext) local_unnamed_addr

