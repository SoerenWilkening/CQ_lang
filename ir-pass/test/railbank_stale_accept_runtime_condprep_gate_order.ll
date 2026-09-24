; railbank_stale_accept_runtime_condprep_gate_order.ll — bd `xdu2.1` (Track B,
; session 2026-09-24-railbank-parallel; Rule-13 review round 1 item 4).
;
; THE GATE-ORDER PIN for `tests/e2e/railbank_stale_matrix.c` row 30, the
; xdu2.4 SEED-PATH CONDITIONAL PREP on a runtime `int b[n]` bank (the owner's
; `example/grover/main.c` shape), whose promoted store value is the merge phi
; `[theta, %cq.bank.seed]` that the stale-reader fence's memory hop seeds from.
; The matrix row pins only the VERDICT; it cannot be a byte twin, because its
; hand-unrolled flat twin (`trackB_probes` `t30_condprep.twin.c`) emits the
; SAME gates with ONE reordering per trip: the rolled form mints the prep rail
; `cqrt_alloc_i32(0)` BEFORE the `icmp sgt` flag and the flat form AFTER it.
; Allocating a fresh `|0>` rail commutes with a compare on a different rail,
; so the two circuits are equal, but the handle numbering permutes (measured
; with `diff`: every difference is that alloc swap plus the handle renaming it
; implies). So the order is pinned here instead, per trip:
;   seed alloc -> flag -> CONTROLLED Ry(flag, seed) -> flag strip -> free(flag)
;   -> the `if (b[i]) Z -= 2` data select READING THE SEED RAIL -> store seed.
; The last CHECK pins that each bank measure reads a cell LOAD, i.e. the rail
; the loop parked.
;
; RE-MEASURED 2026-09-24 on `d0720cb1` (`cq-opt` c6f61f80a5d524c6): ACCEPTS, 47
; trace lines at n=3, STRICT 2b `0 violation(s)`.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
;   __attribute__((noinline)) static int slice(int n) {
;     if (n <= 0) return 0;
;     int b[n]; int Z = 4 * n; int s = 0;
;     for (int i = 0; i < n; ++i) { if (Z >= 2) b[i] = cq_theta(b[i], 0.5); if (b[i]) Z -= 2; }
;     for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
;     return s + cq_measure(Z);
;   }
;   int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CRYC  --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS  --input-file=%t.ll %s
;
; IR: alloca i32, i64 %{{.*}}, !cq.railbank
; IR: %cq.bank.seed = call i32 @cqrt_alloc_i32(i32 0), !cq.railbank.seed
; IR-NEXT: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(
; IR-NEXT: call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %cq.bank.seed, double 5.000000e-01)
; IR-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp,
; IR-NEXT: call void @cqrt_free(i32 %h_cmp)
; IR: %h_cmp1 = call i32 @cq_template_icmp_eq_i32_hl(i32 %cq.bank.seed, i32 0)
; IR: call void @cqrt_free(i32 %h_cmp1)
; IR: store i32 %cq.bank.seed, ptr %cq.bank.addr
; IR: [[CELL:%[0-9]+]] = load i32, ptr
; IR-NEXT: call i32 @cqrt_measure_i32(i32 [[CELL]])
;
; ⚠ One whole-file prefix per count (Rule 12 (a)).
; CRYC-COUNT-1: call void @cqrt_ry_i32_controlled(
; CMEAS-COUNT-2: call i32 @cqrt_measure_i32(
;
; NOTS-NOT: cqrt_qram_
; NOTS-NOT: cqrt_free(i32 %cq.bank.seed)

source_filename = "h04_condprep_control.bank.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %0, 2
  %4 = tail call fastcc i32 @slice(i32 noundef %3)
  ret i32 %4
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @slice(i32 noundef %0) unnamed_addr #1 {
  %2 = icmp slt i32 %0, 1
  br i1 %2, label %39, label %3

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  %5 = tail call ptr @llvm.stacksave.p0()
  %6 = alloca i32, i64 %4, align 16
  %7 = shl nsw i32 %0, 2
  %8 = zext nneg i32 %0 to i64
  br label %11

9:                                                ; preds = %19
  %10 = zext nneg i32 %0 to i64
  br label %30

11:                                               ; preds = %3, %19
  %12 = phi i64 [ 0, %3 ], [ %25, %19 ]
  %13 = phi i32 [ %7, %3 ], [ %24, %19 ]
  %14 = icmp sgt i32 %13, 1
  br i1 %14, label %15, label %19

15:                                               ; preds = %11
  %16 = getelementptr inbounds i32, ptr %6, i64 %12
  %17 = load i32, ptr %16, align 4, !tbaa !6
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 5.000000e-01) #4
  store i32 %18, ptr %16, align 4, !tbaa !6
  br label %19

19:                                               ; preds = %15, %11
  %20 = getelementptr inbounds i32, ptr %6, i64 %12
  %21 = load i32, ptr %20, align 4, !tbaa !6
  %22 = icmp eq i32 %21, 0
  %23 = add nsw i32 %13, -2
  %24 = select i1 %22, i32 %13, i32 %23
  %25 = add nuw nsw i64 %12, 1
  %26 = icmp eq i64 %25, %8
  br i1 %26, label %9, label %11, !llvm.loop !10

27:                                               ; preds = %30
  %28 = tail call i32 @cq_measure_si32(i32 noundef %24) #4
  %29 = add nsw i32 %28, %36
  tail call void @llvm.stackrestore.p0(ptr %5)
  br label %39

30:                                               ; preds = %9, %30
  %31 = phi i64 [ 0, %9 ], [ %37, %30 ]
  %32 = phi i32 [ 0, %9 ], [ %36, %30 ]
  %33 = getelementptr inbounds i32, ptr %6, i64 %31
  %34 = load i32, ptr %33, align 4, !tbaa !6
  %35 = tail call i32 @cq_measure_si32(i32 noundef %34) #4
  %36 = add nsw i32 %35, %32
  %37 = add nuw nsw i64 %31, 1
  %38 = icmp eq i64 %37, %10
  br i1 %38, label %27, label %30, !llvm.loop !13

39:                                               ; preds = %1, %27
  %40 = phi i32 [ %29, %27 ], [ 0, %1 ]
  ret i32 %40
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #2

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
