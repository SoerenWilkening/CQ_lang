; cq-k65d: rule 22 into slot arrays through M6 (clang -O1 of the C below; each entry green under cqcheck user, 300
; samples): a quantum fill byte splatted into int cells, a run-time classical length under seed guards
; (the host copies exactly the length into a zeroed buffer), a QRAM source read by the byte engine.
; | /* a quantum fill byte into a slot array of ints that crosses to a clone */
; | static __attribute__((noinline)) int sum3(const int *a) { return a[0] ^ (a[1] + a[2]); }
; | int slot_qfill(int x, double th) {
; |     int a[3];
; |     cq_theta(&x, th);
; |     __builtin_memset(a, x, 12);
; |     return cq_measure(sum3(a));
; | }
; | /* a run-time classical length copied into a slot array */
; | int slot_rt_memcpy(int x, unsigned n, double th) {
; |     int a[4];
; |     int b[4] = {3, 4, 5, 6};
; |     cq_theta(&x, th);
; |     a[0] = x; a[1] = x + 1; a[2] = x + 2; a[3] = x + 3;
; |     __builtin_memcpy(a, b, (n & 3) * 4);
; |     return cq_measure(a[0] + a[1] + a[2] + a[3]);
; | }
; | /* a QRAM source copied into a slot array */
; | int slot_from_qram(int x, double th) {
; |     int q[4] = {1, 2, 3, 4};
; |     int s[2];
; |     cq_theta(&x, th);
; |     q[x & 3] = x;
; |     s[0] = x;
; |     __builtin_memcpy(s, q + 1, 8);
; |     return cq_measure(s[0] * 3 + s[1]);
; | }

; Function Attrs: nounwind ssp uwtable
define i32 @slot_qfill(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = alloca [3 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %3)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %5 = trunc i32 %4 to i8
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(12) %3, i8 %5, i64 12, i1 false)
  %6 = call fastcc i32 @sum3(ptr noundef nonnull %3)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %3)
  ret i32 %7
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)


; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)


; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal fastcc i32 @sum3(ptr nocapture noundef readonly %0) unnamed_addr {
  %2 = load i32, ptr %0, align 4
  %3 = getelementptr inbounds i8, ptr %0, i64 4
  %4 = load i32, ptr %3, align 4
  %5 = getelementptr inbounds i8, ptr %0, i64 8
  %6 = load i32, ptr %5, align 4
  %7 = add nsw i32 %6, %4
  %8 = xor i32 %7, %2
  ret i32 %8
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)




@__const.slot_rt_memcpy.b = private unnamed_addr constant [4 x i32] [i32 3, i32 4, i32 5, i32 6], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @slot_rt_memcpy(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr {
  %4 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2)
  store i32 %5, ptr %4, align 16
  %6 = add nsw i32 %5, 1
  %7 = getelementptr inbounds i8, ptr %4, i64 4
  store i32 %6, ptr %7, align 4
  %8 = add nsw i32 %5, 2
  %9 = getelementptr inbounds i8, ptr %4, i64 8
  store i32 %8, ptr %9, align 8
  %10 = add nsw i32 %5, 3
  %11 = getelementptr inbounds i8, ptr %4, i64 12
  store i32 %10, ptr %11, align 4
  %12 = shl i32 %1, 2
  %13 = and i32 %12, 12
  %14 = zext nneg i32 %13 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 16 %4, ptr nonnull align 16 @__const.slot_rt_memcpy.b, i64 %14, i1 false)
  %15 = load i32, ptr %4, align 16
  %16 = getelementptr inbounds i8, ptr %4, i64 4
  %17 = load i32, ptr %16, align 4
  %18 = add nsw i32 %17, %15
  %19 = getelementptr inbounds i8, ptr %4, i64 8
  %20 = load i32, ptr %19, align 8
  %21 = add nsw i32 %18, %20
  %22 = getelementptr inbounds i8, ptr %4, i64 12
  %23 = load i32, ptr %22, align 4
  %24 = add nsw i32 %21, %23
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  ret i32 %25
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)



; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)




@__const.slot_from_qram.q = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @slot_from_qram(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %3, ptr noundef nonnull align 16 dereferenceable(16) @__const.slot_from_qram.q, i64 16, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %5 = and i32 %4, 3
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [4 x i32], ptr %3, i64 0, i64 %6
  store i32 %4, ptr %7, align 4
  %8 = getelementptr inbounds i8, ptr %3, i64 4
  %9 = load i32, ptr %8, align 4
  %10 = getelementptr inbounds i8, ptr %3, i64 8
  %11 = load i32, ptr %10, align 8
  %12 = mul nsw i32 %9, 3
  %13 = add nsw i32 %12, %11
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3)
  ret i32 %14
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)



; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)



declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr
declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
; CHECK slot_qfill: call i32 @cq_template_mul_i32_hl(i32 %{{z}}, i32 16843009)
; CHECK-COUNT slot_rt_memcpy: @cqrt_alloc_i1( 3
; CHECK slot_from_qram: call i32 @cqrt_qram_load_i32_hl(i32 %{{a}}, i32 1)
