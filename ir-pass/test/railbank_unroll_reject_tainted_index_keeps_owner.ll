; DECLINE + ADVERSARIAL (bd `test_C_libtooling-01po.19`): a cell read at a TAINTED index.
;
; `q[k]` with a quantum `k` is 7.5's QRAM axis, not a classical-index bank: the unroll
; stage must not take the array even though its writing walk has a constant trip
; (candidate clause (c)). Its debug lever prints nothing for this array, and the module
; reaches its existing owner, which declines it with the rail-bank string below.
;
; SOURCE (clang -O1, verbatim below):
;   /* adversarial: a cell read at a TAINTED index after the walk: the QRAM axis (7.5)
;      must keep its owner; the unroll stage must not take the array. */
;   int main(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .5);
;     int k = 0;
;     cq_theta(&k, .3);
;     k &= 3;
;     return cq_measure(q[k]);
;   }
;
; RUN: env CQ_RAILBANK_UNROLL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='CQ_RAILBANK_UNROLL_DBG'
; CHECK: cq rail bank: array mixes a rail cell access with an unrecognized one

; ModuleID = 'tidx.c'
source_filename = "tidx.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @main() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #3
  store i32 0, ptr %1, align 4
  br label %11

2:                                                ; preds = %11
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #4
  %4 = and i32 %3, 3
  %5 = zext nneg i32 %4 to i64
  %6 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %5
  %7 = load i8, ptr %6, align 1, !tbaa !6, !range !10, !noundef !11
  %8 = trunc nuw i8 %7 to i1
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %8) #3
  %10 = zext i1 %9 to i32
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #3
  ret i32 %10

11:                                               ; preds = %0, %11
  %12 = phi i64 [ 0, %0 ], [ %18, %11 ]
  %13 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %12
  %14 = load i8, ptr %13, align 1, !tbaa !6, !range !10, !noundef !11
  %15 = trunc nuw i8 %14 to i1
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %15, double noundef 5.000000e-01) #4
  %17 = zext i1 %16 to i8
  store i8 %17, ptr %13, align 1, !tbaa !6
  %18 = add nuw nsw i64 %12, 1
  %19 = icmp eq i64 %18, 4
  br i1 %19, label %2, label %11, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
