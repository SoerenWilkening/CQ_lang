; spec_reject_musttail_forward_inalloca.ll — DECLINE (bd test_C_libtooling-dm7f.5 review round
; 2; OWNER RULING 2026-10-05: a `musttail` forward of the caller's own `inalloca` argument is
; refused in BOTH demotion paths). This is the CLONE-path decline: a lifted body (`h`, called
; with a quantum argument) whose `musttail` forwards its incoming `inalloca` argument to `h2`.
;
; HISTORY — FLIPPED from an accept. This module was
; `spec_accept_musttail_in_clone_demoted_inalloca.ll` (bd m5pn round 2): the clone's
; `stripStaleClassicalAttrs` demoted the `musttail` and the module was byte-identical to its
; plain-`tail` spelling — the owner's 2026-09-29 invariant ("a forwarded `inalloca` argument is
; legal on a plain call; the verifier checks `inalloca` provenance only when the operand is an
; `alloca`"). The ruling of 2026-10-05 supersedes that invariant for `inalloca`: LangRef — a
; `musttail` call forwards an `inalloca` argument IN PLACE, and on any other call the operand
; must be the `alloca` set up for that call; the plain spelling was verifier-clean and invalid.
; `scanBody` now declines it through `mustTailForwardBlocksDemotion` (ReturnMerge.h), the ONE
; predicate the module-level `ret` merge asks too (control_multiexit_reject_inalloca_musttail.ll),
; with the same words as the `preallocated` forward
; (spec_reject_musttail_forward_preallocated.ll). The file's old mutant note ("V5, the
; `preallocated` decline widened to `inalloca`, turns this file into a decline") is now the
; shipped code. IR-only: clang emits `inalloca` only for the 32-bit Windows C++ ABI.
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error: {{.*}}in function h{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (musttail forward of an inalloca argument)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @atoi(ptr)
define i32 @h2(i32 %x, ptr inalloca(i32) %s) noinline {
  %r = add i32 %x, 1
  ret i32 %r
}
define i32 @h(i32 %a, ptr inalloca(i32) %s) noinline {
  %r = musttail call i32 @h2(i32 %a, ptr inalloca(i32) %s)
  ret i32 %r
}
define i32 @main(i32 %argc, ptr %argv) {
  %g = getelementptr inbounds i8, ptr %argv, i64 8
  %sp = load ptr, ptr %g
  %m = call i32 @atoi(ptr %sp)
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = alloca inalloca i32
  store i32 3, ptr %p
  %r = call i32 @h(i32 %q, ptr inalloca(i32) %p)
  %mr = call i32 @cq_measure_si32(i32 %r)
  ret i32 %mr
}
