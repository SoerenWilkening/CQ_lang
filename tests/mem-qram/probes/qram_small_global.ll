; cq-k65d: green under cqcheck user (300 samples). C source:
; | #include <stdlib.h>
; | typedef int v4 __attribute__((vector_size(16)));
; | static char small[2];
; | static _Thread_local int tl[4];
; | /* a global QRAM smaller than its bus handles: the handles live beside it */
; | int qram_small_global(int x, double th) {
; |     cq_theta(&x, th);
; |     small[x & 1] = 5;
; |     return cq_measure(small[0] + 2 * small[1]);
; | }

@small = internal unnamed_addr global [2 x i8] zeroinitializer, align 1

; Function Attrs: nounwind ssp uwtable
define i32 @qram_small_global(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %4 = and i32 %3, 1
  %5 = zext nneg i32 %4 to i64
  %6 = getelementptr inbounds [2 x i8], ptr @small, i64 0, i64 %5
  store i8 5, ptr %6, align 1
  %7 = load i8, ptr @small, align 1
  %8 = sext i8 %7 to i32
  %9 = load i8, ptr getelementptr inbounds (i8, ptr @small, i64 1), align 1
  %10 = sext i8 %9 to i32
  %11 = shl nsw i32 %10, 1
  %12 = add nsw i32 %11, %8
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12)
  ret i32 %13
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr



; CHECK qram_small_global: cqrt_qram_
