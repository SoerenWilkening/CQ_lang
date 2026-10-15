; lowering_merge_out_discharge_rolled.ll — ACCEPT, DISCHARGED PER TRIP, and the
; FAIL-CLOSED ALIAS CLOSURE (bd test_C_libtooling-r2j3.32, R11 round-1 items 1
; and 3). `clang -O1` of:
;
;     int a = 5; bool b0[3]; int c = 0; cq_theta(&c, 0.3); int acc = 0;
;     for (int i = 0; i < 3; ++i) {
;         if (a >= 3) cq_theta(&b0[i], 0.5);
;         int s = b0[i] ? a : 7;            // a 4.4 merge, dead after its reader
;         if (b0[i]) a -= 3;                // the loop-carried merge (`a`)
;         acc += cq_measure(s + c);
;     }
;     return acc + cq_measure(b0[0]) + … + cq_measure(a) + cq_measure(c);
;
; THE MERGE `s` (%out) reads two registers that are NOT call results: the
; carried handle φ `a` (as its true copy source) and, through the 6.5 prep, the
; bank-parked rail `b0[i]` (as the copy control's source). Round 1 found that a
; φ / load / select operand was never in the window's register set, so a write
; to it between the stream and the replay went unchecked (a latent dirty free).
; Now EVERY operand but a Constant or a classical caller Argument is a register,
; and its ALIAS CLASS is checked: the φ `a` closes over its preheader seed (and
; NOT over its back-edge incoming `%out3`, a fresh mint of THIS trip — a
; different handle than the φ holds), and `b0[i]` closes through the rail bank
; over every cell load (the post-loop measures, outside the window). Nothing in
; the window writes any of them, so `%out` is reversed every trip, after its
; reader `add`, and freed. The carried `%out3` has a φ user and is left
; allocated (a cross-trip LIFO reversal is not a per-trip one).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define i32 @main(
; CHECK:      %[[A:[0-9]+]] = phi i32 [ %cq.carried, %{{[0-9]+}} ], [ %[[OUT3:out[0-9]*]], %{{[0-9]+}} ]
; CHECK:      call void @cqrt_cnot(i32 %[[B:[0-9a-zA-Z_.]+]], i32 %[[BF:[0-9a-zA-Z_.]+]])
; CHECK-NEXT: %[[OUT:[0-9a-zA-Z_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[A]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[BF]], i32 %[[OUT]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK:      call void @cqrt_copy_i32_controlled(i32 %{{[0-9a-zA-Z_.]+}}, i32 %[[A]], i32 %[[OUT3]])
; CHECK:      call i32 @cq_template_add_i32(i32 %[[OUT]],
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_xorc_i32_controlled(i32 %[[BF]], i32 %[[OUT]], i32 7)
; CHECK-NEXT: call void @cqrt_x(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[BF]], i32 %[[A]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_cnot(i32 %[[B]], i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[BF]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NOT:  call void @cqrt_free(i32 %[[OUT3]])
; CHECK:      store i32 %[[B]], ptr %cq.bank.addr
; CHECK-NOT:  call void @cqrt_free(i32 %[[OUT3]])
; CHECK:      {{^}}}
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #4
  br label %25

3:                                                ; preds = %36
  %4 = load i8, ptr %1, align 1, !tbaa !6, !range !10, !noundef !11
  %5 = trunc nuw i8 %4 to i1
  %6 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #3
  %7 = zext i1 %6 to i32
  %8 = add nsw i32 %45, %7
  %9 = getelementptr inbounds i8, ptr %1, i64 1
  %10 = load i8, ptr %9, align 1, !tbaa !6, !range !10, !noundef !11
  %11 = trunc nuw i8 %10 to i1
  %12 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %11) #3
  %13 = zext i1 %12 to i32
  %14 = add nsw i32 %8, %13
  %15 = getelementptr inbounds i8, ptr %1, i64 2
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11
  %17 = trunc nuw i8 %16 to i1
  %18 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %17) #3
  %19 = zext i1 %18 to i32
  %20 = add nsw i32 %14, %19
  %21 = tail call i32 @cq_measure_si32(i32 noundef %42) #3
  %22 = add nsw i32 %20, %21
  %23 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %24 = add nsw i32 %22, %23
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #3
  ret i32 %24

25:                                               ; preds = %0, %36
  %26 = phi i64 [ 0, %0 ], [ %46, %36 ]
  %27 = phi i32 [ 5, %0 ], [ %42, %36 ]
  %28 = phi i32 [ 0, %0 ], [ %45, %36 ]
  %29 = icmp sgt i32 %27, 2
  br i1 %29, label %30, label %36

30:                                               ; preds = %25
  %31 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %26
  %32 = load i8, ptr %31, align 1, !tbaa !6, !range !10, !noundef !11
  %33 = trunc nuw i8 %32 to i1
  %34 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %33, double noundef 5.000000e-01) #4
  %35 = zext i1 %34 to i8
  store i8 %35, ptr %31, align 1, !tbaa !6
  br label %36

36:                                               ; preds = %30, %25
  %37 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %26
  %38 = load i8, ptr %37, align 1, !tbaa !6, !range !10, !noundef !11
  %39 = trunc nuw i8 %38 to i1
  %40 = select i1 %39, i32 %27, i32 7
  %41 = add nsw i32 %27, -3
  %42 = select i1 %39, i32 %41, i32 %27
  %43 = add nsw i32 %40, %2
  %44 = tail call i32 @cq_measure_si32(i32 noundef %43) #3
  %45 = add nsw i32 %44, %28
  %46 = add nuw nsw i64 %26, 1
  %47 = icmp eq i64 %46, 3
  br i1 %47, label %3, label %25, !llvm.loop !12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

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
