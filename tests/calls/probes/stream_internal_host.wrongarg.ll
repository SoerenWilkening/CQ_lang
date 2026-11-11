; cq-xkmrm mutant: the second printf passes x where the C program passes x + 2 (must be REJECTED)
; ModuleID = 'tests/calls/probes/stream_internal_host.O1.ll'
source_filename = "stream_internal_host.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

@__stdoutp = external local_unnamed_addr global ptr, align 8
@.str.1 = private unnamed_addr constant [4 x i8] c"%d|\00", align 1
@.str.2 = private unnamed_addr constant [5 x i8] c"<%d>\00", align 1
@llvm.used = appending global [1 x ptr] [ptr @printf], section "llvm.metadata"
@__cq_act_stream_internal_host = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [9 x i8] c"i32 (i8)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nofree noinline nounwind ssp uwtable
define internal noundef i32 @printf(ptr noalias nocapture noundef readonly %0, ...) #0 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #6
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = load ptr, ptr @__stdoutp, align 8, !tbaa !6
  %4 = call i32 @fputc(i32 66, ptr %3)
  %5 = load ptr, ptr @__stdoutp, align 8, !tbaa !6
  %6 = call i32 @vfprintf(ptr noundef %5, ptr noundef %0, ptr noundef nonnull %2) #6
  call void @llvm.va_end.p0(ptr %2)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #6
  ret i32 %6
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #2

; Function Attrs: nofree nounwind
declare noundef i32 @vfprintf(ptr nocapture noundef, ptr nocapture noundef readonly, ptr noundef) local_unnamed_addr #3

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @stream_internal_host(i8 noundef signext %0) local_unnamed_addr #4 {
  %2 = call i32 @cqrt_tape_alloc()
  %3 = call i32 @cqrt_alloc_i8(i8 %0)
  call void @cqrt_ry_i8(i32 %3, double 3.000000e-01)
  %4 = call i32 @cq_template_sext_i8_to_i32(i32 %3)
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 1)
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 0)
  %7 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_xor_i1(i32 %6, i32 %7)
  call void @cqrt_tape_fmt_controlled(i32 %7, i32 %2, ptr @.str.1)
  %8 = call i32 @cqrt_tape_write_i32_controlled(i32 %7, i32 %2, i32 %4)
  call void @cqrt_xor_i1(i32 %6, i32 %7)
  call void @cqrt_not_i1(i32 %7)
  call void @cqrt_free(i32 %7)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %5, i32 0)
  call void @cqrt_free(i32 %6)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 1)
  call void @cqrt_free(i32 %5)
  %9 = call i32 @cq_template_add_i32_hl(i32 %4, i32 2)
  call void @cqrt_tape_fmt(i32 %2, ptr @.str.2)
  %10 = call i32 @cqrt_tape_write_i32(i32 %2, i32 %4)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %4, i32 2)
  call void @cqrt_free(i32 %9)
  %11 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)
  call void @cq_template_sext_i8_to_i32_unc(i32 %4, i32 %3)
  call void @cqrt_free(i32 %4)
  %12 = call i32 @cqrt_measure_i32(i32 %11), !cq.measure !10
  ret i32 %12
}

; Function Attrs: nofree nounwind
declare noundef i32 @fputc(i32 noundef, ptr nocapture noundef) local_unnamed_addr #5

declare i32 @cqrt_alloc_i8(i8)

declare void @cqrt_ry_i8(i32, double)

declare i32 @cq_template_sext_i8_to_i32(i32)

declare i32 @cq_template_and_i32_hl(i32, i32)

declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_not_i1(i32)

declare void @cqrt_xor_i1(i32, i32)

declare i32 @cqrt_tape_alloc()

declare void @cqrt_tape_fmt_controlled(i32, i32, ptr)

declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)

declare i32 @cq_template_add_i32_hl(i32, i32)

declare void @cqrt_tape_fmt(i32, ptr)

declare i32 @cqrt_tape_write_i32(i32, i32)

declare i32 @cqrt_measure_i32(i32)

declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)

declare void @cq_template_and_i32_hl_unc(i32, i32, i32)

declare void @cq_template_sext_i8_to_i32_unc(i32, i32)

define internal i32 @__cq_q_stream_internal_host_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %0, i32 %4)
  call void @cqrt_ry_i8(i32 %4, double 3.000000e-01)
  %5 = call i32 @cq_template_sext_i8_to_i32(i32 %4)
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 0)
  %8 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %8)
  call void @cqrt_xor_i1(i32 %7, i32 %8)
  call void @cqrt_tape_fmt_controlled(i32 %8, i32 %3, ptr @.str.1)
  %9 = call i32 @cqrt_tape_write_i32_controlled(i32 %8, i32 %3, i32 %5)
  call void @cqrt_xor_i1(i32 %7, i32 %8)
  call void @cqrt_not_i1(i32 %8)
  call void @cqrt_free(i32 %8)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %6, i32 0)
  call void @cqrt_free(i32 %7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %5, i32 1)
  call void @cqrt_free(i32 %6)
  %10 = call i32 @cq_template_add_i32_hl(i32 %5, i32 2)
  call void @cqrt_tape_fmt(i32 %3, ptr @.str.2)
  %11 = call i32 @cqrt_tape_write_i32(i32 %3, i32 %10)
  call void @cq_template_add_i32_hl_unc(i32 %10, i32 %5, i32 2)
  call void @cqrt_free(i32 %10)
  %12 = call i32 @cq_template_add_i32_hl(i32 %5, i32 1)
  %13 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %12, i32 %13)
  call void @cq_template_add_i32_hl_unc(i32 %12, i32 %5, i32 1)
  call void @cqrt_free(i32 %12)
  call void @cq_template_sext_i8_to_i32_unc(i32 %5, i32 %4)
  call void @cqrt_free(i32 %5)
  %14 = call i32 @cqrt_measure_i32(i32 %13), !cq.measure !10
  call void @cqrt_push(i32 %4)
  call void @cqrt_push(i32 %13)
  %15 = call i32 @cqrt_alloc_i32(i32 %14)
  ret i32 %15
}

declare void @cqrt_copy_i8(i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_push(i32)

define internal i32 @__cq_q_stream_internal_host_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_stream_internal_host, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_stream_internal_host, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %28

7:                                                ; preds = %3
  %8 = call i32 @cqrt_tape_alloc()
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %9 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %1, i32 %9)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %9, double 3.000000e-01)
  %10 = alloca { i32, ptr }, align 8
  %11 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 0
  store i32 %9, ptr %11, align 4
  %12 = load ptr, ptr %cq.mints, align 8
  %13 = getelementptr inbounds { i32, ptr }, ptr %10, i32 0, i32 1
  store ptr %12, ptr %13, align 8
  store ptr %10, ptr %cq.mints, align 8
  %14 = call i32 @cq_template_sext_i8_to_i32(i32 %9)
  %15 = call i32 @cq_template_and_i32_hl(i32 %14, i32 1)
  %16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %15, i32 0)
  %17 = call i32 @cqrt_alloc_i1(i1 false)
  %18 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_xor_i1(i32 %16, i32 %18)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %17)
  call void @cqrt_tape_fmt_controlled(i32 %17, i32 %8, ptr @.str.1)
  %19 = call i32 @cqrt_tape_write_i32_controlled(i32 %17, i32 %8, i32 %14)
  call void @cqrt_and_i1(i32 %0, i32 %18, i32 %17)
  call void @cqrt_free(i32 %17)
  call void @cqrt_xor_i1(i32 %16, i32 %18)
  call void @cqrt_not_i1(i32 %18)
  call void @cqrt_free(i32 %18)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %16, i32 %15, i32 0)
  call void @cqrt_free(i32 %16)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %14, i32 1)
  call void @cqrt_free(i32 %15)
  %20 = call i32 @cq_template_add_i32_hl(i32 %14, i32 2)
  call void @cqrt_tape_fmt_controlled(i32 %0, i32 %8, ptr @.str.2)
  %21 = call i32 @cqrt_tape_write_i32_controlled(i32 %0, i32 %8, i32 %20)
  call void @cq_template_add_i32_hl_unc(i32 %20, i32 %14, i32 2)
  call void @cqrt_free(i32 %20)
  %22 = call i32 @cq_template_add_i32_hl(i32 %14, i32 1)
  %23 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %22, i32 %23)
  call void @cq_template_add_i32_hl_unc(i32 %22, i32 %14, i32 1)
  call void @cqrt_free(i32 %22)
  call void @cq_template_sext_i8_to_i32_unc(i32 %14, i32 %9)
  call void @cqrt_free(i32 %14)
  %24 = call i32 @cqrt_measure_i32(i32 %23), !cq.measure !10
  %25 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %25)
  %26 = load i32, ptr @__cq_act_stream_internal_host, align 4
  %27 = add i32 %26, -1
  store i32 %27, ptr @__cq_act_stream_internal_host, align 4
  ret i32 %23

28:                                               ; preds = %3
  %29 = call i32 @cqrt_alloc_i32(i32 0)
  %30 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %30)
  call void @cqrt_push(i32 0)
  %31 = load i32, ptr @__cq_act_stream_internal_host, align 4
  %32 = add i32 %31, -1
  store i32 %32, ptr @__cq_act_stream_internal_host, align 4
  ret i32 %29
}

declare void @cqrt_ry_i8_controlled(i32, i32, double)

declare void @cqrt_and_i1(i32, i32, i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

define internal void @__cq_mints_push(ptr %0) {
  br label %2

2:                                                ; preds = %6, %1
  %3 = phi ptr [ %0, %1 ], [ %10, %6 ]
  %4 = phi i32 [ 0, %1 ], [ %11, %6 ]
  %5 = icmp eq ptr %3, null
  br i1 %5, label %12, label %6

6:                                                ; preds = %2
  %7 = getelementptr inbounds { i32, ptr }, ptr %3, i32 0, i32 0
  %8 = load i32, ptr %7, align 4
  call void @cqrt_push(i32 %8)
  %9 = getelementptr inbounds { i32, ptr }, ptr %3, i32 0, i32 1
  %10 = load ptr, ptr %9, align 8
  %11 = add i32 %4, 1
  br label %2

12:                                               ; preds = %2
  call void @cqrt_push(i32 %4)
  ret void
}

declare void @cqrt_copy_i1(i32, i32)

define internal i32 @__cq_q_stream_internal_host_1_t_pure(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_copy_i8(i32 %0, i32 %3)
  call void @cqrt_ry_i8(i32 %3, double 3.000000e-01)
  %4 = call i32 @cq_template_sext_i8_to_i32(i32 %3)
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 1)
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 0)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %5, i32 0)
  call void @cqrt_free(i32 %6)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 1)
  call void @cqrt_free(i32 %5)
  %7 = call i32 @cq_template_add_i32_hl(i32 %4, i32 2)
  call void @cq_template_add_i32_hl_unc(i32 %7, i32 %4, i32 2)
  call void @cqrt_free(i32 %7)
  %8 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)
  %9 = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %8, i32 %9)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %4, i32 1)
  call void @cqrt_free(i32 %8)
  call void @cq_template_sext_i8_to_i32_unc(i32 %4, i32 %3)
  call void @cqrt_free(i32 %4)
  %10 = call i32 @cqrt_measure_i32(i32 %9), !cq.measure !10
  call void @cqrt_push(i32 %3)
  call void @cqrt_push(i32 %9)
  %11 = call i32 @cqrt_alloc_i32(i32 %10)
  ret i32 %11
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @stream_internal_host, ptr @.cq.sig, ptr @__cq_q_stream_internal_host_1_t, ptr @__cq_q_stream_internal_host_1_t_ctl, ptr @__cq_q_stream_internal_host_1_t_unc, ptr @__cq_q_stream_internal_host_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_stream_internal_host_1_t_unc(i32 %out, i32 %0, i32 %1) {
  %3 = call i32 @cqrt_pop()
  %4 = call i32 @cqrt_pop()
  %5 = call i32 @cq_template_sext_i8_to_i32(i32 %4)
  %6 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)
  %7 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 0)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %7, i32 %6, i32 0)
  call void @cqrt_free(i32 %7)
  call void @cq_template_and_i32_hl_unc(i32 %6, i32 %5, i32 1)
  call void @cqrt_free(i32 %6)
  %8 = call i32 @cq_template_add_i32_hl(i32 %5, i32 2)
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %5, i32 2)
  call void @cqrt_free(i32 %8)
  %9 = call i32 @cq_template_add_i32_hl(i32 %5, i32 1)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %5, i32 1)
  call void @cqrt_free(i32 %9)
  call void @cq_template_sext_i8_to_i32_unc(i32 %5, i32 %4)
  call void @cqrt_free(i32 %5)
  ret void
}

define internal void @__cq_q_stream_internal_host_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_stream_internal_host, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_stream_internal_host, align 4
  %7 = load i32, ptr @__cq_act_stream_internal_host, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_stream_internal_host, align 4
  %9 = call i32 @cqrt_pop()
  br label %10

10:                                               ; preds = %13, %4
  %11 = phi i32 [ %9, %4 ], [ %15, %13 ]
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %16, label %13

13:                                               ; preds = %10
  %14 = call i32 @cqrt_pop()
  %15 = sub i32 %11, 1
  br label %10

16:                                               ; preds = %10
  ret void
}

declare i32 @cqrt_pop()

attributes #0 = { nofree noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nosync nounwind willreturn }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
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
!10 = !{}
