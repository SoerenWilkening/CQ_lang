; ModuleID = 'varargs.c'
source_filename = "varargs.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

; Function Attrs: nounwind ssp uwtable
define i32 @varargs(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5    ; C: cq_theta(&x, th);
  %6 = tail call i32 (i32, ...) @sum3(i32 poison, i32 noundef %2, i32 noundef %5, i32 noundef %3)    ; C: sum3(1, a, x, b)  (-O1 propagated n = 1 into sum3, so the named argument is dead: poison)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #6    ; C: cq_measure(sum3(1, a, x, b))
  ret i32 %7    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp uwtable
define internal range(i32 -2147483647, -2147483648) i32 @sum3(i32 %0, ...) unnamed_addr #3 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16    ; C: va_list ap;
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #6    ; C: (ap comes into scope)
  call void @llvm.va_start.p0(ptr nonnull %2)    ; C: va_start(ap, n);
  %3 = load i32, ptr %2, align 16    ; C: ap->gp_offset
  %4 = getelementptr inbounds i8, ptr %2, i64 8    ; C: &ap->overflow_arg_area
  %5 = getelementptr inbounds i8, ptr %2, i64 16    ; C: &ap->reg_save_area
  %6 = load ptr, ptr %5, align 16    ; C: ap->reg_save_area
  %7 = load ptr, ptr %4, align 8    ; C: ap->overflow_arg_area
  br label %10    ; C: for (int i = 0; ...)

8:                                                ; preds = %22
  call void @llvm.va_end.p0(ptr %2)    ; C: va_end(ap);
  %9 = add nsw i32 %27, 1    ; C: s + n  (n = 1 propagated by -O1)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #6    ; C: (ap goes out of scope)
  ret i32 %9    ; C: return

10:                                               ; preds = %1, %22
  %11 = phi ptr [ %7, %1 ], [ %23, %22 ]    ; C: overflow_arg_area (loop-carried)
  %12 = phi i32 [ 0, %1 ], [ %28, %22 ]    ; C: i
  %13 = phi i32 [ 0, %1 ], [ %27, %22 ]    ; C: s
  %14 = phi i32 [ %3, %1 ], [ %24, %22 ]    ; C: gp_offset (loop-carried)
  %15 = icmp ult i32 %14, 41    ; C: va_arg: gp_offset <= 40 ? register slot : overflow area
  br i1 %15, label %16, label %20    ; C: va_arg(ap, int)

16:                                               ; preds = %10
  %17 = zext nneg i32 %14 to i64    ; C: va_arg: &reg_save_area[gp_offset]
  %18 = getelementptr i8, ptr %6, i64 %17    ; C: va_arg: &reg_save_area[gp_offset]
  %19 = add nuw nsw i32 %14, 8    ; C: va_arg: gp_offset += 8
  store i32 %19, ptr %2, align 16    ; C: va_arg: ap->gp_offset = ...
  br label %22    ; C: va_arg

20:                                               ; preds = %10
  %21 = getelementptr i8, ptr %11, i64 8    ; C: va_arg: overflow_arg_area += 8
  store ptr %21, ptr %4, align 8    ; C: va_arg: ap->overflow_arg_area = ...
  br label %22    ; C: va_arg

22:                                               ; preds = %20, %16
  %23 = phi ptr [ %11, %16 ], [ %21, %20 ]    ; C: va_arg: overflow_arg_area after
  %24 = phi i32 [ %19, %16 ], [ %14, %20 ]    ; C: va_arg: gp_offset after
  %25 = phi ptr [ %18, %16 ], [ %11, %20 ]    ; C: va_arg: the argument slot
  %26 = load i32, ptr %25, align 4, !tbaa !6    ; C: va_arg(ap, int)
  %27 = add nsw i32 %26, %13    ; C: s += va_arg(ap, int);
  %28 = add nuw nsw i32 %12, 1    ; C: i++
  %29 = icmp eq i32 %28, 3    ; C: i < 3
  br i1 %29, label %8, label %10, !llvm.loop !10    ; C: i < 3
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
