; ModuleID = 'g02_guarded_ctrl.s1.ll'
source_filename = "g02_guarded_ctrl.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call fastcc i32 @guarded_local()
  %2 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %1)
  ret i32 0
}

; Function Attrs: nofree nounwind
declare noundef i32 @printf(ptr nocapture noundef readonly, ...) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @guarded_local() unnamed_addr #2 {
  %arr = call i32 @cqrt_qram_alloc_i32(i32 8)
  %h = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %h1 = call i32 @cqrt_alloc_i32(i32 1)
  call void @cqrt_ry_i32(i32 %h1, double 5.000000e-01)
  %h2 = call i32 @cqrt_alloc_i32(i32 2)
  call void @cqrt_ry_i32(i32 %h2, double 5.000000e-01)
  %h3 = call i32 @cqrt_alloc_i32(i32 3)
  call void @cqrt_ry_i32(i32 %h3, double 5.000000e-01)
  %h_cmp = call i32 @cq_template_icmp_slt_i32_hl(i32 %h, i32 3)
  %qval = call i32 @cqrt_alloc_i32(i32 7)
  call void @cqrt_qram_store_i32_controlled(i32 %h_cmp, i32 %arr, i32 %h1, i32 %qval)
  br label %1

1:                                                ; preds = %0
  %2 = call i32 @cqrt_qram_load_i32(i32 %arr, i32 %h)
  %qret = call i32 @cqrt_alloc_i32(i32 0)
  call void @cqrt_copy_i32(i32 %2, i32 %qret)
  call void @cqrt_qram_load_i32_unc(i32 %2, i32 %arr, i32 %h)
  call void @cqrt_free(i32 %2)
  call void @cqrt_qram_store_i32_controlled_unc(i32 %h_cmp, i32 %arr, i32 %h1, i32 %qval)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 3)
  call void @cqrt_free(i32 %h_cmp)
  call void @cqrt_ry_i32(i32 %h1, double -5.000000e-01)
  call void @cqrt_ry_i32(i32 %h, double -5.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %qret)
  %m4 = call i32 @cqrt_measure_i32(i32 %h2)
  %3 = add nsw i32 %m4, %m
  %m5 = call i32 @cqrt_measure_i32(i32 %h3)
  %4 = add nsw i32 %3, %m5
  ret i32 %4
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #3

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #3

declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)

declare i32 @cqrt_qram_alloc_i32(i32)

declare i32 @cqrt_qram_load_i32(i32, i32)

declare void @cqrt_qram_store_i32(i32, i32, i32)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_qram_store_i32_controlled(i32, i32, i32, i32)

declare void @cqrt_copy_i32(i32, i32)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_measure_i32(i32)

declare void @cqrt_qram_load_i32_unc(i32, i32, i32)

declare void @cqrt_free(i32)

declare void @cqrt_qram_store_i32_controlled_unc(i32, i32, i32, i32)

declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nocallback nofree nounwind willreturn memory(argmem: write) }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
