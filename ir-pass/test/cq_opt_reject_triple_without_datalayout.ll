; cq_opt_reject_triple_without_datalayout.ll — cq-opt refuses a module that
; names a `target triple` but carries no `target datalayout`.
;
; WHY. Stock `opt` (LLVM 19 optMain's SetDataLayout callback) INFERS the
; datalayout of such a module from the registered target's TargetMachine and
; prints it; cq-opt links no target backends (that is its whole point: see the
; cq-opt block in ir-pass/CMakeLists.txt), so it would run the pass under the
; DEFAULT DataLayout and print no layout line. The two then diverge silently:
; the 2026-10-16 batch gate (`cq-opt-equivalence-full`, main a19e570c) caught
; exactly that on two fixtures ("stdout differs"), and the pass's own semantics
; (pointer size, alignment) depend on the layout. Inferring it would mean
; linking every target opt registers; refusing keeps cq-opt observationally
; equivalent where it runs at all, and loud where it cannot be.
;
; The triple and layout live in `; TRIPLE:` / `; LAYOUT:` comments and are
; spliced in by sed, so this file itself has neither and the equivalence sweep
; (tools/cq_opt_equivalence.py, which runs stock opt on every *.ll here) still
; sees both drivers agree on it.
;
; TRIPLE: target triple = "x86_64-apple-macosx16.0.0"
; LAYOUT: target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
;
; Decline: triple, no layout -> loud, non-zero, nothing printed.
; RUN: sed -e 's/^; TRIPLE: //' %s > %t.bad.ll
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %t.bad.ll 2>&1 \
; RUN:   | %filecheck %s --check-prefix=BAD --implicit-check-not=define
; BAD: cq-opt: module has a target triple ('x86_64-apple-macosx16.0.0') but no target datalayout; stock opt infers one from the target, cq-opt links no targets and cannot. Add an explicit 'target datalayout' line.
;
; Accept: the same module with an explicit layout lowers and keeps the layout.
; RUN: sed -e 's/^; TRIPLE: //' -e 's/^; LAYOUT: //' %s > %t.good.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %t.good.ll \
; RUN:   | %filecheck %s --check-prefix=GOOD
; GOOD: target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
; GOOD: target triple = "x86_64-apple-macosx16.0.0"
; GOOD: call void @cqrt_ry_i32(
;
; Accept: no triple at all (this file as written) is unaffected.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s --check-prefix=NOTRIPLE
; NOTRIPLE-NOT: target datalayout
; NOTRIPLE: call void @cqrt_ry_i32(

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u) {
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
