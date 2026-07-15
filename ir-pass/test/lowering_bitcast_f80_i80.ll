; lowering_bitcast_f80_i80.ll — bd 3c6m.51 ACCEPT: the f80<->i80 reinterpret is
; NOW in scope. `castInScope` admits a bitcast for a same-BIT-WIDTH fp<->int pair
; at a SHIPPED width, and `intBits` now knows `i80 == 80 == fpBits(f80)`, so a
; tainted `bitcast x86_fp80 -> i80` lowers to the identity relabel
; `cq_template_bitcast_f80_to_i80` and the follow-on `trunc i80 -> i32` to
; `cq_template_trunc_i80_to_i32`. This is the x86_fp80 bit-pattern EXTRACTION the
; promoteFp80Union peephole depends on (the union-memory form is exercised by
; lowering_fp80_union_promote.ll; this pins the register-resident WIDTH path).
; SUPERSEDES the p119.7 decline fixture (f80<->i80 was out of scope then).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %cq-opt -passes=verify -S %t.ll -o /dev/null

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare x86_fp80 @cq_theta_f80(x86_fp80, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call x86_fp80 @cq_theta_f80(x86_fp80 0xK3FFF8000000000000000, double 5.000000e-01)
  %i = bitcast x86_fp80 %q to i80       ; IN SCOPE (bd 3c6m.51): the extraction relabel
  %t = trunc i80 %i to i32
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}

; CHECK: call i32 @cqrt_alloc_f80
; CHECK: call void @cqrt_ry_f80
; CHECK: call i32 @cq_template_bitcast_f80_to_i80
; CHECK: call i32 @cq_template_trunc_i80_to_i32
; CHECK: call i32 @cqrt_measure_i32
; CHECK-NOT: error
