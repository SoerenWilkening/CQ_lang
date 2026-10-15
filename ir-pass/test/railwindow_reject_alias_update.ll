; railwindow_reject_alias_update.ll — DECLINE (bd `test_C_libtooling-01po.19` S7
; postcondition, coordinator 2026-10-15).
;
; `q[i] += q[j]` over unsigned char cells with runtime i, j. The aliased copy
; (i == j) merges both classes into one name, and `x + x` does NOT fold to a
; classical value the way `x ^ x` does: it is an out-of-place value over one
; rail stored back into that cell (r2j3.33's never-allowed form). The S7
; POSTCONDITION (no quantum op of an aliased copy still reads the merged cell
; through two operands) refuses it loudly, at the residual op, before the S5
; needs list is computed. The distinct copy (i != j) is S5's in-place add.
; The message is mirrored CHARACTER-FOR-CHARACTER from kMsgUpdate.
; RETIREMENT TRIGGER: an in-place lowering of `x = 2x` on one rail (not
; reversible at width 8: the top bit is lost) is a physics question for the
; owner, not an S5 item (bd `test_C_libtooling-01po.19.10`).
;
; SOURCE (clang -O1, verbatim below):
;   __attribute__((noinline)) int f(int i, int j) {
;     unsigned char q[4] = {0};
;     i &= 3; j &= 3;
;     for (int k = 0; k < 4; k++) cq_theta(&q[k], .3);
;     q[i] += q[j];
;     int r = 0;
;     for (int k = 0; k < 4; k++) r = 2 * r + cq_measure(q[k]);
;     return r;
;   }
;   int main(int argc, char **argv) { (void)argv; return f(argc, argc + 1); }
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='quantum array not lowered yet'
; CHECK: error: {{.*}}in function f i32 (i32, i32): cq rail window: aliased cell update does not reduce to a classical rebind or an in-place chain

source_filename = "addupd.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @f(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #4
  store i32 0, ptr %3, align 4
  %4 = and i32 %0, 3
  br label %14

5:                                                ; preds = %14
  %6 = and i32 %1, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %7
  %9 = load i8, ptr %8, align 1, !tbaa !6
  %10 = zext nneg i32 %4 to i64
  %11 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %10
  %12 = load i8, ptr %11, align 1, !tbaa !6
  %13 = add i8 %12, %9
  store i8 %13, ptr %11, align 1, !tbaa !6
  br label %22

14:                                               ; preds = %2, %14
  %15 = phi i64 [ 0, %2 ], [ %19, %14 ]
  %16 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %15
  %17 = load i8, ptr %16, align 1, !tbaa !6
  %18 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %17, double noundef 3.000000e-01) #5
  store i8 %18, ptr %16, align 1, !tbaa !6
  %19 = add nuw nsw i64 %15, 1
  %20 = icmp eq i64 %19, 4
  br i1 %20, label %5, label %14, !llvm.loop !9

21:                                               ; preds = %22
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #4
  ret i32 %30

22:                                               ; preds = %5, %22
  %23 = phi i64 [ 0, %5 ], [ %31, %22 ]
  %24 = phi i32 [ 0, %5 ], [ %30, %22 ]
  %25 = shl nsw i32 %24, 1
  %26 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %23
  %27 = load i8, ptr %26, align 1, !tbaa !6
  %28 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %27) #4
  %29 = zext i8 %28 to i32
  %30 = add nsw i32 %25, %29
  %31 = add nuw nsw i64 %23, 1
  %32 = icmp eq i64 %31, 4
  br i1 %32, label %21, label %22, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, 1
  %4 = tail call i32 @f(i32 noundef %0, i32 noundef %3)
  ret i32 %4
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !10, !11}
