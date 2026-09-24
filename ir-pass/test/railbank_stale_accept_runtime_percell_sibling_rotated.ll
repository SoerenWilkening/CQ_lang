; railbank_stale_accept_runtime_percell_sibling_rotated.ll — bd `xdu2.1`
; (Track B, session 2026-09-24-railbank-parallel).
;
; THE GREEN HALF for the runtime-sized bank (bd `xdu2.4`, `alloca i32, i64 %n`):
; the capability — a DISTINCT theta per cell, minted INSIDE the walk loop — plus
; an UNRELATED register `r` rotated non-diagonally (0.7) BETWEEN the write loop
; and the measure loop.  The fence's memory hop seeds each cell read with the
; per-trip mint (after `applyBank` PASS A the in-loop read is the null seed, so
; the theta is a SOURCE); its forward users are the store and nothing else, so
; `r`'s gate is on a different wire and must not decline this.  A hop seeded
; with the wrong thing (the whole function's rails, or `r`) declines it — the
; runtime twin of register-twin row `p07`.
;
; RE-MEASURED 2026-09-24 on `d0720cb1` (`cq-opt` c6f61f80a5d524c6): ACCEPTS, 13
; trace lines at n=3, STRICT 2b `0 violation(s)`.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
;   __attribute__((noinline)) int slice(int n, int seed) {
;     if (n <= 1) return 0;
;     int r = cq_theta(seed, 0.2);
;     int b[n]; int s = 0;
;     for (int i = 0; i < n; ++i) b[i] = cq_theta(b[i], 0.5);
;     r = cq_theta(r, 0.7);
;     for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
;     return s + cq_measure(r);
;   }
;   int main(int argc, char **argv) { (void)argv; return slice(argc + 2, 1); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CRY   --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS  --input-file=%t.ll %s
;
; The runtime-sized object carries the membership record; the unrelated
; register's 0.7 rotation IS emitted (so the accept is not the fence never
; looking at a gate), and each cell holds a fresh per-trip rail.
; IR: %h = call i32 @cqrt_alloc_i32(
; IR: call void @cqrt_ry_i32(i32 %h, double 2.000000e-01)
; IR: alloca i32, i64 %{{.*}}, !cq.railbank
; IR: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
; IR: [[CELLH:%h[0-9]+]] = call i32 @cqrt_alloc_i32(i32 0)
; IR: call void @cqrt_ry_i32(i32 [[CELLH]], double 5.000000e-01)
; IR: store i32 [[CELLH]], ptr %cq.bank.addr
; IR: call i32 @cqrt_measure_i32(i32 %h)
; IR: [[CELL:%[0-9]+]] = load i32, ptr
; IR: call i32 @cqrt_measure_i32(i32 [[CELL]])
;
; ⚠ One whole-file prefix per count (Rule 12 (a)).
; CRY-COUNT-3: call void @cqrt_ry_i32(
; CMEAS-COUNT-2: call i32 @cqrt_measure_i32(
;
; NOTS-NOT: cqrt_qram_
; NOTS-NOT: cqrt_free

source_filename = "s19_rt_sibling_register_rotated.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %0, 2
  br i1 %3, label %32, label %4

4:                                                ; preds = %2
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.000000e-01) #4
  %6 = zext nneg i32 %0 to i64
  %7 = tail call ptr @llvm.stacksave.p0()
  %8 = alloca i32, i64 %6, align 16
  %9 = zext nneg i32 %0 to i64
  br label %13

10:                                               ; preds = %13
  %11 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 0x3FE6666666666666) #4
  %12 = zext nneg i32 %0 to i64
  br label %23

13:                                               ; preds = %4, %13
  %14 = phi i64 [ 0, %4 ], [ %18, %13 ]
  %15 = getelementptr inbounds i32, ptr %8, i64 %14
  %16 = load i32, ptr %15, align 4, !tbaa !6
  %17 = tail call i32 @cq_theta_si32(i32 noundef %16, double noundef 5.000000e-01) #4
  store i32 %17, ptr %15, align 4, !tbaa !6
  %18 = add nuw nsw i64 %14, 1
  %19 = icmp eq i64 %18, %9
  br i1 %19, label %10, label %13, !llvm.loop !10

20:                                               ; preds = %23
  %21 = tail call i32 @cq_measure_si32(i32 noundef %11) #4
  %22 = add nsw i32 %21, %29
  tail call void @llvm.stackrestore.p0(ptr %7)
  br label %32

23:                                               ; preds = %10, %23
  %24 = phi i64 [ 0, %10 ], [ %30, %23 ]
  %25 = phi i32 [ 0, %10 ], [ %29, %23 ]
  %26 = getelementptr inbounds i32, ptr %8, i64 %24
  %27 = load i32, ptr %26, align 4, !tbaa !6
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #4
  %29 = add nsw i32 %28, %25
  %30 = add nuw nsw i64 %24, 1
  %31 = icmp eq i64 %30, %12
  br i1 %31, label %20, label %23, !llvm.loop !13

32:                                               ; preds = %2, %20
  %33 = phi i32 [ %22, %20 ], [ 0, %2 ]
  ret i32 %33
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, 2
  %4 = tail call i32 @slice(i32 noundef %3, i32 noundef 1)
  ret i32 %4
}

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
