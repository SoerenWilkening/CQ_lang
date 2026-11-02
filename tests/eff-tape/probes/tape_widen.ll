; cq-py5f (CR rule 16, §1.3): tape entries over rule 16's class (tape_widen.c).
; CHECK pos_printf: call void @cqrt_tape_fmt(i32 %{{t}}, ptr @".cqfmt.p.%d %d %d\0A")
; CHECK-COUNT pos_printf: @cqrt_tape_write_i32_lit( 2
; CHECK-COUNT pos_printf: @cqrt_tape_write_i32( 1
; CHECK runtime_fputs: call void @cqrt_tape_fmt(i32 %{{t}}, ptr @.cqfmt.fputs)
; CHECK runtime_fputs: call void @cqrt_tape_write_str_lit(i32 %{{t}}, ptr %{{b}})
; CHECK fwrite_classical: call void @cqrt_tape_fmt(i32 %{{t}}, ptr @.cqfmt.fwrite3)
; CHECK-COUNT fwrite_classical: @cqrt_tape_write_i8_lit( 3
; CHECK effect_after_tape: call i32 @cqrt_alloc_i1(i1 true)
; CHECK effect_after_tape: call void @cqrt_tape_effect_controlled(i32 %{{c}}, i32 %{{t}}, ptr @.cq.effect.remove)
; CHECK-COUNT effect_after_tape: @remove( 0
; CHECK exit_quantum: call void @cqrt_abort_i1(i32 %{{f}})
; CHECK-COUNT exit_quantum: @exit( 0
; CHECK abort_flag_rotated: call void @cqrt_copy_i1_controlled(i32 %{{f}}, i32 %{{b}}, i32 %{{s}})
; CHECK-COUNT abort_flag_rotated: @cqrt_abort_i1( 1
; ModuleID = 'tape_widen.c'
source_filename = "tape_widen.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [16 x i8] c"%2$d %1$d %2$d\0A\00", align 1
@.str.1 = private unnamed_addr constant [6 x i8] c"x %d\0A\00", align 1
@__stdoutp = external local_unnamed_addr global ptr, align 8
@.str.2 = private unnamed_addr constant [18 x i8] c"/tmp/cq_py5f_none\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @pos_printf(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #6
  %4 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %3, i32 noundef %1)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %3) #7
  ret i32 %5
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @runtime_fputs(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i8], align 1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #6
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, i32 noundef %4)
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #7
  store i8 104, ptr %3, align 1, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %3, i64 1
  store i8 105, ptr %6, align 1, !tbaa !6
  %7 = getelementptr inbounds i8, ptr %3, i64 2
  %8 = trunc i32 %1 to i8
  %9 = and i8 %8, 7
  %10 = or disjoint i8 %9, 48
  store i8 %10, ptr %7, align 1, !tbaa !6
  %11 = getelementptr inbounds i8, ptr %3, i64 3
  store i8 0, ptr %11, align 1, !tbaa !6
  %12 = load ptr, ptr @__stdoutp, align 8, !tbaa !9
  %13 = call i32 @"\01_fputs"(ptr noundef nonnull %3, ptr noundef %12) #7
  %14 = call i32 @cq_measure_si32(i32 noundef %4) #7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #7
  ret i32 %14
}

declare i32 @"\01_fputs"(ptr noundef, ptr noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @fwrite_classical(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [3 x i8], align 1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #6
  %5 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, i32 noundef %4)
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %3) #7
  store i8 97, ptr %3, align 1, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %3, i64 1
  %7 = trunc i32 %1 to i8
  %8 = and i8 %7, 7
  %9 = or disjoint i8 %8, 48
  store i8 %9, ptr %6, align 1, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %3, i64 2
  store i8 10, ptr %10, align 1, !tbaa !6
  %11 = load ptr, ptr @__stdoutp, align 8, !tbaa !9
  %12 = call i64 @"\01_fwrite"(ptr noundef nonnull %3, i64 noundef 1, i64 noundef 3, ptr noundef %11) #7
  %13 = call i32 @cq_measure_si32(i32 noundef %4) #7
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %3) #7
  ret i32 %13
}

declare i64 @"\01_fwrite"(ptr noundef, i64 noundef, i64 noundef, ptr noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @effect_after_tape(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #6
  %3 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str.1, i32 noundef %2)
  %4 = tail call i32 @remove(ptr noundef nonnull @.str.2)
  %5 = tail call i32 @cq_measure_si32(i32 noundef %2) #7
  ret i32 %5
}

; Function Attrs: nofree nounwind
declare noundef i32 @remove(ptr nocapture noundef readonly) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @exit_quantum(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #6
  %4 = icmp sgt i32 %3, %1
  br i1 %4, label %5, label %6

5:                                                ; preds = %2
  tail call void @exit(i32 noundef %3) #8
  unreachable

6:                                                ; preds = %2
  %7 = tail call i32 @cq_measure_si32(i32 noundef %3) #7
  ret i32 %7
}

; Function Attrs: noreturn
declare void @exit(i32 noundef) local_unnamed_addr #4

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 2) i32 @abort_flag_rotated(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = and i32 %0, 1
  %4 = icmp ne i32 %3, 0
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %4, double noundef 1.000000e+00) #6
  %6 = icmp sgt i32 %1, 0
  %7 = and i1 %6, %5
  br i1 %7, label %8, label %9

8:                                                ; preds = %2
  tail call void @abort() #9
  unreachable

9:                                                ; preds = %2
  %10 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %5, double noundef 5.000000e-01) #6
  %11 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %10) #7
  %12 = zext i1 %11 to i32
  ret i32 %12
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #2

; Function Attrs: cold noreturn nounwind
declare void @abort() local_unnamed_addr #5

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { cold noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }
attributes #8 = { noreturn nounwind }
attributes #9 = { cold noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"any pointer", !7, i64 0}
