; cq-k65d: green under cqcheck user (300 samples). C source:
; | #include <stdlib.h>
; | typedef int v4 __attribute__((vector_size(16)));
; | static char small[2];
; | static _Thread_local int tl[4];
; | /* a thread-local QRAM (rule 24: one thread) */
; | int qram_tls(int x, double th) {
; |     cq_theta(&x, th);
; |     tl[x & 3] = x;
; |     return cq_measure(tl[1] + tl[x & 1]);
; | }

@tl = internal thread_local unnamed_addr global [4 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @qram_tls(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %4 = tail call align 16 ptr @llvm.threadlocal.address.p0(ptr align 16 @tl)
  %5 = and i32 %3, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %6
  store i32 %3, ptr %7, align 4
  %8 = getelementptr inbounds i8, ptr %4, i64 4
  %9 = load i32, ptr %8, align 4
  %10 = and i32 %3, 1
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = add nsw i32 %13, %9
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare nonnull ptr @llvm.threadlocal.address.p0(ptr nonnull)

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr



; CHECK qram_tls: cqrt_qram_
