; tests/aggr probe (cq-z6bul): a quantum scalar x updated by scalar adds (spine's rule 6 cleans x from x + 3) whose
; lanes are then multiplied by a constant vector (aggr's lane rule 6 would clean x a second time). clang -O1 of:
; unsigned vec(unsigned x0, double t){unsigned x=x0;cq_theta(&x,t);v4u s=(v4u){x,x+1,x+2,x+3};
;   v4u m=s*(v4u){3,5,7,9};unsigned r=m.x+m.y+m.z+m.w;return cq_measure(r);}  (v4u: unsigned ext_vector_type(4))
; ModuleID = 'mulconst.c'
source_filename = "mulconst.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @v_mulconst(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %4 = insertelement <4 x i32> poison, i32 %3, i64 0
  %5 = add i32 %3, 1
  %6 = insertelement <4 x i32> %4, i32 %5, i64 1
  %7 = add i32 %3, 2
  %8 = insertelement <4 x i32> %6, i32 %7, i64 2
  %9 = add i32 %3, 3
  %10 = insertelement <4 x i32> %8, i32 %9, i64 3
  %11 = mul <4 x i32> %10, <i32 3, i32 5, i32 7, i32 9>
  %12 = shufflevector <4 x i32> %11, <4 x i32> poison, <4 x i32> <i32 1, i32 poison, i32 poison, i32 poison>
  %13 = add <4 x i32> %11, %12
  %14 = shufflevector <4 x i32> %11, <4 x i32> poison, <4 x i32> <i32 2, i32 poison, i32 poison, i32 poison>
  %15 = add <4 x i32> %13, %14
  %16 = shufflevector <4 x i32> %11, <4 x i32> poison, <4 x i32> <i32 3, i32 poison, i32 poison, i32 poison>
  %17 = add <4 x i32> %15, %16
  %18 = extractelement <4 x i32> %17, i64 0
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #3
  ret i32 %19
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
