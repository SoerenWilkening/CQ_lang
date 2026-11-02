; cq-a63l (CR rule 16 fields over rule 21): see tape_fat_fields.c (clang 19.1.7 -O1).
; CHECK fat_str: call void @cqrt_tape_str_begin(i32 %{{t}})
; CHECK-COUNT fat_str: @cq_template_select_i8_ll( 3
; CHECK-COUNT fat_str: @cqrt_tape_write_i8_lit( 1
; CHECK fat_str: call void @cqrt_tape_str_end(i32 %{{t}})
; CHECK-COUNT fat_write: @cqrt_tape_write_i8( 2
source_filename = "fatstr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.fat_str.a = private unnamed_addr constant [3 x i8] c"ab\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @fat_str(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  %3 = and i32 %0, 1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 8.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #5
  store i32 8026488, ptr %2, align 4
  %5 = icmp eq i32 %4, 0
  %6 = select i1 %5, ptr %2, ptr @__const.fat_str.a
  %7 = call i32 @puts(ptr nonnull dereferenceable(1) %6)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %4) #5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #5
  ret i32 %8
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @fat_write(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [2 x i8], align 2
  %3 = alloca [2 x i8], align 2
  %4 = and i32 %0, 1
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 8.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %2) #5
  store i16 25185, ptr %2, align 2
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %3) #5
  store i16 31096, ptr %3, align 2
  %6 = icmp eq i32 %5, 0
  %7 = select i1 %6, ptr %3, ptr %2
  %8 = call i64 @"\01_write"(i32 noundef 1, ptr noundef nonnull %7, i64 noundef 2) #5
  %9 = call i32 @cq_measure_si32(i32 noundef %5) #5
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %3) #5
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %2) #5
  ret i32 %9
}

declare i64 @"\01_write"(i32 noundef, ptr noundef, i64 noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @puts(ptr nocapture noundef readonly) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind }
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
