; lowering_mc_xorc_widths.ll — the REST of the frozen `cqrt_xorc_<W>` grid for
; M-C in-place reassignment (bd test_C_libtooling-6uqc, Increment 2c): i8, i16,
; i64. i1 and i32 have their own files (lowering_mc_xorc_i{1,32}.ll).
;
; WHY THE GRID IS PINNED AT ALL, given that 2a already pinned five `cqrt_addc_<W>`
; widths: `xorcFn` and `addcFn` are SEPARATE resolvers minting SEPARATE symbols.
; They apply the same <=64-integer fence today, but nothing in the tree makes a
; drift in one visible in the other, and before this increment `cqrt_xorc_` was
; pinned at i32 ONLY (25 CHECK lines, all from the dtzb loop path). A width that
; silently stopped resolving would fall back to out-of-place and go unnoticed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; Not one out-of-place `xor` template in the whole module:
; CHECK-NOT: cq_template_xor_

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i8  @cq_theta_si8(i8, double)
declare i16 @cq_theta_si16(i16, double)
declare i64 @cq_theta_sll(i64, double)

; CHECK-LABEL: define void @w_i8
; CHECK:       call void @cqrt_xorc_i8(i32 %[[H8:[a-zA-Z0-9_.]+]], i8 42)
; CHECK:       call void @cqrt_xorc_i8(i32 %[[H8]], i8 42)
; CHECK:       call void @cqrt_free(i32 %[[H8]])
define void @w_i8() {
entry:
  %a = call i8 @cq_theta_si8(i8 11, double 5.000000e-01)
  %c = xor i8 %a, 42        ; parent DEAD after -> in place
  ret void
}

; CHECK-LABEL: define void @w_i16
; CHECK:       call void @cqrt_xorc_i16(i32 %[[H16:[a-zA-Z0-9_.]+]], i16 100)
; CHECK:       call void @cqrt_xorc_i16(i32 %[[H16]], i16 100)
; CHECK:       call void @cqrt_free(i32 %[[H16]])
define void @w_i16() {
entry:
  %a = call i16 @cq_theta_si16(i16 21, double 5.000000e-01)
  %c = xor i16 %a, 100        ; parent DEAD after -> in place
  ret void
}

; CHECK-LABEL: define void @w_i64
; CHECK:       call void @cqrt_xorc_i64(i32 %[[H64:[a-zA-Z0-9_.]+]], i64 1000000)
; CHECK:       call void @cqrt_xorc_i64(i32 %[[H64]], i64 1000000)
; CHECK:       call void @cqrt_free(i32 %[[H64]])
define void @w_i64() {
entry:
  %a = call i64 @cq_theta_sll(i64 51, double 5.000000e-01)
  %c = xor i64 %a, 1000000        ; parent DEAD after -> in place
  ret void
}
