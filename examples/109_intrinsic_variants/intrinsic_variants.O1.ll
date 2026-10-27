; ModuleID = 'intrinsic_variants.c'
source_filename = "intrinsic_variants.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

; Function Attrs: nounwind ssp uwtable
define i32 @smin_q(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #8    ; C: cq_theta(&x, th);
  %5 = tail call i32 @llvm.smin.i32(i32 %4, i32 %2)    ; C: x < c ? x : c
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #9    ; C: cq_measure(x < c ? x : c)
  ret i32 %6    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @bswap_q(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #8    ; C: cq_theta(&x, th);
  %4 = tail call i32 @llvm.bswap.i32(i32 %3)    ; C: __builtin_bswap32(x)
  %5 = tail call i32 @cq_measure_ui32(i32 noundef %4) #9    ; C: cq_measure(__builtin_bswap32(x))
  ret i32 %5    ; C: return
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.bswap.i32(i32) #3

; Function Attrs: nounwind ssp uwtable
define i32 @usub_sat_q(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #8    ; C: cq_theta(&x, th);
  %5 = tail call i32 @llvm.usub.sat.i32(i32 %4, i32 %2)    ; C: x > c ? x - c : 0
  %6 = tail call i32 @cq_measure_ui32(i32 noundef %5) #9    ; C: cq_measure(x > c ? x - c : 0)
  ret i32 %6    ; C: return
}

; Function Attrs: nounwind ssp uwtable
define i32 @va_copy_q(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #8    ; C: cq_theta(&x, th);
  %5 = tail call i32 (i32, ...) @sum_twice(i32 poison, i32 noundef %4, i32 noundef %2)    ; C: sum_twice(2, x, a)  (n = 2 propagated into the callee: poison)
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5) #9    ; C: cq_measure(sum_twice(2, x, a))
  ret i32 %6    ; C: return
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp uwtable
define internal i32 @sum_twice(i32 %0, ...) unnamed_addr #4 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16    ; C: va_list ap
  %3 = alloca [1 x %struct.__va_list_tag], align 16    ; C: va_list bp
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #9    ; C: (ap comes into scope)
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %3) #9    ; C: (bp comes into scope)
  call void @llvm.va_start.p0(ptr nonnull %2)    ; C: va_start(ap, n);
  call void @llvm.va_copy.p0(ptr nonnull %3, ptr nonnull %2)    ; C: va_copy(bp, ap);
  %4 = load i32, ptr %2, align 16    ; C: ap.gp_offset
  %5 = getelementptr inbounds i8, ptr %2, i64 8    ; C: &ap.overflow_arg_area
  %6 = getelementptr inbounds i8, ptr %2, i64 16    ; C: &ap.reg_save_area
  %7 = load ptr, ptr %6, align 16    ; C: ap.reg_save_area
  %8 = load ptr, ptr %5, align 8    ; C: ap.overflow_arg_area
  br label %15    ; C: for (i = 0; i < n; i++)  (first loop)

9:                                                ; preds = %27
  %10 = load i32, ptr %3, align 16    ; C: bp.gp_offset
  %11 = getelementptr inbounds i8, ptr %3, i64 8    ; C: &bp.overflow_arg_area
  %12 = getelementptr inbounds i8, ptr %3, i64 16    ; C: &bp.reg_save_area
  %13 = load ptr, ptr %12, align 16    ; C: bp.reg_save_area
  %14 = load ptr, ptr %11, align 8    ; C: bp.overflow_arg_area
  br label %37    ; C: for (i = 0; i < n; i++)  (second loop)

15:                                               ; preds = %1, %27
  %16 = phi ptr [ %8, %1 ], [ %28, %27 ]    ; C: ap.overflow_arg_area (loop-carried)
  %17 = phi i32 [ 0, %1 ], [ %33, %27 ]    ; C: i
  %18 = phi i32 [ 0, %1 ], [ %32, %27 ]    ; C: s
  %19 = phi i32 [ %4, %1 ], [ %29, %27 ]    ; C: ap.gp_offset (loop-carried)
  %20 = icmp ult i32 %19, 41    ; C: va_arg(ap, int): register slot left?
  br i1 %20, label %21, label %25    ; C: va_arg(ap, int)

21:                                               ; preds = %15
  %22 = zext nneg i32 %19 to i64    ; C: va_arg: slot offset
  %23 = getelementptr i8, ptr %7, i64 %22    ; C: va_arg: &reg_save_area[gp_offset]
  %24 = add nuw nsw i32 %19, 8    ; C: va_arg: gp_offset += 8
  store i32 %24, ptr %2, align 16    ; C: va_arg: ap.gp_offset = ...
  br label %27    ; C: va_arg

25:                                               ; preds = %15
  %26 = getelementptr i8, ptr %16, i64 8    ; C: va_arg: overflow_arg_area + 8
  store ptr %26, ptr %5, align 8    ; C: va_arg: ap.overflow_arg_area = ...
  br label %27    ; C: va_arg

27:                                               ; preds = %25, %21
  %28 = phi ptr [ %16, %21 ], [ %26, %25 ]    ; C: va_arg: next overflow_arg_area
  %29 = phi i32 [ %24, %21 ], [ %19, %25 ]    ; C: va_arg: next gp_offset
  %30 = phi ptr [ %23, %21 ], [ %16, %25 ]    ; C: va_arg: the argument slot
  %31 = load i32, ptr %30, align 4, !tbaa !6    ; C: va_arg(ap, int)
  %32 = add nsw i32 %31, %18    ; C: s += va_arg(ap, int)
  %33 = add nuw nsw i32 %17, 1    ; C: i++
  %34 = icmp eq i32 %17, 0    ; C: i < n
  br i1 %34, label %15, label %9, !llvm.loop !10    ; C: i < n

35:                                               ; preds = %49
  call void @llvm.va_end.p0(ptr %3)    ; C: va_end(bp);
  call void @llvm.va_end.p0(ptr %2)    ; C: va_end(ap);
  %36 = add nsw i32 %54, %32    ; C: s + t
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %3) #9    ; C: (bp goes out of scope)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #9    ; C: (ap goes out of scope)
  ret i32 %36    ; C: return

37:                                               ; preds = %9, %49
  %38 = phi ptr [ %14, %9 ], [ %50, %49 ]    ; C: bp.overflow_arg_area (loop-carried)
  %39 = phi i32 [ 0, %9 ], [ %55, %49 ]    ; C: i
  %40 = phi i32 [ 0, %9 ], [ %54, %49 ]    ; C: t
  %41 = phi i32 [ %10, %9 ], [ %51, %49 ]    ; C: bp.gp_offset (loop-carried)
  %42 = icmp ult i32 %41, 41    ; C: va_arg(bp, int): register slot left?
  br i1 %42, label %43, label %47    ; C: va_arg(bp, int)

43:                                               ; preds = %37
  %44 = zext nneg i32 %41 to i64    ; C: va_arg: slot offset
  %45 = getelementptr i8, ptr %13, i64 %44    ; C: va_arg: &reg_save_area[gp_offset]
  %46 = add nuw nsw i32 %41, 8    ; C: va_arg: gp_offset += 8
  store i32 %46, ptr %3, align 16    ; C: va_arg: bp.gp_offset = ...
  br label %49    ; C: va_arg

47:                                               ; preds = %37
  %48 = getelementptr i8, ptr %38, i64 8    ; C: va_arg: overflow_arg_area + 8
  store ptr %48, ptr %11, align 8    ; C: va_arg: bp.overflow_arg_area = ...
  br label %49    ; C: va_arg

49:                                               ; preds = %47, %43
  %50 = phi ptr [ %38, %43 ], [ %48, %47 ]    ; C: va_arg: next overflow_arg_area
  %51 = phi i32 [ %46, %43 ], [ %41, %47 ]    ; C: va_arg: next gp_offset
  %52 = phi ptr [ %45, %43 ], [ %38, %47 ]    ; C: va_arg: the argument slot
  %53 = load i32, ptr %52, align 4, !tbaa !6    ; C: va_arg(bp, int)
  %54 = add nsw i32 %53, %40    ; C: t += va_arg(bp, int)
  %55 = add nuw nsw i32 %39, 1    ; C: i++
  %56 = icmp eq i32 %39, 0    ; C: i < n
  br i1 %56, label %37, label %35, !llvm.loop !13    ; C: i < n
}

; Function Attrs: nounwind ssp uwtable
define i32 @vla_loop_q(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #8    ; C: cq_theta(&x, th);
  %6 = icmp sgt i32 %3, 0    ; C: i < m
  br i1 %6, label %7, label %9    ; C: for (int i = 0; i < m; i++)

7:                                                ; preds = %4
  %8 = zext i32 %2 to i64    ; C: (n as the element count)
  br label %12    ; C: for

9:                                                ; preds = %12, %4
  %10 = phi i32 [ 0, %4 ], [ %19, %12 ]    ; C: acc (at the exit)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #9    ; C: cq_measure(acc)
  ret i32 %11    ; C: return

12:                                               ; preds = %7, %12
  %13 = phi i32 [ 0, %7 ], [ %19, %12 ]    ; C: acc
  %14 = phi i32 [ 0, %7 ], [ %20, %12 ]    ; C: i
  %15 = tail call ptr @llvm.stacksave.p0()    ; C: int v[n];  (stack mark)
  %16 = alloca i32, i64 %8, align 16    ; C: int v[n];
  %17 = add nsw i32 %14, %5    ; C: x + i
  call fastcc void @put(ptr noundef nonnull %16, i32 noundef %17)    ; C: put(v, x + i);
  %18 = load i32, ptr %16, align 16, !tbaa !6    ; C: v[0]
  %19 = add nsw i32 %18, %13    ; C: acc += v[0];
  tail call void @llvm.stackrestore.p0(ptr %15)    ; C: (v goes out of scope: stack restored)
  %20 = add nuw nsw i32 %14, 1    ; C: i++
  %21 = icmp eq i32 %20, %3    ; C: i < m
  br i1 %21, label %9, label %12, !llvm.loop !14    ; C: i < m
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #5

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc void @put(ptr nocapture noundef writeonly %0, i32 noundef %1) unnamed_addr #6 {
  store i32 %1, ptr %0, align 4, !tbaa !6    ; C: v[0] = val;
  ret void    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #5

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #5

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_copy.p0(ptr, ptr) #5

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #7

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.usub.sat.i32(i32, i32) #7

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nofree noinline norecurse nosync nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #6 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #7 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { nomerge nounwind }
attributes #9 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !11, !12}
!14 = distinct !{!14, !11, !12}
