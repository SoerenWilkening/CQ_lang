; loop_acc_dead_measured_warn.ll — ACCEPT WITH A WARNING (bd test_C_libtooling-01po.19.18.1;
; delegated ruling ruling-01po19-18-dead-accumulator-leak-warn-2026-10-16, option (a)).
;
; SOURCE (clang -O1, verbatim below):
;   int main(void) {
;       int a = 0;
;       cq_theta(&a, 1.0);
;       int c = 0;
;       for (int i = 0; i < 3; i++) {
;           if (c == 1) cq_phi(0.5);
;           c += a;
;       }
;       printf("%d %d\n", cq_measure(a), cq_measure(c));
;       return 0;
;   }
;
; `-O1` closed-forms the exit read of `c` as `mul a, 3` (computed from the SOURCE),
; so the seeded accumulator's register `%cq.acc` is never read after the loop: a
; DEAD RECORD of `a`. Its only source `a` is afterwards only READ (the `mul`
; template) and MEASURED — measurement is not a move (dead-record-live-across-move
; ruling), so no measured statistic changes. The register cannot be reversed in
; the rolled form yet, so it is LEFT ALLOCATED (R5: never freed, not provably
; |0>) and the pass says so on stderr (lyyf class, DS_Warning; `opt` exits 0).
; ANALYTIC: `cqrt_ry_i32` rotates every qubit of `a` (backend.md §11.3), so each
; bit of `a` is 1 independently with probability sin^2(.5) = 0.229849; the measured
; pair is (a, 3a mod 2^32), and `%cq.acc` ends holding 3a. (Corrected R11 round 2
; rA2-F2: an earlier text used a low-bit-only model.)
; RETIREMENT TRIGGER: bd 8h7d.20's post-loop reverse loop uncomputes `%cq.acc`
; after the loop; the warning then disappears and a `cqrt_free(%cq.acc)` appears.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s < %t.ll
; WARN: warning: {{.*}}cq loop lowering: dead loop accumulator left allocated; its sources are only measured afterwards
; CHECK: %cq.acc = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_add_i32(i32 %h, i32 %cq.acc), !cq.inplace.qq
; CHECK-NOT: cqrt_free(i32 %cq.acc)

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1

define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #3
  br label %7

2:                                                ; preds = %12
  %3 = mul i32 %1, 3
  %4 = tail call i32 @cq_measure_si32(i32 noundef %1) #4
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #4
  %6 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %4, i32 noundef %5)
  ret i32 0

7:                                                ; preds = %0, %12
  %8 = phi i32 [ 0, %0 ], [ %14, %12 ]
  %9 = phi i32 [ 0, %0 ], [ %13, %12 ]
  %10 = icmp eq i32 %9, 1
  br i1 %10, label %11, label %12

11:                                               ; preds = %7
  tail call void @cq_phi(double noundef 5.000000e-01) #4
  br label %12

12:                                               ; preds = %11, %7
  %13 = add nsw i32 %9, %1
  %14 = add nuw nsw i32 %8, 1
  %15 = icmp eq i32 %14, 3
  br i1 %15, label %2, label %7, !llvm.loop !0
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1
declare void @cq_phi(double noundef) local_unnamed_addr #1
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #2
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { "no-trapping-math"="true" }
attributes #2 = { nofree nounwind }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!0 = distinct !{!0, !1, !2}
!1 = !{!"llvm.loop.mustprogress"}
!2 = !{!"llvm.loop.unroll.disable"}
