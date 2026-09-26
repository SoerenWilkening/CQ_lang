; taint_reject_quantum_return_lift_owner_order.ll — DECLINE (bd test_C_libtooling-9bhg × bd
; test_C_libtooling-d88e: the composed post-specialize() SLOT ORDER).
;
; A TWO-TU module (caller TU `-include CQ.h`, llvm-linked with a plain-C library
; TU, as tests/e2e/run_slice_multi.sh builds one). Written at the merge of `main`
; (d88e) into the 9bhg branch: before that merge neither owner below existed on
; one binary, so no fixture could pin their relative order.
;
; `f` holds BOTH hazards the post-`specialize()` window re-asks:
;  * a one-register lift `r = t; if (m > 3) r = cq_theta(t, .2);` over
;    `t = hc(q, m)`, a spec site whose clone proves the CLASSICAL `k + 1`. The
;    lift's premise is falsified by the scrub, so bd d88e's
;    `declineFalsifiedMergePhiLifts` fires;
;  * a RETURN of `t2 = hq(q, m + 2)`, a spec site whose clone proves QUANTUM
;    (`a + k`). That return is provisional at propagation, so bd 9bhg's LATE
;    `declineQuantumReturnCalls` would fire too.
; `LLVMContext::diagnose` exits on the first DS_Error (bd br4a), so the ORDER picks
; the owner. The d88e re-ask runs FIRST, and that matches the hand-inlined twin
; (`t = m + 1`, `hq` kept). There the lift base is classical from propagation
; onward, so `declineClassicalMuxes` speaks with this same string long before any
; 3jru ask. Measured at the merge (merged `cq-opt` 242f8b61): this module's stderr
; is BYTE-IDENTICAL to the twin's. On the 9bhg-alone binary (8b837d1f) it declined
; with the 3jru string instead, i.e. twin-DIFFERENT.
;
; Mutant (TRACK_9BHG §10): moving the late 3jru ask ABOVE the d88e re-ask turns
; this file red (the 3jru string speaks, in `main`).
;
; Library TU (plain C, no CQ.h):
;   int hc(int a, int k) { return k + 1; }
;   int hq(int a, int k) { return a + k; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int hc(int a, int k); int hq(int a, int k);
;   __attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = hc(q, m); int t2 = hq(q, m + 2); int r = t; if (m > 3) r = cq_theta(t, .2); return t2 + cq_measure(r); }
;   int main(int c, char **v) { int m = atoi(v[1]); return f(m); }
;
; Regenerate: clang -O1 -emit-llvm -S each TU as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='quantum value returned'
; CHECK: in function f {{.*}}: cq taint escape: tainted value muxed by a classical-condition phi

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #5
  %3 = tail call i32 @hc(i32 noundef %2, i32 noundef %0) #5
  %4 = add nsw i32 %0, 2
  %5 = tail call i32 @hq(i32 noundef %2, i32 noundef %4) #5
  %6 = icmp sgt i32 %0, 3
  br i1 %6, label %7, label %9

7:                                                ; preds = %1
  %8 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.000000e-01) #5
  br label %9

9:                                                ; preds = %7, %1
  %10 = phi i32 [ %8, %7 ], [ %3, %1 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #5
  %12 = add nsw i32 %11, %5
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #2 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @f(i32 noundef %5)
  ret i32 %6
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483647, -2147483648) i32 @hc(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @hq(i32 noundef %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
