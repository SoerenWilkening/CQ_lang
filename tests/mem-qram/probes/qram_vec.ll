; cq-k65d: green under cqcheck user (300 samples). C source:
; | #include <stdlib.h>
; | typedef int v4 __attribute__((vector_size(16)));
; | static char small[2];
; | static _Thread_local int tl[4];
; | /* a QRAM of vectors */
; | int qram_vec(int x, double th) {
; |     v4 a[2] = {{1, 2, 3, 4}, {5, 6, 7, 8}};
; |     cq_theta(&x, th);
; |     a[x & 1][2] = x;
; |     v4 s = a[0] + a[1];
; |     return cq_measure(s[0] + s[2] + a[x & 1][3]);
; | }

@__const.qram_vec.a = private unnamed_addr constant [2 x <4 x i32>] [<4 x i32> <i32 1, i32 2, i32 3, i32 4>, <4 x i32> <i32 5, i32 6, i32 7, i32 8>], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @qram_vec(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = alloca [2 x <4 x i32>], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %3)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, ptr noundef nonnull align 16 dereferenceable(32) @__const.qram_vec.a, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %5 = and i32 %4, 1
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [2 x <4 x i32>], ptr %3, i64 0, i64 %6
  %8 = load <4 x i32>, ptr %7, align 16
  %9 = getelementptr inbounds i8, ptr %7, i64 8
  store i32 %4, ptr %9, align 8
  %10 = load <4 x i32>, ptr %3, align 16
  %11 = getelementptr inbounds i8, ptr %3, i64 16
  %12 = load <4 x i32>, ptr %11, align 16
  %13 = add <4 x i32> %12, %10
  %14 = shufflevector <4 x i32> %8, <4 x i32> poison, <4 x i32> <i32 poison, i32 poison, i32 3, i32 poison>
  %15 = add <4 x i32> %13, %14
  %16 = shufflevector <4 x i32> %15, <4 x i32> poison, <4 x i32> <i32 2, i32 poison, i32 poison, i32 poison>
  %17 = add <4 x i32> %16, %13
  %18 = extractelement <4 x i32> %17, i64 0
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %3)
  ret i32 %19
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)



; CHECK qram_vec: cqrt_qram_
