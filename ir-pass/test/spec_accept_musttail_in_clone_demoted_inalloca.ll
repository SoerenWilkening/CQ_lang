; spec_accept_musttail_in_clone_demoted_inalloca.ll — ACCEPT — a `musttail` forward of an `inalloca` argument inside a
; CLONE is demoted like any other (bd test_C_libtooling-m5pn round 2; r1B F-r1B-2's sibling;
; hand-written IR, IR-only).
;
; r1B's `pa2.ll` with `inalloca` in place of `preallocated` (last parameter, as the verifier
; requires). Unlike `preallocated`, a forwarded `inalloca` argument is legal on a PLAIN call
; (the verifier checks `inalloca` provenance only when the operand is an `alloca`), so after the
; demotion the module is byte-identical to its plain-`tail` spelling's — the owner's 2026-09-29
; invariant — and it is not declined. On `main` 9a230646 it ABORTED (exit 134, measured). Mutant
; V5 (the `preallocated` decline widened to `inalloca`) turns this file into a decline.
;
; Twin (trace-compared, tools/pairs.py): its plain-`tail` spelling `r2/iaN.ll` (byte-identical traces, measured).
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of each function (derived from the lowered module; SSA
; names wildcarded, constants — every dropped `0` and every angle — kept). Between
; consecutive matches NO other runtime/clone call may appear, so the stream is pinned
; EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @atoi(ptr %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_h_01(i32 %{{[a-zA-Z0-9_.]+}}, ptr inalloca(i32) %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret 
; CLONE-LABEL: define {{.*}}@h(
; CLONE-NEXT: musttail call i32 @h2(
; CLONE-LABEL: define internal i32 @__cq_q_h_01(
; CLONE-NOT: musttail
; CLONE: call i32 @__cq_q_h2_01(i32 %a, ptr inalloca(i32) %s)
; CLONE-NOT: musttail
; CLONE: ret i32
; NODROP-NOT: CQ_DEADARG_DBG

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
