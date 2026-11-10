; ModuleID = 'tests/calls/probes/stream_wide_forms.c'
source_filename = "tests/calls/probes/stream_wide_forms.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

@.str = private unnamed_addr constant [12 x i32] [i32 91, i32 37, i32 100, i32 32, i32 37, i32 108, i32 115, i32 32, i32 37, i32 115, i32 93, i32 0], align 4
@.str.1 = private unnamed_addr constant [5 x i32] [i32 119, i32 105, i32 100, i32 101, i32 0], align 4
@.str.2 = private unnamed_addr constant [7 x i8] c"narrow\00", align 1
@__stdoutp = external local_unnamed_addr global ptr, align 8
@.str.3 = private unnamed_addr constant [12 x i32] [i32 60, i32 37, i32 53, i32 46, i32 49, i32 102, i32 32, i32 37, i32 108, i32 99, i32 62, i32 0], align 4
@.str.4 = private unnamed_addr constant [14 x i32] [i32 37, i32 100, i32 124, i32 37, i32 52, i32 46, i32 50, i32 108, i32 115, i32 124, i32 37, i32 37, i32 124, i32 0], align 4
@.str.5 = private unnamed_addr constant [5 x i32] [i32 119, i32 120, i32 121, i32 122, i32 0], align 4
@.str.6 = private unnamed_addr constant [17 x i32] [i32 123, i32 37, i32 108, i32 100, i32 32, i32 37, i32 99, i32 32, i32 37, i32 76, i32 103, i32 32, i32 37, i32 42, i32 100, i32 125, i32 0], align 4
@.str.7 = private unnamed_addr constant [10 x i32] [i32 111, i32 100, i32 100, i32 32, i32 37, i32 104, i32 104, i32 120, i32 59, i32 0], align 4
@__stderrp = external local_unnamed_addr global ptr, align 8
@.str.8 = private unnamed_addr constant [8 x i32] [i32 101, i32 114, i32 114, i32 32, i32 37, i32 100, i32 10, i32 0], align 4
@.str.9 = private unnamed_addr constant [9 x i32] [i32 101, i32 114, i32 114, i32 50, i32 32, i32 37, i32 100, i32 10, i32 0], align 4

; Function Attrs: nounwind ssp uwtable
define i32 @stream_wide_forms(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 3.000000e-01) #5
  %3 = sext i8 %2 to i32
  %4 = tail call i32 (ptr, ...) @wprintf(ptr noundef nonnull @.str, i32 noundef %3, ptr noundef nonnull @.str.1, ptr noundef nonnull @.str.2) #6
  %5 = load ptr, ptr @__stdoutp, align 8, !tbaa !6
  %6 = sitofp i8 %2 to double
  %7 = fmul double %6, 2.500000e-01
  %8 = and i32 %3, 7
  %9 = add nuw nsw i32 %8, 97
  %10 = tail call i32 (ptr, ptr, ...) @fwprintf(ptr noundef %5, ptr noundef nonnull @.str.3, double noundef %7, i32 noundef %9) #6
  tail call void (ptr, ...) @wsay(ptr nonnull poison, i32 noundef %3, ptr noundef nonnull @.str.5)
  %11 = load ptr, ptr @__stdoutp, align 8, !tbaa !6
  %12 = sext i8 %2 to i64
  %13 = mul nsw i64 %12, 3
  %14 = add nuw nsw i32 %8, 65
  %15 = sitofp i8 %2 to x86_fp80
  %16 = fmul x86_fp80 %15, 0xK3FFD8000000000000000
  tail call void (ptr, ptr, ...) @wsay_to(ptr noundef %11, ptr noundef nonnull @.str.6, i64 noundef %13, i32 noundef %14, x86_fp80 noundef %16, i32 noundef 4, i32 noundef %3)
  %17 = and i32 %3, 1
  %18 = icmp eq i32 %17, 0
  br i1 %18, label %21, label %19

19:                                               ; preds = %1
  %20 = load ptr, ptr @__stdoutp, align 8, !tbaa !6
  tail call void (ptr, ptr, ...) @wsay_to(ptr noundef %20, ptr noundef nonnull @.str.7, i32 noundef %3)
  br label %21

21:                                               ; preds = %19, %1
  %22 = load ptr, ptr @__stderrp, align 8, !tbaa !6
  tail call void (ptr, ptr, ...) @wsay_to(ptr noundef %22, ptr noundef nonnull @.str.8, i32 noundef %3)
  %23 = load ptr, ptr @__stderrp, align 8, !tbaa !6
  %24 = tail call i32 (ptr, ptr, ...) @fwprintf(ptr noundef %23, ptr noundef nonnull @.str.9, i32 noundef %3) #6
  %25 = add nsw i32 %3, 1
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #6
  ret i32 %26
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

declare i32 @wprintf(ptr noundef, ...) local_unnamed_addr #2

declare i32 @fwprintf(ptr noundef, ptr noundef, ...) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal void @wsay(ptr nocapture readnone %0, ...) unnamed_addr #3 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #6
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = call i32 @vwprintf(ptr noundef nonnull @.str.4, ptr noundef nonnull %2) #6
  call void @llvm.va_end.p0(ptr %2)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #6
  ret void
}

; Function Attrs: noinline nounwind ssp uwtable
define internal void @wsay_to(ptr noundef %0, ptr noundef %1, ...) unnamed_addr #3 {
  %3 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %3) #6
  call void @llvm.va_start.p0(ptr nonnull %3)
  %4 = call i32 @vfwprintf(ptr noundef %0, ptr noundef %1, ptr noundef nonnull %3) #6
  call void @llvm.va_end.p0(ptr %3)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %3) #6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #4

declare i32 @vwprintf(ptr noundef, ptr noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #4

declare i32 @vfwprintf(ptr noundef, ptr noundef, ptr noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
