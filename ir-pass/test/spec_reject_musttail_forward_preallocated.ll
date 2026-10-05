; spec_reject_musttail_forward_preallocated.ll — DECLINE, loudly, where `main` 9a230646 and round 1 ABORTED (bd
; test_C_libtooling-m5pn round 2; Rule-13 r1B F-r1B-2, probe `pa2.ll`, verbatim; IR-only).
;
; `h(ptr preallocated(i32) %s, i32 %a){ musttail return h2(%s, %a); }`, `h2` reading `a`. A
; `preallocated` operand is legal only on a `musttail` call or on one carrying the
; `"preallocated"` operand bundle — which a forwarded argument has no token for — so the clone's
; demoted call is invalid IR and the verifier aborted the whole run (exit 134: round 1 with the
; bundle rule, the ORACLE also with the old `musttail … must precede a ret` rule). There is no
; valid plain-`tail` spelling to be identical to (r1B's `paN.ll` is exactly that spelling, and
; it is invalid input). `scanBody` now declines a lifted body that musttail-forwards a
; `preallocated` argument: a clean exit 1 with this string. IR-only: clang emits
; `preallocated` only for the 32-bit Windows C++ ABI. Since the owner's 2026-10-05 ruling (bd
; dm7f.5 review round 2) an `inalloca` forward is declined too, through the same shared
; predicate `mustTailForwardBlocksDemotion` — spec_reject_musttail_forward_inalloca.ll.
;
; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s
; CHECK-NOT: CQ_DEADARG_DBG
; CHECK: error: {{.*}}in function h{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (musttail forward of a preallocated argument)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @atoi(ptr)
declare token @llvm.call.preallocated.setup(i32)
declare ptr @llvm.call.preallocated.arg(token, i32)
define i32 @h2(ptr preallocated(i32) %s, i32 %x) noinline {
  %r = add i32 %x, 1
  ret i32 %r
}
define i32 @h(ptr preallocated(i32) %s, i32 %a) noinline {
  %r = musttail call i32 @h2(ptr preallocated(i32) %s, i32 %a)
  ret i32 %r
}
define i32 @main(i32 %argc, ptr %argv) {
  %g = getelementptr inbounds i8, ptr %argv, i64 8
  %sp = load ptr, ptr %g
  %m = call i32 @atoi(ptr %sp)
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %tok = call token @llvm.call.preallocated.setup(i32 1)
  %p = call ptr @llvm.call.preallocated.arg(token %tok, i32 0) preallocated(i32)
  store i32 3, ptr %p
  %r = call i32 @h(ptr preallocated(i32) %p, i32 %q) [ "preallocated"(token %tok) ]
  %mr = call i32 @cq_measure_si32(i32 %r)
  ret i32 %mr
}
