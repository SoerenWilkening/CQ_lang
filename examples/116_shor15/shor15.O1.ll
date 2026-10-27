; ModuleID = 'shor15.c'
source_filename = "shor15.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @shor15() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1    ; C: bool x[T]
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #4    ; C: (x comes into scope)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, i8 0, i64 3, i1 false)    ; C: x[T] = {0}
  br label %2    ; C: for (j = 0; j < T; j++)

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %9, %2 ]    ; C: j
  %4 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %3    ; C: &x[j]
  %5 = load i8, ptr %4, align 1, !tbaa !6, !range !10, !noundef !11    ; C: x[j]
  %6 = trunc nuw i8 %5 to i1    ; C: x[j] as bool
  %7 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %6, double noundef 0x3FF921FB54442D18) #5    ; C: cq_theta(&x[j], M_PI / 2);
  %8 = zext i1 %7 to i8    ; C: (store back)
  store i8 %8, ptr %4, align 1, !tbaa !6    ; C: x[j] = ...
  %9 = add nuw nsw i64 %3, 1    ; C: j++
  %10 = icmp eq i64 %9, 3    ; C: j < T
  br i1 %10, label %11, label %2, !llvm.loop !12    ; C: loop back / exit

11:                                               ; preds = %2, %21
  %12 = phi i64 [ %25, %21 ], [ 0, %2 ]    ; C: j
  %13 = phi i32 [ %24, %21 ], [ 7, %2 ]    ; C: ap  (A % N before trip 0)
  %14 = phi i32 [ %22, %21 ], [ 1, %2 ]    ; C: y  (1 before trip 0)
  %15 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %12    ; C: &x[j]
  %16 = load i8, ptr %15, align 1, !tbaa !6, !range !10, !noundef !11    ; C: x[j]
  %17 = trunc nuw i8 %16 to i1    ; C: x[j] as bool
  br i1 %17, label %18, label %21    ; C: if (x[j])

18:                                               ; preds = %11
  %19 = mul i32 %13, %14    ; C: y * ap
  %20 = urem i32 %19, 15    ; C: (y * ap) % N
  br label %21    ; C: end of if

21:                                               ; preds = %18, %11
  %22 = phi i32 [ %20, %18 ], [ %14, %11 ]    ; C: y (updated or kept)
  %23 = mul nuw nsw i32 %13, %13    ; C: ap * ap
  %24 = urem i32 %23, 15    ; C: (ap * ap) % N
  %25 = add nuw nsw i64 %12, 1    ; C: j++
  %26 = icmp eq i64 %25, 3    ; C: j < T
  br i1 %26, label %27, label %11, !llvm.loop !15    ; C: loop back / exit

27:                                               ; preds = %21, %57
  %28 = phi i64 [ %60, %57 ], [ 0, %21 ]    ; C: j  (QFT^-1 outer loop)
  %29 = icmp eq i64 %28, 0    ; C: k < j  (inner loop runs?)
  br i1 %29, label %33, label %30    ; C: for (k = 0; k < j; k++)

30:                                               ; preds = %27
  %31 = sub nuw nsw i64 2, %28    ; C: T - 1 - j
  %32 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %31    ; C: &x[T - 1 - j]
  br label %38    ; C: enter the inner loop

33:                                               ; preds = %53, %27
  %34 = sub nuw nsw i64 2, %28    ; C: T - 1 - j
  %35 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %34    ; C: &x[T - 1 - j]
  %36 = load i8, ptr %35, align 1, !tbaa !6, !range !10, !noundef !11    ; C: x[T - 1 - j]
  %37 = trunc nuw i8 %36 to i1    ; C: x[T - 1 - j] as bool
  br i1 %37, label %56, label %57    ; C: if (x[T - 1 - j])

38:                                               ; preds = %30, %53
  %39 = phi i64 [ 0, %30 ], [ %54, %53 ]    ; C: k
  %40 = sub nuw nsw i64 2, %39    ; C: T - 1 - k
  %41 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %40    ; C: &x[T - 1 - k]
  %42 = load i8, ptr %41, align 1, !tbaa !6, !range !10, !noundef !11    ; C: x[T - 1 - k]
  %43 = trunc nuw i8 %42 to i1    ; C: x[T - 1 - k] as bool
  br i1 %43, label %44, label %53    ; C: if (x[T - 1 - k] && ...  (first conjunct)

44:                                               ; preds = %38
  %45 = load i8, ptr %32, align 1, !tbaa !6, !range !10, !noundef !11    ; C: x[T - 1 - j]  (second conjunct)
  %46 = trunc nuw i8 %45 to i1    ; C: x[T - 1 - j] as bool
  br i1 %46, label %47, label %53    ; C: ... && x[T - 1 - j])

47:                                               ; preds = %44
  %48 = sub nuw nsw i64 %28, %39    ; C: j - k
  %49 = trunc nuw i64 %48 to i32    ; C: (int)(j - k)
  %50 = shl nuw nsw i32 1, %49    ; C: 1u << (j - k)
  %51 = uitofp nneg i32 %50 to double    ; C: (double)(1u << (j - k))
  %52 = fdiv double 0xC00921FB54442D18, %51    ; C: -M_PI / (double)(1u << (j - k))
  tail call void @cq_phi(double noundef %52) #4    ; C: cq_phi(...);
  br label %53    ; C: end of if

53:                                               ; preds = %38, %44, %47
  %54 = add nuw nsw i64 %39, 1    ; C: k++
  %55 = icmp eq i64 %54, %28    ; C: k < j
  br i1 %55, label %33, label %38, !llvm.loop !16    ; C: inner loop back / exit

56:                                               ; preds = %33
  tail call void @cq_phi(double noundef 0x400921FB54442D18) #4    ; C: cq_phi(M_PI);
  br label %57    ; C: end of if

57:                                               ; preds = %56, %33
  %58 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %37, double noundef 0x3FF921FB54442D18) #5    ; C: cq_theta(&x[T - 1 - j], M_PI / 2);
  %59 = zext i1 %58 to i8    ; C: (store back)
  store i8 %59, ptr %35, align 1, !tbaa !6    ; C: x[T - 1 - j] = ...
  %60 = add nuw nsw i64 %28, 1    ; C: j++
  %61 = icmp eq i64 %60, 3    ; C: j < T
  br i1 %61, label %66, label %27, !llvm.loop !17    ; C: outer loop back / exit

62:                                               ; preds = %66
  %63 = tail call i32 @cq_measure_ui32(i32 noundef %22) #4    ; C: cq_measure(y)
  %64 = shl i32 %63, 8    ; C: yv << 8
  %65 = or i32 %64, %77    ; C: m | (yv << 8)
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #4    ; C: (x goes out of scope)
  ret i32 %65    ; C: return

66:                                               ; preds = %57, %66
  %67 = phi i64 [ %78, %66 ], [ 0, %57 ]    ; C: j  (measure loop)
  %68 = phi i32 [ %77, %66 ], [ 0, %57 ]    ; C: m
  %69 = sub nuw nsw i64 2, %67    ; C: T - 1 - j
  %70 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %69    ; C: &x[T - 1 - j]
  %71 = load i8, ptr %70, align 1, !tbaa !6, !range !10, !noundef !11    ; C: x[T - 1 - j]
  %72 = trunc nuw i8 %71 to i1    ; C: x[T - 1 - j] as bool
  %73 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %72) #4    ; C: cq_measure(x[T - 1 - j])
  %74 = zext i1 %73 to i32    ; C: (unsigned)...
  %75 = trunc nuw nsw i64 %67 to i32    ; C: j
  %76 = shl nuw nsw i32 %74, %75    ; C: ... << j
  %77 = or i32 %76, %68    ; C: m |= ...
  %78 = add nuw nsw i64 %67, 1    ; C: j++
  %79 = icmp eq i64 %78, 3    ; C: j < T
  br i1 %79, label %62, label %66, !llvm.loop !18    ; C: loop back / exit
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare void @cq_phi(double noundef) local_unnamed_addr #3

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
!17 = distinct !{!17, !13, !14}
!18 = distinct !{!18, !13, !14}
