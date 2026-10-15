; spec_accept_gate_sub_extern_byptr.ll — ACCEPT (bd test_C_libtooling-p3kd.21, R11
; r1 item 5; reviewer probe revS1/p3_extern_byptr.c). A by-pointer gate subroutine
; with DEFAULT (external) linkage, the ordinary C spelling:
;
;   __attribute__((noinline)) void prep(int c, bool *t) { if (c == 1) cq_theta(t, 0.4); }
;   cq_theta(&q0, 0.5); int c = q0; prep(c, &q1);
;
; The call is compiled at its site (a controlled Ry on `q0`'s rail). Before the fix
; the external `prep` kept its standalone body, which stores a register through
; its pointer parameter and declined `tainted value stored to memory`. The module
; defines `main`: a whole program (cqc llvm-links every TU before the pass), so an
; inlined gate subroutine with no use left is erased whatever its linkage.
; `clang -O1 -include CQ.h` output verbatim.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; CHECK-LABEL: define {{.*}}i32 @main(
; CHECK-NEXT: [[Q0:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1(i32 [[Q0]], double 5.000000e-01)
; CHECK-NEXT: [[Q1:%[0-9a-z.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 [[Q0]], i32 [[Q1]], double 4.000000e-01)
; CHECK-NEXT: {{%[0-9a-z.]+}} = call i1 @cqrt_measure_i1(i32 [[Q1]])
; CHECK-NOT: @prep

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: noinline nounwind ssp uwtable
define void @prep(i32 noundef %0, ptr nocapture noundef %1) local_unnamed_addr #0 {
  %3 = icmp eq i32 %0, 1
  br i1 %3, label %4, label %9

4:                                                ; preds = %2
  %5 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %6 = trunc nuw i8 %5 to i1
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 4.000000e-01) #4
  %8 = zext i1 %7 to i8
  store i8 %8, ptr %1, align 1, !tbaa !6
  br label %9

9:                                                ; preds = %4, %2
  ret void
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 3) i32 @main() local_unnamed_addr #2 {
  %1 = alloca i8, align 1
  call void @llvm.lifetime.start.p0(i64 1, ptr nonnull %1) #5
  store i8 0, ptr %1, align 1, !tbaa !6
  %2 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01) #4
  %3 = zext i1 %2 to i32
  call void @prep(i32 noundef %3, ptr noundef nonnull %1)
  %4 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %5 = trunc nuw i8 %4 to i1
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #5
  %7 = zext i1 %6 to i32
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %2) #5
  %9 = zext i1 %8 to i32
  %10 = add nuw nsw i32 %9, %7
  call void @llvm.lifetime.end.p0(i64 1, ptr nonnull %1) #5
  ret i32 %10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

attributes #0 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

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
