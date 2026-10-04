; spec_accept_dropped_arg_quantum_reader_outofplace.ll — ACCEPT, byte-identical to the
; oracle (bd test_C_libtooling-vsfp / hgwx — the CONTROL for M-C `priorUseIsSettled`
; arm (d0)'s per-slot READ test).
;
; `h(a, k) = a * 3 + k` READS `a`, so the clone `__cq_q_h_01(q, m)` is a real reader of
; `q` and `u = q + 5` (a Q+C add, an in-place candidate) sees it as a PRIOR USER. Arm
; (d0) settles a call only when every slot passing `q` is a parameter the callee never
; reads; here the slot is read, so (d0) does not apply, arm (d) refuses, and the add
; stays OUT of place — as on the oracle. MEASURED: the mutant "(d0) settles any call to
; a defined function passing `q`" lowers it IN place (`cqrt_addc_i32`), and this file
; is what catches it.
;
; ⚠ Whether that in-place lowering would be WRONG is a separate question and this file
; does not answer it. Arm (d)'s written hazard is a clone `_unc` twin re-reading `q`
; after the add, and the module-level spine never adjoints a clone call today
; (`Uncomputation.cpp`, `emitDagReversal`'s header: clone results are not rails). So
; settling a READING clone is plausibly sound — bd hgwx's "consult the verdict"
; suggestion goes further than (d0) — but it is an ACCEPT-direction widening of M-C that
; would owe its own argument and Rule-13 round. (d0) deliberately settles only a call
; that cannot read `q` at all; this file pins that boundary. The lyyf-(B) warning that
; fires is the oracle's too, and is not pinned.
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int q = m; cq_theta(&q, .5); int t = h(q, m); int u = q + 5; int r = u; cq_theta(&r, .2); return cq_measure(r) + cq_measure(t); }
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return a * 3 + k; }
;
; Regenerate (the tests/e2e/run_slice_multi.sh recipe, clang/llvm-link 19):
;   clang -O1 -emit-llvm -S -I<repo>/include -include CQ.h caller.c -o caller.ll
;   clang -O1 -emit-llvm -S lib.c -o lib.ll      (plain C, no CQ.h)
;   llvm-link -S caller.ll lib.ll -o <this file's body>
;
; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.err
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[0-9]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %{{[0-9]+}})
; CHECK-NEXT: [[U:%[a-z0-9._]+]] = call i32 @cq_template_add_i32_hl(i32 [[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[U]], double 2.000000e-01)
; CHECK-NOT:  cqrt_addc_i32
; CHECK:      ret i32
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
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call i32 @h(i32 noundef %6, i32 noundef %5) #4
  %8 = add nsw i32 %6, 5
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.000000e-01) #4
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %11 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = mul nsw i32 %0, 3
  %4 = add nsw i32 %3, %1
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
