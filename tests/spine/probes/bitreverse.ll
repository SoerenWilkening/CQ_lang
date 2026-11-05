; cq-jkq8 (CR §1.2, f684858): llvm.bitreverse of a quantum value is its template; rule 6 cleans the dead old
; value through bitreverse (an involution). Rule 6 composite updates beyond the affine class (127): brev8's
; bitreverse(x) ^ x is no bijection (x kept); gf2's (x << 1) ^ x is one, inverted by a QROM of its inverse table.
; CHECK brev32: call i32 @cq_template_bitreverse_i32(
; CHECK gf2: @cqrt_qram_load_i8(
; USERCHECK brev32
; USERCHECK brev8
; USERCHECK gf2
; Source:
;   #include "CQ.h"
;   /* rule 4 / §1.2: bitreverse of a quantum value is its template; rule 6: x is dead after x' = bitreverse(x),
;      so the old rail is cleaned by bitreverse(x') (an involution). */
;   unsigned brev32(unsigned x0, double th) {
;     unsigned x = x0; cq_theta(&x, th);
;     unsigned y = __builtin_bitreverse32(x);
;     return cq_measure(y);
;   }
;   unsigned char brev8(unsigned char x0, double th) {
;     unsigned char x = x0; cq_theta(&x, th);
;     unsigned char y = __builtin_bitreverse8(x) ^ x;
;     return cq_measure(y);
;   }
;   /* rule 6 composite update (127) beyond the affine class: y = (x << 1) ^ x is a bijection of x (decided over the
;      width, inverted by a QROM of its inverse table); bitreverse(x) ^ x above is none (x is kept). */
;   unsigned char gf2(unsigned char x0, double th) {
;     unsigned char x = x0; cq_theta(&x, th);
;     unsigned char y = (unsigned char)(x << 1) ^ x;
;     return cq_measure(y);
;   }
; ModuleID = 'bitrev.c'
source_filename = "bitrev.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @brev32(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #3
  %4 = tail call i32 @llvm.bitreverse.i32(i32 %3)
  %5 = tail call i32 @cq_measure_ui32(i32 noundef %4) #4
  ret i32 %5
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.bitreverse.i32(i32) #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define zeroext i8 @brev8(i8 noundef zeroext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3
  %4 = tail call i8 @llvm.bitreverse.i8(i8 %3)
  %5 = xor i8 %4, %3
  %6 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %5) #4
  ret i8 %6
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i8 @llvm.bitreverse.i8(i8) #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define zeroext i8 @gf2(i8 noundef zeroext %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3
  %4 = shl i8 %3, 1
  %5 = xor i8 %4, %3
  %6 = tail call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %5) #4
  ret i8 %6
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
