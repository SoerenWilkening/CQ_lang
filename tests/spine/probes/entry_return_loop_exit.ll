; CR rules 14, 18, 19: an entry returning the exit value of a rolled quantum-exit loop returns a copy; the reverse still runs (memcmp, own symbol).
; CHECK mc: cqrt_copy_i32
; ModuleID = 'pr/m1.c'
source_filename = "pr/m1.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define noundef i32 @sweep_m1(i8 noundef zeroext %0, i8 noundef zeroext %1) local_unnamed_addr {
  %3 = alloca [8 x i8], align 16
  %4 = alloca [8 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %3)
  store i64 67305984, ptr %3, align 16
  store i8 %0, ptr %3, align 16
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4)
  store i64 84083200, ptr %4, align 16
  store i8 %1, ptr %4, align 16
  %5 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef 3.000000e-01)
  store i8 %5, ptr %3, align 16
  %6 = call fastcc i32 @mc(ptr noundef nonnull %3, ptr noundef nonnull %4)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %3)
  ret i32 0
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(read, inaccessiblemem: none) uwtable
define internal fastcc range(i32 -255, 256) i32 @mc(ptr nocapture noundef readonly %0, ptr nocapture noundef readonly %1) unnamed_addr {
  br label %3

3:                                                ; preds = %2, %10
  %4 = phi ptr [ %1, %2 ], [ %13, %10 ]
  %5 = phi ptr [ %0, %2 ], [ %12, %10 ]
  %6 = phi i64 [ 8, %2 ], [ %11, %10 ]
  %7 = load i8, ptr %5, align 1
  %8 = load i8, ptr %4, align 1
  %9 = icmp eq i8 %7, %8
  br i1 %9, label %10, label %15

10:                                               ; preds = %3
  %11 = add nsw i64 %6, -1
  %12 = getelementptr inbounds i8, ptr %5, i64 1
  %13 = getelementptr inbounds i8, ptr %4, i64 1
  %14 = icmp eq i64 %11, 0
  br i1 %14, label %19, label %3

15:                                               ; preds = %3
  %16 = zext i8 %7 to i32
  %17 = zext i8 %8 to i32
  %18 = sub nsw i32 %16, %17
  br label %19

19:                                               ; preds = %10, %15
  %20 = phi i32 [ %18, %15 ], [ 0, %10 ]
  ret i32 %20
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)



