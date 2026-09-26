; spec_accept_phantom_arg_read_theta_source_inplace_mc.ll — ACCEPT, IN PLACE like the
; hand-inlined twin (bd test_C_libtooling-hgwx's C-reachable RESIDUAL after bd vsfp's
; drop; M-C `priorUseIsSettled` arm (d0)).
;
; bd hgwx's `j02C` (`t = h(q, m); u = t + q; ... Ry(.2) on u`) with the callee's
; parameter READ by `volatile int z = a;` — so the dead-argument drop leaves the call
; alone, the clone's own lowering erases the store, and the built `__cq_q_h_01` never
; reads `q`. `q` is a `cq_theta` result, which `declinePhantomCloneArgReads` exempts, so
; the module reaches `lowerOps`. There, on the oracle (`main` aee8f4f8) and before arm
; (d0), M-C's G7 counted that phantom call as an UNSETTLED prior reader of `q` and
; lowered `u = t + q` OUT of place (`cq_template_add_i32_hl`) — the Ry(.2) then acted on
; the copy while `q` kept the which-value record: DEPHASED (hgwx's analytic 0.070 vs
; 0.118). Arm (d0) asks the CALLEE'S PARAMETER: a call that passes `q` only in slots its
; body never reads does not read `q`, and neither can its `_unc` twin. The add lowers IN
; PLACE (`cqrt_addc_i32` on `q`'s handle) and the gate stream is TRACE-IDENTICAL to the
; twin's (`volatile int z = q; int t = m + 1; ...`), measured.
;
; ⚠ STILL WARNED, AND THE WARNING IS SPURIOUS: M-A's `isCloneCallHop` classifies every
; non-void `__cq_q_*` result as a RECORD by NAME, and a classical-verdict clone's result
; is plain data. The stream is the twin's; the warning is filed as bd jr8q and is
; deliberately NOT pinned here either way. RED on the oracle (out-of-place add).
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = t + q; int r = u; if (m > 3) r = cq_theta(u, .2); return cq_measure(r); }
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { volatile int z = a; return k + 1; }
;
; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll      (plain C, no CQ.h)
;   llvm-link -S caller.ll lib.ll -o <this file's body>
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=INPLACE < %t.cqd0.ll
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_addc_i32(i32 [[Q]], i32 [[T]])
; CHECK:      call void @cqrt_ry_i32(i32 [[Q]], double 2.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 [[Q]])
; INPLACE-NOT: cq_template_add_i32

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
  %3 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3)
  store volatile i32 %0, ptr %3, align 4, !tbaa !10
  %4 = add nsw i32 %1, 1
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3)
  ret i32 %4
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
