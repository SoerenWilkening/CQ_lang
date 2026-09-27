; lowering_volatile_globalfold_cascade.ll — ACCEPT with the twin's stream (bd
; test_C_libtooling-1xp9; r3B probe `u1`, the GLOBAL-fold path; hand-written IR).
;
; Two never-stored internal volatile globals (`@KB`, an `i1` read as the second branch's
; condition φ; `@K2`, the second merge's φ incoming). Round 3 segfaulted (exit 139). Round 4:
; the tracked seed follows the first φ to its replacement and the fold asks the folder
; (`simplifySelectInst`; NOT what SimplifyCFG does — it builds with NoFolder and -O1 loses the
; select in InstCombine, bd w9xe), so `select %c, i1 true, i1 false` IS `%c` and the second φ becomes
; `select %c, 5, 9` — the twin `u1T.ll`. Without the folder the logical select would be a 4.4
; data select's condition, which that grammar refuses (an over-decline; oracle declined too).
; The second RUN line is the deterministic use-after-free pin (test allocator, `nofree`).
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
; CHECK: call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_x(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 9)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_x(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
; NODROP-NOT: CQ_DEADARG_DBG

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
@KB = internal global i1 true, align 1
@K2 = internal global i32 5, align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %a1, label %s1
a1:
  %kb = load volatile i1, ptr @KB, align 1
  br label %s1
s1:
  %p = phi i1 [ %kb, %a1 ], [ false, %entry ]
  br i1 %p, label %a2, label %s2
a2:
  %k = load volatile i32, ptr @K2, align 4
  br label %s2
s2:
  %r = phi i32 [ %k, %a2 ], [ 9, %s1 ]
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %m3 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m1, %m3
  ret i32 %s
}
