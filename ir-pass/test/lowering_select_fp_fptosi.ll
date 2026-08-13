; lowering_select_fp_fptosi.ll — bd p119.6: a tainted-condition fp-DATA `select`
; (kjd1) whose merge result feeds `fptosi` (fp->int) — the branchless
; `n = (int)select(cond,a,b)` range-reduction shape. The fp select lowers to the
; controlled-XOR copy merge (kjd1), RAUW'ing the select result to the i32 out-rail
; handle. The DOWNSTREAM fptosi then captures its SOURCE width: without the merge
; recording HandleWidth, the recovery reads the laundered i32 and declines
; ("no template for opcode 'fptosi i32'"). SelectMergeEmit now records
; HandleWidth[out-rail] = the select's fp data width, so the fptosi recovers "f64"
; and lowers to cq_template_fptosi_f64_to_i32. (The same handle-width invariant
; every other producer — theta / arith / cast — already upholds.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_f64(double
; CHECK:     call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK:     call i32 @cq_template_fptosi_f64_to_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: = fptosi
; CHECK-NOT: cq_template_fptosi_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call double @cq_theta_f64(double 5.000000e-01, double 5.000000e-01)
  %c = fcmp olt double %q, 0.000000e+00        ; tainted condition
  %n = fneg double %q
  %s = select i1 %c, double %n, double %q       ; tainted-cond fp-DATA select (branchless abs)
  %i = fptosi double %s to i32                  ; fptosi directly on the select merge
  %m = call i32 @cq_measure_si32(i32 %i)
  ret i32 %m
}
