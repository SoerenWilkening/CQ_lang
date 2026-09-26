; spec_accept_dropped_arg_quantum_clone_dead_slot.ll — ACCEPT with the hand-inlined twin's
; stream (bd test_C_libtooling-vsfp — a member NO earlier record named: the phantom read
; of a SPEC-QUANTUM clone).
;
; `h3(a, b, k) = b + k` reads `b` (a genuine quantum argument: the clone's verdict is
; QUANTUM) and ignores `a`. On the oracle (`main` aee8f4f8) the site's mask was `011`:
; `__cq_q_h3_011(%out, q, m)`, whose clone never looks at slot 0 — and `%out` is the 4.4
; bool-select rail of `p = b ? 9 : 4`, a which-path copy of `b`, left entangled across
; `b = cq_theta(b, .7)`. Silent, stage 2b clean. So the class is "a clone that does not
; read a slot it is passed", not "a classical-verdict clone" — the verdict is irrelevant.
; With the drop the mask is `010`: the clone reads exactly what it is given, `p` is
; never computed, and the stream is the twin's (`int t = q + m;`): the clone's
; Bennett copy-out of `q + m` is unchanged, the bool register sees Ry(.5), Ry(.7).
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h3(int a, int b, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int q = cq_theta(m, .3); int t = h3(p, q, m); b = cq_theta(b, .7); return cq_measure(t) + cq_measure(b); }
; Library TU (plain C, no CQ.h):
;   int h3(int a, int b, int k) { return b + k; }
;
; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll      (plain C, no CQ.h)
;   llvm-link -S caller.ll lib.ll -o <this file's body>
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NORAIL < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[B:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i1(i1 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 5.000000e-01)
; CHECK-NEXT: [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 3.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h3_010(i32 noundef 0, i32 noundef [[Q]], i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 0x3FE6666666666666)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 [[T]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 [[B]])
; NORAIL-NOT: cqrt_copy_i32_controlled
; NORAIL-NOT: __cq_q_h3_011
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h3 in @main (inst)
; DROP-NOT: warning

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 1
  %7 = icmp ne i32 %6, 0
  %8 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef 5.000000e-01) #4
  %9 = select i1 %8, i32 9, i32 4
  %10 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 3.000000e-01) #4
  %11 = tail call i32 @h3(i32 noundef %9, i32 noundef %10, i32 noundef %5) #4
  %12 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 0x3FE6666666666666) #4
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %14 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %12) #4
  %15 = zext i1 %14 to i32
  %16 = add nsw i32 %13, %15
  ret i32 %16
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h3(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #3 {
  %4 = add nsw i32 %2, %1
  ret i32 %4
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

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
