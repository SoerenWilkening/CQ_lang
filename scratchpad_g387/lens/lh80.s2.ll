; ModuleID = 'scratchpad_g387/lens/lh80.s1.ll'
source_filename = "scratchpad_g387/lens/lh80.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %h = call i32 @cqrt_alloc_f80(x86_fp80 0xK00000000000000000000)
  call void @cqrt_ry_f80(i32 %h, double 3.000000e-01)
  %h_libm = call i32 @cq_template_remquo_f80_lh(x86_fp80 0xK4001E000000000000000, i32 %h)
  %h_libm1 = call i32 @cq_template_remquoquo_f80_to_i32_lh(x86_fp80 0xK4001E000000000000000, i32 %h)
  %m = call i32 @cqrt_measure_i32(i32 %h_libm1)
  ret i32 %m
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nofree nounwind willreturn memory(write)
declare x86_fp80 @remquol(x86_fp80 noundef, x86_fp80 noundef, ptr nocapture noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare void @cqrt_ry_f80(i32, double)

declare i32 @cqrt_alloc_f80(x86_fp80)

declare i32 @cq_template_remquo_f80_lh(x86_fp80, i32)

declare i32 @cq_template_remquoquo_f80_to_i32_lh(x86_fp80, i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nofree nounwind willreturn memory(write) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
