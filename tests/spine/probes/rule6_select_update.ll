; /* tests/spine probe (CR rule 6 in-place update, a select of an update; owner ruling pending 2026-11-26, cq-6wef6):
;  * `if (c) y += o;`, which -O1 makes `select c, y + o, y`, lowers as `y += c ? o : 0;` does: the select on the other
;  * operand, the in-place gate, the select's _unc. Either arm order, add or xor (with a rail -O1 already
;  * selects the operand). */
; #include <stdbool.h>
; int if_add(unsigned char a0, double ta, double tx) {
;   unsigned char a = a0;
;   bool x = 0;
;   cq_theta(&a, ta);
;   cq_theta(&x, tx);
;   if (x) a += 7;
;   return cq_measure(a) + cq_measure(x);
; }
; int unless_add(int a0, double ta, int b0, double tb) {
;   int a = a0, b = b0;
;   cq_theta(&a, ta);
;   cq_theta(&b, tb);
;   if (!(b > 3)) a += 9;
;   return cq_measure(a) + cq_measure(b);
; }
; int if_xor(unsigned a0, double ta, int b0, double tb) {
;   unsigned a = a0;
;   int b = b0;
;   cq_theta(&a, ta);
;   cq_theta(&b, tb);
;   if (b < 0) a ^= 0x55;
;   return cq_measure(a) + cq_measure(b);
; }
source_filename = "tests/spine/probes/rule6_select_update.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 257) i32 @if_add(i8 noundef zeroext %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #2
  %5 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef %2) #2
  %6 = add i8 %4, 7
  %7 = select i1 %5, i8 %6, i8 %4
  %8 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %7) #3
  %9 = zext i8 %8 to i32
  %10 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %5) #3
  %11 = zext i1 %10 to i32
  %12 = add nuw nsw i32 %11, %9
  ret i32 %12
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #1

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @unless_add(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #2
  %7 = icmp sgt i32 %6, 3
  %8 = add nsw i32 %5, 9
  %9 = select i1 %7, i32 %5, i32 %8
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  %12 = add nsw i32 %11, %10
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @if_xor(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %3) #2
  %7 = icmp slt i32 %6, 0
  %8 = xor i32 %5, 85
  %9 = select i1 %7, i32 %8, i32 %5
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #3
  %11 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  %12 = add i32 %11, %10
  ret i32 %12
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
; USERCHECK if_add
; USERCHECK unless_add
; USERCHECK if_xor
; CHECK if_add: call i32 @cq_template_select_i8_ll(i32 %{{x}}, i8 7, i8 0)
; CHECK if_add: call void @cqrt_add_i8(i32 %{{s}}, i32 %{{a}})
; CHECK-COUNT if_add: @cq_template_add 0
; CHECK unless_add: call i32 @cq_template_select_i32_ll(i32 %{{c}}, i32 0, i32 9)
; CHECK unless_add: call void @cqrt_add_i32(i32 %{{s}}, i32 %{{a}})
; CHECK-COUNT unless_add: @cq_template_add 0
; CHECK if_xor: call i32 @cq_template_select_i32_ll(i32 %{{c}}, i32 85, i32 0)
; CHECK if_xor: call void @cqrt_copy_i32(i32 %{{s}}, i32 %{{a}})
; CHECK-COUNT if_xor: @cq_template_xor 0
