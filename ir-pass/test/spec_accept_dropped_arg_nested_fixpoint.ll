; spec_accept_dropped_arg_nested_fixpoint.ll — ACCEPT with the hand-inlined twin's stream
; (bd test_C_libtooling-vsfp ROUND 2 — the drop's FIXPOINT, four TUs deep).
;
; `o4 -> m4 -> n4 -> i4`, one per TU, each forwarding `a` to the next; only `i4` ignores it.
; Each drop makes the next caller's parameter dead, so the chain needs FOUR turns. The
; drop's two slots give two turns for free, which is why the 2-link
; `spec_accept_dropped_arg_nested.ll` could not pin the fixpoint (measured: the one-turn
; mutant passed it). Here the one-turn mutant leaves `o4(p, m)` reading the 4.4 `%out`,
; and the phantom-read backstop declines it. The four census lines, innermost first,
; pin the order. Twin: `int t = ((m + 1 - 1) + 3) * 2 + m;` — no gate but the two Ry.
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int o4(int a, int b);
;   int main(int c, char **v) { int m = atoi(v[1]); _Bool b = (_Bool)(m & 1); cq_theta(&b, .5); int p = b ? 9 : 4; int t = o4(p, m); cq_theta(&b, .7); return t + cq_measure(b); }
; Library TU 1 (plain C, no CQ.h):
;   int m4(int a, int b);
;   int o4(int a, int b) { return m4(a, b) * 2 + b; }
; Library TU 2 (plain C, no CQ.h):
;   int n4(int a, int b);
;   int m4(int a, int b) { return n4(a, b) + 3; }
; Library TU 3 (plain C, no CQ.h):
;   int i4(int a, int b);
;   int n4(int a, int b) { return i4(a, b) - 1; }
; Library TU 4 (plain C, no CQ.h):
;   int i4(int a, int k) { return k + 1; }
;
; Regenerate: as tests/e2e/run_slice_multi.sh, one `clang -O1` per library TU, then
;   llvm-link -S caller.ll lib.ll lib2.ll … lib4.ll -o <this file's body>
;
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=DROP < %t.err
;
; The ordered call sequence of @main (derived from the lowered module; SSA names
; wildcarded, constants — every dropped `0` and every angle — kept):
; Between consecutive matches NO other runtime/clone call may appear, so the
; runtime stream is pinned EXACTLY, not as a subsequence.
; CHECK-LABEL: define {{.*}}@main(
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @atoi(ptr nocapture noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @cqrt_alloc_i1(i1 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i32 @o4(i32 noundef 0, i32 noundef %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call void @cqrt_ry_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 0x3FE6666666666666)
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: call i1 @cqrt_measure_i1(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}
; CHECK: ret i32
;
; Callees the ORACLE emitted in @main and this lowering must not:
; NEG-LABEL: define {{.*}}@main(
; NEG-NOT: @__cq_q_o4_01(
; NEG-NOT: @cqrt_alloc_i32(
; NEG-NOT: @cqrt_cnot(
; NEG-NOT: @cqrt_copy_i32_controlled(
; NEG-NOT: @cqrt_free(
; NEG-NOT: @cqrt_x(
; NEG: ret i32
; DROP: CQ_DEADARG_DBG: drop arg 0 of @i4 in @n4 (arg)
; DROP: CQ_DEADARG_DBG: drop arg 0 of @n4 in @m4 (arg)
; DROP: CQ_DEADARG_DBG: drop arg 0 of @m4 in @o4 (arg)
; DROP: CQ_DEADARG_DBG: drop arg 0 of @o4 in @main (inst)

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
  %10 = tail call i32 @o4(i32 noundef %9, i32 noundef %5) #4
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %8, double noundef 0x3FE6666666666666) #4
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #4
  %13 = zext i1 %12 to i32
  %14 = add nsw i32 %10, %13
  ret i32 %14
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @o4(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @m4(i32 noundef %0, i32 noundef %1) #4
  %4 = shl nsw i32 %3, 1
  %5 = add nsw i32 %4, %1
  ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483645, -2147483648) i32 @m4(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @n4(i32 noundef %0, i32 noundef %1) #4
  %4 = add nsw i32 %3, 3
  ret i32 %4
}

; Function Attrs: nounwind ssp uwtable
define range(i32 -2147483648, 2147483647) i32 @n4(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @i4(i32 noundef %0, i32 noundef %1) #4
  %4 = add nsw i32 %3, -1
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @i4(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0, !0, !0, !0}
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
