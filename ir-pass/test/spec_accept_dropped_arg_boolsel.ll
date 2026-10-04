; spec_accept_dropped_arg_boolsel.ll — ACCEPT with the hand-inlined twin's stream (bd
; test_C_libtooling-vsfp, P1 SILENT DEPHASING; bd 9bhg Rule-13 r2A F-9C-1, probe `b15`).
;
; THE DEFECT, on the oracle (`main` aee8f4f8). `h(a, k) = k + 1` ignores `a`, yet the
; call `h(p, m)` kept READING `p`: a Phase-6 site whose clone `__cq_q_h_01` never
; looks at its parameter 0 (bd hgwx's root cause, a phantom read). `p = b ? 9 : 4` is
; a 4.4 data select on a bare `_Bool`, so round-1 control emission minted its `%out`
; rail — two `cqrt_copy_i32_controlled` under a CNOT copy of `b`, i.e. a WHICH-PATH
; copy of `b` — and the phantom read was that rail's only reader. It was left
; allocated and entangled with `b` across `cq_theta(&b, .7)`, so the Ry acted on a
; register whose branches were tagged: a DEPHASED circuit (analytic, r2A §F-9C-1:
; P(b=1) for odd m is cos^2(.6) = 0.6812 in the twin and 0.8356 here). `opt` exit 0,
; ZERO bytes of warnings (the lyyf-(B) warning does not model value-merge rails),
; stage 2b STRICT clean.
;
; THE FIX. `dropDeadCallArguments` (SpecializeDetect.h) runs before any stage reads an
; argument: `h`'s parameter 0 has no uses, so the operand becomes `0` and `p`'s cone
; (the select) is deleted — what `clang -O1` does to the twin (`int t = m + 1;`).
; Nothing is minted for `p`, no clone is built, and the stream is the twin's:
; Ry(.5), Ry(.7), one measurement, all on ONE handle. RED on the oracle: CHECK and
; NORAIL both fail there (it mints `%out` and calls `__cq_q_h_01`).
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); _Bool b = (_Bool)(m & 1); cq_theta(&b, .5); int p = b ? 9 : 4; int t = h(p, m); cq_theta(&b, .7); return t + cq_measure(b); }
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return k + 1; }
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
; CHECK-NEXT: tail call i32 @h(i32 noundef 0, i32 noundef %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[B]], double 0x3FE6666666666666)
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 [[B]])
; No which-path rail and no clone anywhere in the module (own prefix: whole file).
; NORAIL-NOT: cqrt_copy_i32_controlled
; NORAIL-NOT: __cq_q_h
; DROP: CQ_DEADARG_DBG: drop arg 0 of @h in @main (inst)
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
  %10 = tail call i32 @h(i32 noundef %9, i32 noundef %5) #4
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

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
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
