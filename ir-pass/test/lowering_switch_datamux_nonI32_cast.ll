; lowering_switch_datamux_nonI32_cast.ll — bd p119.8 (same gap as p119.6, for the
; SWITCH data-mux merge). A tainted all-ConstantInt data-mux `switch` whose merge is
; NON-i32 (i64 constants 3/7/9) feeds a downstream `trunc i64 -> i32`. The data-mux
; lowers (preload + XOR-delta cqrt_copy_i64_controlled) and RAUWs the merge to the
; i64 out-rail. Without SwitchDataMuxEmit recording HandleWidth[out]="i64", the
; downstream trunc reads the laundered i32 source (getSrcTy after RAUW) and
; over-declines "no template for opcode 'trunc i32'"; with the fix it recovers "i64"
; and lowers to cq_template_trunc_i64_to_i32. (Hand-written `switch` — clang -O1
; folds a small const mux to a select-chain / jump-table gep+load, so the INPUT
; prefix pins the real SWITCH path.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=INPUT < %s
;
; CHECK:     call void @cqrt_copy_i64_controlled(
; CHECK:     call i32 @cq_template_trunc_i64_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: = trunc
; CHECK-NOT: cq_template_trunc_i32
; INPUT: switch i32 %q, label %merge

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i64 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ]   ; i64 data-mux merge (non-i32)
  %t  = trunc i64 %rm to i32                             ; cast off the merge (needs From=i64)
  %m  = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
