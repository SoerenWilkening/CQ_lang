; lowering_accept_undef_literal_two_functions.ll — ACCEPT (bd xy9n).
; ARM: guard 1's PER-FUNCTION counting scope, and the only thing pinning it.
;
; *** THE FIRST DRAFT COUNTED PER MODULE AND DECLINED THIS. *** The Rule-13 round
; reproduced it from REAL openlibm source: a TU holding TWO libm cells, each with
; its own `clang -O1` dead-edge `select i1 %c, double undef, double %v`, ends up with
; two `cqrt_alloc_<W>(double undef)` slots in two DIFFERENT functions. Each one is
; individually the exact shape lowering_accept_undef_literal_single_slot.ll certifies
; as sound; neither rail is ever freed; on the pre-change plugin the whole module
; passes free_pairing_check STRICT with 436/436 verified and 0 unproven. Two cells in
; one TU is an ordinary multi-slice, so declining it is a real regression.
;
; WHY PER-FUNCTION IS SOUND. The draft counted module-wide to reach the ONE
; cross-function pairing that exists — a literal baked into a Phase-6 clone body,
; which `CloneFunctionInto` duplicates into the uncompute twin. That pairing now has
; its OWN fence at the duplication site (spec_reject_twin_undef_dup.ll), and the only
; other conceivable cross-function shape — a `__cq_q_f(poison)` forward and its
; `__cq_q_f_unc(out, poison)` adjoint — has both calls in the CALLER, so a
; per-function count still sees two. Every other adjoint the pass emits lands in the
; same function as its forward. DO NOT re-widen this to per-module without deleting
; that fence's reason to exist.
;
; AND DO NOT "sharpen" it to `Constant`-identity counting, which is the natural next
; idea: `undef`/`poison` are UNIQUED PER TYPE, so every `double undef` in a module is
; ONE `Constant *` and identity-keying would decline this fixture all over again.
;
; RESIDUAL, deliberately accepted: two independent single slots in ONE function still
; decline. Direction is safe and the measured population is zero — no TU across 966
; fixtures + 257 e2e + 251 openlibm modules has two undef-bearing gate slots in one
; function.
;
; GREEN ON BOTH plugins by design, so absent from the differential; its power is
; arm-kill — restore module-wide counting and it goes red.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; bd dm7f.81 MOVED THE SUBJECT: @cell_a/@cell_b's undef select arm is refined to
; zero and emits no gate (MergeArmWrite.cpp `armWriteIsNoop`), so the two cells
; now pin that refinement, and the per-function count is carried by @add_a/@add_b:
; one M-C `cqrt_addc_i32(h, undef)` slot each, in two different functions.
; Module-wide counting would see two slots and decline.
; CHECK-LABEL: define double @cell_a
; CHECK-NOT: undef
; CHECK-LABEL: define double @cell_b
; CHECK-NOT: undef
; CHECK-LABEL: define i32 @add_a
; CHECK: call void @cqrt_addc_i32(i32 %{{[a-z0-9_.]+}}, i32 undef)
; CHECK-LABEL: define i32 @add_b
; CHECK: call void @cqrt_addc_i32(i32 %{{[a-z0-9_.]+}}, i32 undef)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @cell_a(double %u0) {
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c = fcmp uno double %q, %q
  %a = select i1 %c, double undef, double %q
  %m = call double @cq_measure_f64(double %a)
  ret double %m
}

define double @cell_b(double %u1) {
  %q = call double @cq_theta_f64(double %u1, double 2.500000e-01)
  %c = fcmp uno double %q, %q
  %a = select i1 %c, double undef, double %q
  %m = call double @cq_measure_f64(double %a)
  ret double %m
}

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @add_a(i32 %x) {
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %d = add i32 %q, undef
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}

define i32 @add_b(i32 %x) {
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %d = add i32 %q, undef
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
