; lowering_fp80_union_arg_seed_padding_drop.ll — SILENT-DROP PIN (bd vqlq):
; an OPPORTUNISTIC (argument-seeded) union whose promotion the §4.1 walk
; refuses must be dropped SILENTLY, never loud-declined — the helper returns
; the RAW offset-8 word (bits [80,128) are padding: modelled-as-0 bits would
; escape through the `ret` observable), so promotion is unsound and the walk
; fails. Before the vqlq widening this alloca was never a candidate at all
; (seed gate) and the module compiled with the union left in memory; the
; widening must preserve exactly that outcome (the opportunistic set is
; dropped and the strict-only walk re-runs — here to an empty set). A STRICT
; (tainted-seed) walk failure keeps its loud kMsgFp80Padding decline — this
; pin is the widening's no-new-loud-declines boundary. The untainted union
; stays in memory legally (an untainted store is no taint escape).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

%union.IEEEl2bits = type { x86_fp80 }

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @anchor(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %m = call double @cq_measure_f64(double %q)
  ret double %m
}

define i64 @punread(i32 noundef %0) {
  %2 = alloca %union.IEEEl2bits, align 16
  %3 = sitofp i32 %0 to x86_fp80
  store x86_fp80 %3, ptr %2, align 16
  %4 = getelementptr inbounds i8, ptr %2, i64 8
  %5 = load i64, ptr %4, align 8      ; bits [80,128) are padding...
  ret i64 %5                          ; ...returned RAW — walk must refuse
}

; the module still compiles (exit 0, no diagnostic); the anchor lowers
; normally, and the unsound candidate is left byte-untouched in memory (the
; anchor precedes @punread in the output; the CHECK-NOT covers the promoted
; form's bitcast relabel from the surviving store onward):
; CHECK:     call double @cqrt_measure_f64(
; CHECK:     define i64 @punread(
; CHECK:     alloca %union.IEEEl2bits
; CHECK:     store x86_fp80
; CHECK-NOT: bitcast x86_fp80
