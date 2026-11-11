; ModuleID = 'tests/calls/probes/stream_reads_string.O1.ll'
source_filename = "stream_reads_string.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.cq.effect.perror = private unnamed_addr constant [7 x i8] c"perror\00", align 1
@.cq.effect.puts = private unnamed_addr constant [5 x i8] c"puts\00", align 1
@__cq_act_stream_reads_string = internal global i32 0, align 4
@.cq.sig = private unnamed_addr constant [9 x i8] c"i32 (i8)\00", align 1
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

; Function Attrs: nounwind ssp uwtable
define noundef i32 @stream_reads_string(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = call i32 @cqrt_tape_alloc()
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 16, i64 16)
  %5 = ptrtoint ptr %4 to i64
  %6 = call i32 @cqrt_alloc_i8(i8 0)
  br label %7

7:                                                ; preds = %7, %1
  %8 = phi i64 [ 0, %1 ], [ %10, %7 ]
  %9 = add i64 %5, %8
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %9, i32 %6)
  %10 = add nuw i64 %8, 1
  %11 = icmp eq i64 %10, 16
  br i1 %11, label %12, label %7

12:                                               ; preds = %7
  %13 = getelementptr inbounds i8, ptr %4, i64 1
  %14 = ptrtoint ptr %13 to i64
  %15 = call i32 @cqrt_alloc_i8(i8 97)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %14, i32 %15)
  %16 = getelementptr inbounds i8, ptr %4, i64 2
  %17 = ptrtoint ptr %16 to i64
  %18 = call i32 @cqrt_alloc_i8(i8 98)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %17, i32 %18)
  %19 = ptrtoint ptr %4 to i64
  %20 = call i32 @cqrt_alloc_i8(i8 %0)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %19, i32 %20)
  %21 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl(i32 %3, i64 %19, i32 %21)
  call void @cqrt_ry_i8(i32 %21, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl(i32 %3, i64 %19, i32 %21)
  call void @cqrt_free(i32 %21)
  %22 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %2, i64 %14)
  call void @cqrt_tape_effect_controlled(i32 %22, i32 %2, ptr @.cq.effect.perror, i32 1)
  call void @cqrt_free(i32 %22)
  %23 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %2, i64 %19)
  call void @cqrt_tape_effect_controlled(i32 %23, i32 %2, ptr @.cq.effect.puts, i32 1)
  call void @cqrt_free(i32 %23)
  ret i32 0
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

; Function Attrs: cold nofree nounwind
declare void @perror(ptr nocapture noundef readonly) local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare ptr @__cq_alloc(i64, i64)

declare i32 @cqrt_alloc_i8(i8)

declare i32 @__cq_mem()

declare void @cqrt_qram_store_i8_hl(i32, i64, i32)

declare void @cqrt_qram_swap_i8_hl(i32, i64, i32)

declare void @cqrt_ry_i8(i32, double)

declare void @cqrt_free(i32)

declare i32 @cqrt_alloc_i1(i1)

declare i32 @cqrt_tape_alloc()

declare void @cqrt_tape_write_i64_lit(i32, i64)

declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)

define internal i32 @__cq_q_stream_reads_string_1_t(i32 %0, i32 %1) {
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %3 = call i32 @cqrt_tape_alloc()
  %4 = call i32 @__cq_mem()
  %5 = call ptr @__cq_alloc(i64 16, i64 16)
  %6 = ptrtoint ptr %5 to i64
  %7 = call i32 @cqrt_alloc_i8(i8 0)
  br label %8

8:                                                ; preds = %8, %2
  %9 = phi i64 [ 0, %2 ], [ %11, %8 ]
  %10 = add i64 %6, %9
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %10, i32 %7)
  %11 = add nuw i64 %9, 1
  %12 = icmp eq i64 %11, 16
  br i1 %12, label %13, label %8

13:                                               ; preds = %8
  %14 = getelementptr inbounds i8, ptr %5, i64 1
  %15 = ptrtoint ptr %14 to i64
  %16 = call i32 @cqrt_alloc_i8(i8 97)
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %15, i32 %16)
  %17 = getelementptr inbounds i8, ptr %5, i64 2
  %18 = ptrtoint ptr %17 to i64
  %19 = call i32 @cqrt_alloc_i8(i8 98)
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %18, i32 %19)
  %20 = ptrtoint ptr %5 to i64
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %20, i32 %0)
  %21 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl(i32 %4, i64 %20, i32 %21)
  call void @cqrt_ry_i8(i32 %21, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl(i32 %4, i64 %20, i32 %21)
  call void @cqrt_free(i32 %21)
  %22 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 %20)
  call void @cqrt_tape_effect_controlled(i32 %22, i32 %3, ptr @.cq.effect.perror, i32 1)
  call void @cqrt_free(i32 %22)
  %23 = call i32 @cqrt_alloc_i1(i1 true)
  call void @cqrt_tape_write_i64_lit(i32 %3, i64 %20)
  call void @cqrt_tape_effect_controlled(i32 %23, i32 %3, ptr @.cq.effect.puts, i32 1)
  call void @cqrt_free(i32 %23)
  %24 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %24)
  %25 = call i32 @cqrt_alloc_i32(i32 0)
  ret i32 %25
}

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

declare void @cqrt_push(i32)

declare i32 @cqrt_alloc_i32(i32)

define internal i32 @__cq_q_stream_reads_string_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_stream_reads_string, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_stream_reads_string, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %31

7:                                                ; preds = %3
  %cq.mints = alloca ptr, align 8
  store ptr null, ptr %cq.mints, align 8
  %8 = call i32 @cqrt_tape_alloc()
  %9 = call i32 @__cq_mem()
  %10 = call ptr @__cq_alloc(i64 16, i64 16)
  %11 = ptrtoint ptr %10 to i64
  %12 = call i32 @cqrt_alloc_i8(i8 0)
  br label %13

13:                                               ; preds = %13, %7
  %14 = phi i64 [ 0, %7 ], [ %16, %13 ]
  %15 = add i64 %11, %14
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %9, i64 %15, i32 %12)
  %16 = add nuw i64 %14, 1
  %17 = icmp eq i64 %16, 16
  br i1 %17, label %18, label %13

18:                                               ; preds = %13
  %19 = getelementptr inbounds i8, ptr %10, i64 1
  %20 = ptrtoint ptr %19 to i64
  %21 = call i32 @cqrt_alloc_i8(i8 97)
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %9, i64 %20, i32 %21)
  %22 = getelementptr inbounds i8, ptr %10, i64 2
  %23 = ptrtoint ptr %22 to i64
  %24 = call i32 @cqrt_alloc_i8(i8 98)
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %9, i64 %23, i32 %24)
  %25 = ptrtoint ptr %10 to i64
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %9, i64 %25, i32 %1)
  %26 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %0, i32 %9, i64 %25, i32 %26)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %26, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %0, i32 %9, i64 %25, i32 %26)
  call void @cqrt_free(i32 %26)
  call void @cqrt_tape_write_i64_lit(i32 %8, i64 %25)
  call void @cqrt_tape_effect_controlled(i32 %0, i32 %8, ptr @.cq.effect.perror, i32 1)
  call void @cqrt_tape_write_i64_lit(i32 %8, i64 %25)
  call void @cqrt_tape_effect_controlled(i32 %0, i32 %8, ptr @.cq.effect.puts, i32 1)
  %27 = load ptr, ptr %cq.mints, align 8
  call void @__cq_mints_push(ptr %27)
  %28 = call i32 @cqrt_alloc_i32(i32 0)
  %29 = load i32, ptr @__cq_act_stream_reads_string, align 4
  %30 = add i32 %29, -1
  store i32 %30, ptr @__cq_act_stream_reads_string, align 4
  ret i32 %28

31:                                               ; preds = %3
  %32 = call i32 @cqrt_alloc_i32(i32 0)
  %33 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %33)
  call void @cqrt_push(i32 0)
  %34 = load i32, ptr @__cq_act_stream_reads_string, align 4
  %35 = add i32 %34, -1
  store i32 %35, ptr @__cq_act_stream_reads_string, align 4
  ret i32 %32
}

declare void @cqrt_qram_store_i8_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_qram_swap_i8_hl_controlled(i32, i32, i64, i32)

declare void @cqrt_ry_i8_controlled(i32, i32, double)

declare void @cqrt_copy_i1(i32, i32)

define internal i32 @__cq_q_stream_reads_string_1_t_ctl_pure(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_stream_reads_string, align 4
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_stream_reads_string, align 4
  %6 = icmp ult i32 %4, %2
  br i1 %6, label %7, label %29

7:                                                ; preds = %3
  %8 = call i32 @__cq_mem()
  %9 = call ptr @__cq_alloc(i64 16, i64 16)
  %10 = ptrtoint ptr %9 to i64
  %11 = call i32 @cqrt_alloc_i8(i8 0)
  br label %12

12:                                               ; preds = %12, %7
  %13 = phi i64 [ 0, %7 ], [ %15, %12 ]
  %14 = add i64 %10, %13
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %14, i32 %11)
  %15 = add nuw i64 %13, 1
  %16 = icmp eq i64 %15, 16
  br i1 %16, label %17, label %12

17:                                               ; preds = %12
  %18 = getelementptr inbounds i8, ptr %9, i64 1
  %19 = ptrtoint ptr %18 to i64
  %20 = call i32 @cqrt_alloc_i8(i8 97)
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %19, i32 %20)
  %21 = getelementptr inbounds i8, ptr %9, i64 2
  %22 = ptrtoint ptr %21 to i64
  %23 = call i32 @cqrt_alloc_i8(i8 98)
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %22, i32 %23)
  %24 = ptrtoint ptr %9 to i64
  call void @cqrt_qram_store_i8_hl_controlled(i32 %0, i32 %8, i64 %24, i32 %1)
  %25 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %0, i32 %8, i64 %24, i32 %25)
  call void @cqrt_ry_i8_controlled(i32 %0, i32 %25, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl_controlled(i32 %0, i32 %8, i64 %24, i32 %25)
  call void @cqrt_free(i32 %25)
  %26 = call i32 @cqrt_alloc_i32(i32 0)
  %27 = load i32, ptr @__cq_act_stream_reads_string, align 4
  %28 = add i32 %27, -1
  store i32 %28, ptr @__cq_act_stream_reads_string, align 4
  ret i32 %26

29:                                               ; preds = %3
  %30 = call i32 @cqrt_alloc_i32(i32 0)
  %31 = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_copy_i1(i32 %0, i32 %31)
  %32 = load i32, ptr @__cq_act_stream_reads_string, align 4
  %33 = add i32 %32, -1
  store i32 %33, ptr @__cq_act_stream_reads_string, align 4
  ret i32 %30
}

define internal i32 @__cq_q_stream_reads_string_1_t_pure(i32 %0, i32 %1) {
  %3 = call i32 @__cq_mem()
  %4 = call ptr @__cq_alloc(i64 16, i64 16)
  %5 = ptrtoint ptr %4 to i64
  %6 = call i32 @cqrt_alloc_i8(i8 0)
  br label %7

7:                                                ; preds = %7, %2
  %8 = phi i64 [ 0, %2 ], [ %10, %7 ]
  %9 = add i64 %5, %8
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %9, i32 %6)
  %10 = add nuw i64 %8, 1
  %11 = icmp eq i64 %10, 16
  br i1 %11, label %12, label %7

12:                                               ; preds = %7
  %13 = getelementptr inbounds i8, ptr %4, i64 1
  %14 = ptrtoint ptr %13 to i64
  %15 = call i32 @cqrt_alloc_i8(i8 97)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %14, i32 %15)
  %16 = getelementptr inbounds i8, ptr %4, i64 2
  %17 = ptrtoint ptr %16 to i64
  %18 = call i32 @cqrt_alloc_i8(i8 98)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %17, i32 %18)
  %19 = ptrtoint ptr %4 to i64
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %19, i32 %0)
  %20 = call i32 @cqrt_alloc_i8(i8 0)
  call void @cqrt_qram_swap_i8_hl(i32 %3, i64 %19, i32 %20)
  call void @cqrt_ry_i8(i32 %20, double 3.000000e-01)
  call void @cqrt_qram_swap_i8_hl(i32 %3, i64 %19, i32 %20)
  call void @cqrt_free(i32 %20)
  %21 = call i32 @cqrt_alloc_i32(i32 0)
  ret i32 %21
}

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @stream_reads_string, ptr @.cq.sig, ptr @__cq_q_stream_reads_string_1_t, ptr @__cq_q_stream_reads_string_1_t_ctl, ptr @__cq_q_stream_reads_string_1_t_unc, ptr @__cq_q_stream_reads_string_1_t_ctl_unc)
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)

define internal void @__cq_q_stream_reads_string_1_t_unc(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cqrt_pop()
  br label %5

5:                                                ; preds = %8, %3
  %6 = phi i32 [ %4, %3 ], [ %10, %8 ]
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %11, label %8

8:                                                ; preds = %5
  %9 = call i32 @cqrt_pop()
  %10 = sub i32 %6, 1
  br label %5

11:                                               ; preds = %5
  ret void
}

define internal void @__cq_q_stream_reads_string_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_stream_reads_string, align 4
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_stream_reads_string, align 4
  %7 = load i32, ptr @__cq_act_stream_reads_string, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_stream_reads_string, align 4
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

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { cold nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
