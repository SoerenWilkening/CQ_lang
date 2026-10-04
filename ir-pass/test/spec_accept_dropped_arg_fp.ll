; spec_accept_dropped_arg_fp.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-vsfp — the FLOATING-POINT slot).
;
; `hf(double a, int k) = k + 1` ignores its `double` parameter; the operand `e = d * 2.0`
; is an fp template rail on the `double` register `d`. On the oracle (`main` aee8f4f8) the
; phantom read kept `e`'s `cq_template_fmul_f64_hl` rail live across `cq_theta(&d,
; .7)` — dephased, WARNED (`non-diagonal gate over a live derived record`). The drop's
; replacement constant is `Constant::getNullValue(double)`, i.e. `0.000000e+00` (+0.0,
; which no `nofpclass` clang emits at -O1 excludes; the attribute whitelist refuses any
; other parameter attribute anyway), and the stream is the twin's: Ry(.5), Ry(.7),
; measure, one handle, no warning.
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int hf(double a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); double d = (double)m; cq_theta(&d, .5); double e = d * 2.0; int t = hf(e, m); cq_theta(&d, .7); return t + (int)cq_measure(d); }
; Library TU (plain C, no CQ.h):
;   int hf(double a, int k) { return k + 1; }
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
; CHECK:      [[D:%[a-z0-9.]+]] = call i32 @cqrt_alloc_f64(double %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_f64(i32 [[D]], double 5.000000e-01)
; CHECK-NEXT: tail call i32 @hf(double noundef 0.000000e+00, i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_f64(i32 [[D]], double 0x3FE6666666666666)
; CHECK-NEXT: call double @cqrt_measure_f64(i32 [[D]])
; NORAIL-NOT: cq_template_fmul
; NORAIL-NOT: __cq_q_hf
; DROP: CQ_DEADARG_DBG: drop arg 0 of @hf in @main (inst)
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
  %6 = sitofp i32 %5 to double
  %7 = tail call double @cq_theta_f64(double noundef %6, double noundef 5.000000e-01) #4
  %8 = fmul double %7, 2.000000e+00
  %9 = tail call i32 @hf(double noundef %8, i32 noundef %5) #4
  %10 = tail call double @cq_theta_f64(double noundef %7, double noundef 0x3FE6666666666666) #4
  %11 = tail call double @cq_measure_f64(double noundef %10) #4
  %12 = fptosi double %11 to i32
  %13 = add nsw i32 %9, %12
  ret i32 %13
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @hf(double noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
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
