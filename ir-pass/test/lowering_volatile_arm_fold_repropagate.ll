; lowering_volatile_arm_fold_repropagate.ll — ACCEPT with the fenv-intended twin's stream (bd
; test_C_libtooling-otam; bd vsfp Rule-13 r2A F-WA-1, probe `stale3c`; red-green).
;
; A quantum-conditioned diamond whose merge has a two-entry φ; the fenv STORE ERASURE empties the arm (`{ volatile int z = 1; r = 5; }`).
; The stage's `deleteDeadCones` folds the emptied arm and turns the φ into
; `select (q > 3), 5, 9` — a NEW value, tainted through its condition. Round 2 ignored the
; stage's return and never re-propagated: control detection (keyed on the tainted
; condition) still claimed the select and RAUW'd it to its `%out` rail HANDLE, while every
; taint consumer saw it CLASSICAL — `f(r)` was not lifted (`f` got the handle as data) and
; the user's `cq_measure` lowered as a never-quantum measure and VANISHED (exit 0, 0 bytes of
; stderr, 2b STRICT clean). Round 3: every volatile stage re-propagates when it changed the
; IR, and `declineStaleTaintSet` checks the whole pre-pass window before
; `detectSpecializations` (drop either re-propagate and this file DECLINES loudly — the
; mutation rows). RED on round 2 (FileCheck), a decline on the oracle and on round 1.
;
; Caller TU (clang -O1 -include CQ.h):
;   __attribute__((noinline)) int f(int x) { return x * 2 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, 0.7);
;     int r;
;     if (q > 3) { volatile int z = 1; r = 5; } else { r = 9; }
;     return cq_measure(f(r));
;   }
;
; Regenerate: clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o <body>
;
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
;
; The ordered call sequence of @main (derived from the lowered module; SSA names
; wildcarded, constants — every dropped `0` and every angle — kept):
; Between consecutive matches NO other runtime/clone call may appear, so the
; runtime stream is pinned EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3FE6666666666666)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_xorc_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_x(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_xorc_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 9)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_x(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_free(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @__cq_q_f_1(i32 noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_measure_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
; NODROP-NOT: CQ_DEADARG_DBG

; ModuleID = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp/r3p/stale3c.c'
source_filename = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp/r3p/stale3c.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = shl nsw i32 %0, 1
  %3 = or disjoint i32 %2, 1
  ret i32 %3
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #1 {
  %1 = alloca i32, align 4
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #4
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %5

4:                                                ; preds = %0
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1)
  store volatile i32 1, ptr %1, align 4, !tbaa !6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1)
  br label %5

5:                                                ; preds = %0, %4
  %6 = phi i32 [ 5, %4 ], [ 9, %0 ]
  %7 = tail call i32 @f(i32 noundef %6)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  ret i32 %8
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
