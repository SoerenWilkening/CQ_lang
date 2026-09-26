; spec_accept_fp_rebuilt_site_second_clone.ll — ACCEPT (bd test_C_libtooling-9bhg).
;
; A TWO-TU module (caller TU `-include CQ.h`, llvm-linked with a plain-C library
; TU, as tests/e2e/run_slice_multi.sh builds one). Two top-level Phase-6 sites in
; one function, BOTH with an f80 RETURN (so `retargetSite` REBUILDS each call as an
; i32-returning one and ERASES the old call), the second consuming the first's
; result beside a second register: `y = lpoly(q); z = lmix(y, q2)`.
;
; It pins two things this bead's ordered scrub made load-bearing:
;  * the REBUILT first call is re-inserted into `taint.Tainted` at resolution, so
;    the second site's RECOMPUTED mask still has slot 0 quantum
;    (`__cq_q_lmix_11(%1, %h1)`, not `_10` with an i32 handle in an fp literal
;    slot) — mutant M17;
;  * the ERASED old call's key must not survive in the module taint. Before it
;    was removed, the second clone's `ret` value was allocated at the freed
;    address, answered "tainted", and the post-`specialize()` re-ask of
;    `declineQuantumReturnCalls` refused this CORRECT module. This was measured
;    on the first bd 9bhg subject; the 983f9361 oracle never asked, so the
;    dangling key had no observable consumer there.
;    - Since bd 8e5r the key is dropped by the self-cleaning `taint.Tainted`
;      (`ScrubOnDelete.h`) at the deletion inside `retargetSite`.
;    - 9bhg's own post-hoc erase was deleted at the 8e5r merge (r1B-8e5r F-EB-9):
;      it erased by an already-dead pointer.
;    - ⚠ The failure depends on the allocator. Under the system allocator it varies
;      from RUN to run (9bhg's M18 mutant: 3/5, Rule-13 r1B F-9B-3), so a single
;      `%cq-opt` run was a FLAKY pin.
;    - Since the 8e5r merge this file runs three allocator modes, bd 8e5r's
;      pattern:
;      - `lifo` (maximal exact-class address reuse, `%debugalloc-cq-opt`) is
;        FileChecked;
;      - `nofree` (no reuse, the reference) and the system allocator must be
;        byte-identical to it.
;      Positive control (TRACK_9BHG §11): with `Set::Core::keyDeleted`'s
;      dead-mark disabled, this file goes red in 3 of 3 lit runs.
;    Other producers of the dangling-key class are bd 8e5r / j8sk.
; The stream is byte-identical to the 983f9361 oracle's and to aad63450's.
;
; Library TU (plain C, no CQ.h) — tests/e2e/spec_fp_arg_lib.c plus:
;   long double lmix(long double x, long double w) { return x * w + 0.5L; }
;
; Caller TU (clang -O1 -include CQ.h):
;   long double lpoly(long double x);
;   long double lmix(long double x, long double w);
;   long double slice(void) {
;       long double q = cq_theta((long double)3.0L, 0.5);
;       long double y = lpoly(q);
;       long double q2 = cq_theta((long double)2.0L, 0.25);
;       long double z = lmix(y, q2);
;       return cq_measure(z);
;   }
;   int main(void) { (void) slice(); return 0; }
;
; Regenerate: clang -O1 -emit-llvm -S each TU as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; Three allocator modes (bd 8e5r's pattern). An `error:` exits non-zero and fails
; the RUN line itself: no `not`, and stdout alone goes to the files.
; RUN: env CQ_OPT_DEBUG_ALLOC=lifo %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.lifo.ll
; RUN: env CQ_OPT_DEBUG_ALLOC=nofree %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.nofree.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.sys.ll
; RUN: %filecheck %s --implicit-check-not=__cq_q_lmix_10 < %t.lifo.ll
; RUN: diff %t.lifo.ll %t.nofree.ll
; RUN: diff %t.lifo.ll %t.sys.ll
; CHECK-LABEL: define x86_fp80 @slice(
; CHECK: %h = call i32 @cqrt_alloc_f80(x86_fp80 0xK4000C000000000000000)
; CHECK-NEXT: call void @cqrt_ry_f80(i32 %h, double 5.000000e-01)
; CHECK-NEXT: [[Y:%[0-9]+]] = call i32 @__cq_q_lpoly_1(i32 %h)
; CHECK-NEXT: %h1 = call i32 @cqrt_alloc_f80(x86_fp80 0xK40008000000000000000)
; CHECK-NEXT: call void @cqrt_ry_f80(i32 %h1, double 2.500000e-01)
; CHECK-NEXT: [[Z:%[0-9]+]] = call i32 @__cq_q_lmix_11(i32 [[Y]], i32 %h1)
; CHECK-NEXT: %m = call x86_fp80 @cqrt_measure_f80(i32 [[Z]])
; CHECK-NEXT: ret x86_fp80 %m
; CHECK-LABEL: define noundef i32 @main(
; CHECK: [[Y2:%[0-9]+]] = call i32 @__cq_q_lpoly_1(i32 %h)
; CHECK: call i32 @__cq_q_lmix_11(i32 [[Y2]], i32 %h1)

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @slice() local_unnamed_addr #0 {
  %1 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef 0xK4000C000000000000000, double noundef 5.000000e-01) #4
  %2 = tail call x86_fp80 @lpoly(x86_fp80 noundef %1) #4
  %3 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef 0xK40008000000000000000, double noundef 2.500000e-01) #4
  %4 = tail call x86_fp80 @lmix(x86_fp80 noundef %2, x86_fp80 noundef %3) #4
  %5 = tail call x86_fp80 @cq_measure_f80(x86_fp80 noundef %4) #4
  ret x86_fp80 %5
}

declare x86_fp80 @cq_theta_f80(x86_fp80 noundef, double noundef) local_unnamed_addr #1

declare x86_fp80 @cq_measure_f80(x86_fp80 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef 0xK4000C000000000000000, double noundef 5.000000e-01) #4
  %2 = tail call x86_fp80 @lpoly(x86_fp80 noundef %1) #4
  %3 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef 0xK40008000000000000000, double noundef 2.500000e-01) #4
  %4 = tail call x86_fp80 @lmix(x86_fp80 noundef %2, x86_fp80 noundef %3) #4
  %5 = tail call x86_fp80 @cq_measure_f80(x86_fp80 noundef %4) #4
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef x86_fp80 @lpoly(x86_fp80 noundef %0) local_unnamed_addr #2 {
  %2 = fmul x86_fp80 %0, %0
  %3 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %2, x86_fp80 0xK3FFE8000000000000000, x86_fp80 %0)
  ret x86_fp80 %3
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare x86_fp80 @llvm.fmuladd.f80(x86_fp80, x86_fp80, x86_fp80) #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef x86_fp80 @lmix(x86_fp80 noundef %0, x86_fp80 noundef %1) local_unnamed_addr #2 {
  %3 = tail call x86_fp80 @llvm.fmuladd.f80(x86_fp80 %0, x86_fp80 %1, x86_fp80 0xK3FFE8000000000000000)
  ret x86_fp80 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
