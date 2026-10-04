; spec_accept_phantom_arg_read_theta_source_inplace_mc.ll — ACCEPT, IN PLACE like the
; hand-inlined twin (bd test_C_libtooling-vsfp / bd hgwx). Re-spelled in round 2
; (branch-only read, below); subject changed in round 3.
;
; `t = h(q, m)` passes `q` only in a slot the specializer RECORDED dead. Round 2 settled
; that call as a prior user of `q` through M-C arm (d0); since round 3 the slot is
; neutralised to `0` first, so the call is not a user of `q` at all and `u = t + q` lowers
; IN PLACE (`cqrt_addc_i32(q, t)`) exactly as in the twin (`int t = m + 1;`). (d0) stays the
; one spelling of the question for an inner clone call, where no neutralisation runs.
; ⚠ ROUND 3 (bd tzfa; Rule-13 r2B F-WB-1). A slot the specializer RECORDED dead is now
; NEUTRALISED after `specialize()` (`resolvePhantomCloneArgReads`: the argument becomes `0`,
; the drop's rewrite), so the uncompute spine, M-C, M-A and stage 2b see the hand-inlined
; twin's consumer set. Round 2 instead ACCEPTED a phantom read whose operand had another
; reader and left the read in place — one consumer too many for the spine.
;
; ⚠ WHY HAND-WRITTEN IR (bd vsfp round 2). The callee's only read of `a` is a
; BRANCH-ONLY one — an empty diamond on `a > 3`. The pass's liveness predicate has no
; control dependence (`DeadValueLiveness.h` LIMITS), so `a` is LIVE in the ORIGINAL
; `@h` and the dead-argument drop (both slots) does NOT fire; the CLONE's own control
; flatten then removes the branch, and `buildClone` RECORDS slot 0 dead
; (`taint.SpecDeadArgMask`). That is the one route by which a phantom read still
; reaches the post-`specialize()` backstop. It is IR-only: `clang -O1` deletes an
; empty diamond in the library TU. Round 1 spelled this file with `volatile int z = a;`,
; which bd vsfp r1B F-VB-3 showed is erased by the MODULE fenv pre-pass on the
; ORIGINAL callee — predictable pre-emission, and since round 2 the drop's slot B
; predicts it (see `spec_reject_phantom_arg_read_volatile_callee.ll`, now an accept).
;
; Caller: `int q = m; cq_theta(&q, .5); int t = h(q, m); int u = t + q; int r = u; if (m > 3) { r = u; cq_theta(&r, .2); } return cq_measure(r);`
;
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of @main (derived from the lowered module; SSA names
; wildcarded, constants — every dropped `0` and every angle — kept):
; Between consecutive matches NO other runtime/clone call may appear, so the
; runtime stream is pinned EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @atoi(ptr nocapture noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_addc_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 2.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
;
; Callees the ORACLE emitted in @main and this lowering must not:
; NEG-LABEL: define {{.*}}@main(
; NEG-NOT: @cq_template_add_i32_hl(
; NEG: ret i32
; NODROP-NOT: CQ_DEADARG_DBG

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #5
  %7 = tail call i32 @h(i32 noundef %6, i32 noundef %5) #5
  %8 = add nsw i32 %7, %6
  %9 = icmp sgt i32 %5, 3
  br i1 %9, label %10, label %12

10:                                               ; preds = %2
  %11 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #5
  br label %12

12:                                               ; preds = %10, %2
  %13 = phi i32 [ %11, %10 ], [ %8, %2 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13) #5
  ret i32 %14
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nofree norecurse nounwind ssp memory(inaccessiblemem: readwrite) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %vsfp.c = icmp sgt i32 %0, 3   ; a BRANCH-ONLY read: live in @h, removed by the CLONE's own flatten
  br i1 %vsfp.c, label %vsfp.arm, label %vsfp.join
vsfp.arm:
  br label %vsfp.join
vsfp.join:
  %vsfp.r = add nsw i32 %1, 1
  ret i32 %vsfp.r
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree norecurse nounwind ssp memory(inaccessiblemem: readwrite) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
