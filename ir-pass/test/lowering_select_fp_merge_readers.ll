; lowering_select_fp_merge_readers.ll — bd p119.6 (Rule-13 clearance hardening).
; Companion to lowering_select_fp_fptosi.ll, which pins only ONE consumer of the
; select merge's recorded HandleWidth — the integer-dest `fptosi`. HandleWidth is
; read in exactly TWO places that can see the merge: the cast From-recovery
; (OpcodeLowering) and the Q+Q compare width-agreement (CompareLowering). This
; fixture exercises BOTH directly on the same fp-select merge %s (an fp-WIDENING
; cast + a Q+Q fp compare), locking the second reader against a silent
; over-decline regression:
;   * %w   = fpext double %s to x86_fp80   -> cq_template_fpext_f64_to_f80  (cast From-recovery reads the merge's "f64")
;   * %cmp = fcmp ogt double %s, %p        -> cq_template_fcmp_ogt_f64      (Q+Q agreement reads the merge's "f64")
; Without SelectMergeEmit recording HandleWidth[out]="f64", both would read the
; laundered i32 and either over-decline or disagree. (Fail-safe direction — a
; regression over-declines, never miscompiles — but pinned so it stays lowering.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; CHECK:     call void @cqrt_copy_f64_controlled(
; CHECK-DAG: call i32 @cq_template_fpext_f64_to_f80(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-DAG: call i32 @cq_template_fcmp_ogt_f64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: fpext_i32
; CHECK-NOT: fcmp_ogt_i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example() {
entry:
  %q   = call double @cq_theta_f64(double 5.000000e-01, double 5.000000e-01)
  %p   = call double @cq_theta_f64(double 2.500000e-01, double 5.000000e-01)
  %c   = fcmp olt double %q, 0.000000e+00
  %qn  = fneg double %q
  %s   = select i1 %c, double %qn, double %q          ; fp-select merge (f64), fans out
  %w   = fpext double %s to x86_fp80                  ; reader 1: cast From-recovery reads merge "f64"
  %cmp = fcmp ogt double %s, %p                       ; reader 2: Q+Q compare agreement reads merge "f64"
  %wt  = fptrunc x86_fp80 %w to double
  %z   = uitofp i1 %cmp to double
  %sum = fadd double %wt, %z
  %m   = call double @cq_measure_f64(double %sum)
  ret double %m
}
