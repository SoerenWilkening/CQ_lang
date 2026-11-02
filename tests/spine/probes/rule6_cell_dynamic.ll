; cq-8101: an old value stored into a local slot array and read back at a run-time classical index
; (unc-h2 p13, p19): the clean-up waits until each such read and its readers are lowered and kept, notes
; them as uses (mem-slots records the load as a register of its own), and is placed after them, before
; the gate on x + 1. The memset's seeds are never written: released after the reads naming them (rule 7;
; p18, p19). @dyn_measured (p17): a read that may name x is measured: x and the seeds are kept.
; CHECK-COUNT dyn_store: call void @cqrt_copy_i32( 1
; CHECK-COUNT dyn_load: call void @cqrt_copy_i32( 1
; CHECK-COUNT dyn_load: call void @cqrt_free( 6
; CHECK-COUNT dyn_measured: call void @cqrt_copy_i32( 0
; CHECK-COUNT dyn_seeds: call void @cqrt_free( 4
;
; C: int dyn_store(int x0, int n, int m, double th) {
; C:     int x = x0;
; C:     cq_theta(&x, th);
; C:     int a[4] = {0, 0, 0, 0};
; C:     a[n & 3] = x;
; C:     x = x + 1;
; C:     int r = cq_measure(a[m & 3] * 5);
; C:     cq_theta(&x, th);
; C:     return r ^ cq_measure(x);
; C: }
; C: int dyn_load(int x0, int m, double th) {
; C:     int x = x0;
; C:     cq_theta(&x, th);
; C:     int a[4] = {0, 0, 0, 0};
; C:     a[1] = x;
; C:     x = x + 1;
; C:     int r = cq_measure(a[m & 3] * 5);
; C:     cq_theta(&x, th);
; C:     return r ^ cq_measure(x);
; C: }
; C: int dyn_measured(int x0, int m, double th) {
; C:     int x = x0;
; C:     cq_theta(&x, th);
; C:     int a[4] = {0, 0, 0, 0};
; C:     a[1] = x;
; C:     x = x + 1;
; C:     int r = cq_measure(a[m & 3]);
; C:     cq_theta(&x, th);
; C:     return r ^ cq_measure(x);
; C: }
; C: int dyn_seeds(int x0, int n, int m, double th) {
; C:     int x = x0;
; C:     cq_theta(&x, th);
; C:     int a[4] = {0, 0, 0, 0};
; C:     a[n & 3] = x;
; C:     int r = cq_measure(a[m & 3] * 5);
; C:     return r;
; C: }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @dyn_store(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr {
  %5 = alloca [4 x i32], align 16
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, i8 0, i64 16, i1 false)
  %7 = and i32 %1, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %8
  store i32 %6, ptr %9, align 4
  %10 = add nsw i32 %6, 1
  %11 = and i32 %2, 3
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4
  %15 = mul nsw i32 %14, 5
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15)
  %17 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef %3)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17)
  %19 = xor i32 %18, %16
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5)
  ret i32 %19
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

; Function Attrs: nounwind ssp uwtable
define i32 @dyn_load(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  %6 = getelementptr inbounds i8, ptr %4, i64 4
  store i32 %5, ptr %6, align 4
  %7 = add nsw i32 %5, 1
  %8 = and i32 %1, 3
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %9
  %11 = load i32, ptr %10, align 4
  %12 = mul nsw i32 %11, 5
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12)
  %14 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef %2)
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  %16 = xor i32 %15, %13
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @dyn_measured(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  %6 = getelementptr inbounds i8, ptr %4, i64 4
  store i32 %5, ptr %6, align 4
  %7 = add nsw i32 %5, 1
  %8 = and i32 %1, 3
  %9 = zext nneg i32 %8 to i64
  %10 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %9
  %11 = load i32, ptr %10, align 4
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %13 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef %2)
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13)
  %15 = xor i32 %14, %12
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @dyn_seeds(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr {
  %5 = alloca [4 x i32], align 16
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, i8 0, i64 16, i1 false)
  %7 = and i32 %1, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %8
  store i32 %6, ptr %9, align 4
  %10 = and i32 %2, 3
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = mul nsw i32 %13, 5
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5)
  ret i32 %15
}



