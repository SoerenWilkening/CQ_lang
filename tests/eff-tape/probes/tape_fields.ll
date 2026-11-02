; cq-a63l (CR rule 16 fields at f684858): see tape_fields.c (clang 19.1.7 -O1).
; CHECK fwrite_stream: call void @cqrt_tape_effect_controlled(i32 %{{f}}, i32 %{{t}}, ptr @.cq.effect.fwrite)
; CHECK-COUNT fwrite_stream: @cqrt_tape_write_i8_lit( 1
; CHECK-COUNT fwrite_stream: @cqrt_tape_write_i64_lit( 3
; CHECK-COUNT fwrite_stream: @fwrite( 0
; CHECK write_qlen: call void @cqrt_tape_effect_controlled(i32 %{{f}}, i32 %{{t}}, ptr @.cq.effect.write)
; CHECK-COUNT write_qlen: @cqrt_tape_write_i8_controlled( 4
; CHECK-COUNT write_qlen: @cq_template_icmp_ugt_i64_hl( 4
; CHECK-COUNT write_qlen: @cqrt_tape_write_i64_controlled( 1
; CHECK printf_runtime_fmt: @snprintf(ptr null, i64 0, ptr %{{f}}, i32 %{{k}}, ptr %{{p}})
; CHECK-COUNT printf_runtime_fmt: @cqrt_tape_write_i64_lit( 1
; CHECK kill_effect: call void @cqrt_tape_effect_controlled(i32 %{{f}}, i32 %{{t}}, ptr @.cq.effect.kill)
; CHECK-COUNT kill_effect: @cqrt_tape_write_i32_lit( 2
; CHECK str_slot: call void @cqrt_tape_str_begin(i32 %{{t}})
; CHECK-COUNT str_slot: @cqrt_tape_write_i8( 3
; CHECK str_slot: call void @cqrt_tape_str_end(i32 %{{t}})
source_filename = "tape_fields.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.fwrite_stream.buf = private unnamed_addr constant [16 x i8] c"abcdefghijklmno\00", align 16
@__const.str_slot.s = private unnamed_addr constant [3 x i8] c"a\00\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @fwrite_stream(i32 noundef %0, i32 noundef %1, ptr noundef %2) local_unnamed_addr #0 {
  %4 = alloca [16 x i8], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #6
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #7
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) @__const.fwrite_stream.buf, i64 16, i1 false)
  %6 = icmp sgt i32 %5, 3
  br i1 %6, label %7, label %10

7:                                                ; preds = %3
  %8 = sext i32 %1 to i64
  %9 = call i64 @"\01_fwrite"(ptr noundef nonnull %4, i64 noundef 1, i64 noundef %8, ptr noundef %2) #7
  br label %10

10:                                               ; preds = %7, %3
  %11 = call i32 @cq_measure_si32(i32 noundef %5) #7
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #7
  ret i32 %11
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

declare i64 @"\01_fwrite"(ptr noundef, i64 noundef, i64 noundef, ptr noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @write_qlen(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  %3 = and i32 %0, 3
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.000000e+00) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #7
  store i32 1684234849, ptr %2, align 4
  %5 = trunc i32 %4 to i8
  store i8 %5, ptr %2, align 4, !tbaa !6
  %6 = icmp sgt i32 %4, 1
  br i1 %6, label %7, label %10

7:                                                ; preds = %1
  %8 = zext nneg i32 %4 to i64
  %9 = call i64 @"\01_write"(i32 noundef 1, ptr noundef nonnull %2, i64 noundef %8) #7
  br label %10

10:                                               ; preds = %7, %1
  %11 = call i32 @cq_measure_si32(i32 noundef %4) #7
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #7
  ret i32 %11
}

declare i64 @"\01_write"(i32 noundef, ptr noundef, i64 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @printf_runtime_fmt(i32 noundef %0, i32 noundef %1, ptr nocapture noundef readonly %2, ptr noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #6
  %6 = icmp sgt i32 %5, 3
  br i1 %6, label %7, label %9

7:                                                ; preds = %4
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) %2, i32 noundef %1, ptr noundef %3)
  br label %9

9:                                                ; preds = %7, %4
  %10 = tail call i32 @cq_measure_si32(i32 noundef %5) #7
  ret i32 %10
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #4

; Function Attrs: nounwind ssp uwtable
define i32 @kill_effect(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 1.000000e+00) #6
  %4 = icmp sgt i32 %3, 3
  br i1 %4, label %5, label %7

5:                                                ; preds = %2
  %6 = tail call i32 @"\01_kill"(i32 noundef %1, i32 noundef 30) #7
  br label %7

7:                                                ; preds = %5, %2
  %8 = tail call i32 @cq_measure_si32(i32 noundef %3) #7
  ret i32 %8
}

declare i32 @"\01_kill"(i32 noundef, i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @str_slot(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [3 x i8], align 1
  %3 = and i32 %0, 127
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.000000e+00) #6
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %2) #7
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %2, ptr noundef nonnull align 1 dereferenceable(3) @__const.str_slot.s, i64 3, i1 false)
  %5 = trunc i32 %4 to i8
  %6 = getelementptr inbounds i8, ptr %2, i64 1
  store i8 %5, ptr %6, align 1, !tbaa !6
  %7 = call i32 @puts(ptr nonnull dereferenceable(1) %2)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4) #7
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %2) #7
  ret i32 %8
}

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree nounwind }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }

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
