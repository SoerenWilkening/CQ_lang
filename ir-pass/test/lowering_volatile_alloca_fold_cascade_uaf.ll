; lowering_volatile_alloca_fold_cascade_uaf.ll — ACCEPT with the twin's stream, under the plain
; allocator AND under the deterministic test allocator (bd test_C_libtooling-1xp9; r3B probe
; `u2`, the ALLOCA-fold path; hand-written IR).
;
; On rounds 2–3 this was SILENT UB under the system allocator (exit 0 — the freed φ's bytes
; happened to read back) and SIGSEGV under Guard Malloc. The `%debugalloc-cq-opt` driver makes
; that deterministic: under `CQ_OPT_DEBUG_ALLOC=nofree` a freed instruction's parent pointer is
; null, and the round-3 objects crash on it every time (measured, exit 139, also under `lifo`).
; The second RUN line is therefore the use-after-free pin; the first pins the twin's stream.
;
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: env CQ_OPT_DEBUG_ALLOC=nofree %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.nofree.ll
; RUN: %filecheck %s < %t.nofree.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of @main (derived from the lowered module; SSA names
; wildcarded, constants — every dropped `0` and every angle — kept):
; Between consecutive matches NO other runtime/clone call may appear, so the
; runtime stream is pinned EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
; NODROP-NOT: CQ_DEADARG_DBG

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %z = alloca i1, align 1
  store volatile i1 true, ptr %z, align 1
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %a1, label %s1
a1:
  %kb = load volatile i1, ptr %z, align 1
  br label %s1
s1:
  %p = phi i1 [ %kb, %a1 ], [ false, %entry ]
  br i1 %p, label %a2, label %s2
a2:
  %k = load volatile i1, ptr %z, align 1
  br label %s2
s2:
  %m1 = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m1
}
