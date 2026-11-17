; ModuleID = 'int_widths.c'
source_filename = "int_widths.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define signext i8 @add_i8(i8 noundef signext %0, double noundef %1, i8 noundef signext %2) local_unnamed_addr #0 {
  %4 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = add i8 %4, %2    ; C: y = x + c;
  %6 = tail call signext i8 @cq_measure_si8(i8 noundef signext %5) #3    ; C: cq_measure(y)
  ret i8 %6    ; C: return
}

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #1

declare signext i8 @cq_measure_si8(i8 noundef signext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define signext i16 @add_i16(i16 noundef signext %0, double noundef %1, i16 noundef signext %2) local_unnamed_addr #0 {
  %4 = tail call signext i16 @cq_theta_si16(i16 noundef signext %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = add i16 %4, %2    ; C: y = x + c;
  %6 = tail call signext i16 @cq_measure_si16(i16 noundef signext %5) #3    ; C: cq_measure(y)
  ret i16 %6    ; C: return
}

declare signext i16 @cq_theta_si16(i16 noundef signext, double noundef) local_unnamed_addr #1

declare signext i16 @cq_measure_si16(i16 noundef signext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i64 @add_i64(i64 noundef %0, double noundef %1, i64 noundef %2) local_unnamed_addr #0 {
  %4 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef %1) #2    ; C: cq_theta(&x, th);
  %5 = add nsw i64 %4, %2    ; C: x + c
  %6 = tail call i64 @cq_measure_sll(i64 noundef %5) #3    ; C: cq_measure(x + c)
  ret i64 %6    ; C: return
}

declare i64 @cq_theta_sll(i64 noundef, double noundef) local_unnamed_addr #1

declare i64 @cq_measure_sll(i64 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define zeroext i1 @and_i1(i1 noundef zeroext %0, i1 noundef zeroext %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %0, double noundef %2) #2    ; C: cq_theta(&x, tx);
  %6 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %1, double noundef %3) #2    ; C: cq_theta(&y, ty);
  %7 = and i1 %5, %6    ; C: z = x & y;
  %8 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %7) #3    ; C: cq_measure(z)
  ret i1 %8    ; C: return
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

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
