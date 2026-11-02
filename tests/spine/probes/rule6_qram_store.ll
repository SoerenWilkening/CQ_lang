; cq-719y: a store of y into a local QRAM copies its value onto the bus; the store's POP re-reads y (a
; reader that moves the clean-up) and the bus dies with the frame: no escape. y is cleaned from y + 3 after
; the POP (qram-h2 p12d). A load of that bus feeding the inverse would read y (168: no clean-up).
; CHECK-COUNT qram_store: call void @cqrt_copy_i32( 1
; CHECK qram_store: call i32 @cq_template_sub_i32_hl(i32 %{{t}}, i32 3)
;
; C: int qram_store(unsigned x0, double th, int a) {
; C:   unsigned x = x0; cq_theta(&x, th);
; C:   int y = a; cq_theta(&y, th);
; C:   int arr[4] = {0, 0, 0, 0};
; C:   arr[x & 3] = y;
; C:   int r = arr[(x >> 2) & 3];
; C:   if (r == 2) cq_phi(0.5);
; C:   y = y + 3;
; C:   return cq_measure(y) + cq_measure(x);
; C: }
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @qram_store(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef %1)
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, i8 0, i64 16, i1 false)
  %7 = and i32 %5, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %8
  store i32 %6, ptr %9, align 4
  %10 = lshr i32 %5, 2
  %11 = and i32 %10, 3
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4
  %15 = icmp eq i32 %14, 2
  br i1 %15, label %16, label %17

16:                                               ; preds = %3
  tail call void @cq_phi(double noundef 5.000000e-01)
  br label %17

17:                                               ; preds = %16, %3
  %18 = add nsw i32 %6, 3
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18)
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %5)
  %21 = add i32 %20, %19
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  ret i32 %21
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

declare void @cq_phi(double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)



