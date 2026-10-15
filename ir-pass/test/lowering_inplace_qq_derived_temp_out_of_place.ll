; lowering_inplace_qq_derived_temp_out_of_place.ll — ACCEPT, SCOPE PIN (bd
; test_C_libtooling-dm7f.77, InPlaceQQ.cpp E2′): `d ^= c` where `d = a ^ b` is a
; dead DERIVED rail that is NOT a register condition.
;
; Source (clang -O1 -include CQ.h):
;   bool a = 0, b = 0, c = 0; cq_theta(&a, .5); cq_theta(&b, .6); cq_theta(&c, .7);
;   bool d = a ^ b; d ^= c; cq_theta(&c, .3);
;   return cq_measure(a) | (cq_measure(b) << 1) | (cq_measure(c) << 2)
;        | (cq_measure(d) << 3);
;
; E2′ (design D5) absorbs a dead FRESH REGISTER CONDITION rail in place; every
; other derived temporary keeps step 1's out-of-place stream, whose discharge the
; spine places (`xor_i1(c, d)`, `xor_i1_unc(d, a, b)`, `free(d)`) — byte-identical
; to main 27aaf1e1. (A first draft applied E2′ to every unplanned derived temp:
; the same unitary, but it rewrote four accepted streams for no customer.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; NOERR-NOT: error
; CHECK-LABEL: define range(i32 0, 16) i32 @main()
; CHECK:       %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %[[B:[a-zA-Z0-9_.]+]])
; CHECK-NEXT:  %[[R:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i1(i32 %[[C:[a-zA-Z0-9_.]+]], i32 %[[D]])
; CHECK-NEXT:  call void @cq_template_xor_i1_unc(i32 %[[D]], i32 %[[A]], i32 %[[B]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  call void @cqrt_ry_i1(i32 %[[C]], double 3.000000e-01)
; CHECK:       call i1 @cqrt_measure_i1(i32 %[[R]])
; CHECK-NOT:   !cq.inplace.qq

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define range(i32 0, 16) i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 6.000000e-01)
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 0x3FE6666666666666)
  %4 = xor i1 %1, %2
  %5 = xor i1 %4, %3
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef 3.000000e-01)
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %8 = zext i1 %7 to i32
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2)
  %10 = select i1 %9, i32 2, i32 0
  %11 = or disjoint i32 %10, %8
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %13 = select i1 %12, i32 4, i32 0
  %14 = or disjoint i32 %11, %13
  %15 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5)
  %16 = select i1 %15, i32 8, i32 0
  %17 = or disjoint i32 %14, %16
  ret i32 %17
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr
