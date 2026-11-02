; cq-k65d: the QRAM byte engine and rule 22 (clang -O1 of the C below; green under cqcheck user, every entry,
; 300 samples): a byte of an int cell, an 8-byte store over two cells at a quantum index, a run-time
; length under classical guards, a quantum length under rule 22's guards, a quantum fill byte splatted into
; int cells.
; | 
; | /* a byte of an int QRAM at a classical offset: a read of part of a cell */
; | int qram_byte_view(int x, int v, double th) {
; |     int a[4] = {0x11223344, 0x55667788, 0x0a0b0c0d, 0x01020304};
; |     cq_theta(&x, th);
; |     a[x & 3] = v;
; |     unsigned char b;
; |     __builtin_memcpy(&b, (char *)a + 5, 1);
; |     return cq_measure((int)b + a[1]);
; | }
; | /* an 8-byte store at a quantum index into an int QRAM: two cells per store */
; | int qram_wide_store(int x, long long w, double th) {
; |     int a[8] = {1, 2, 3, 4, 5, 6, 7, 8};
; |     cq_theta(&x, th);
; |     __builtin_memcpy(&a[2 * (x & 3)], &w, 8);
; |     return cq_measure(a[5] ^ a[2]);
; | }
; | /* a run-time classical length into a QRAM: rule 22's classical loop over the cells (f684858), each cell
; |    under its classical guard, the reverse loop popping them */
; | int qram_rt_memset(int x, int c, unsigned n, double th) {
; |     unsigned char buf[16];
; |     __builtin_memset(buf, 1, 16);
; |     cq_theta(&x, th);
; |     buf[x & 15] = 9;
; |     __builtin_memset(buf, c, n & 15);
; |     return cq_measure(buf[3] + 3 * buf[x & 7]);
; | }
; | /* a quantum length (rule 22's guarded cells) into a QRAM */
; | int qram_q_memcpy(int x, int y, double th) {
; |     unsigned char a[8] = {0};
; |     static const unsigned char src[8] = {9, 8, 7, 6, 5, 4, 3, 2};
; |     cq_theta(&x, th);
; |     cq_theta(&y, th);
; |     a[y & 7] = 1;
; |     __builtin_memcpy(a, src, (unsigned)x & 7);
; |     return cq_measure(a[2] + 2 * a[5] + 4 * a[y & 7]);
; | }
; | /* a quantum fill byte into int cells */
; | int qram_q_fill(int x, int y, double th) {
; |     int a[4] = {5, 6, 7, 8};
; |     cq_theta(&x, th);
; |     cq_theta(&y, th);
; |     a[y & 3] = 0;
; |     __builtin_memset(a, x, 8);
; |     return cq_measure(a[0] + a[1] + a[2] + a[y & 3]);
; | }

@__const.qram_byte_view.a = private unnamed_addr constant [4 x i32] [i32 287454020, i32 1432778632, i32 168496141, i32 16909060], align 16
@__const.qram_wide_store.a = private unnamed_addr constant [8 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8], align 16
@qram_q_memcpy.src = internal unnamed_addr constant [8 x i8] c"\09\08\07\06\05\04\03\02", align 1
@__const.qram_q_fill.a = private unnamed_addr constant [4 x i32] [i32 5, i32 6, i32 7, i32 8], align 16

; Function Attrs: nounwind ssp uwtable
define i32 @qram_byte_view(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr {
  %4 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) @__const.qram_byte_view.a, i64 16, i1 false)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2)
  %6 = and i32 %5, 3
  %7 = zext nneg i32 %6 to i64
  %8 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %7
  store i32 %1, ptr %8, align 4
  %9 = getelementptr inbounds i8, ptr %4, i64 5
  %10 = load i8, ptr %9, align 1
  %11 = zext i8 %10 to i32
  %12 = getelementptr inbounds i8, ptr %4, i64 4
  %13 = load i32, ptr %12, align 4
  %14 = add nsw i32 %13, %11
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  ret i32 %15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg)

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)

; Function Attrs: nounwind ssp uwtable
define i32 @qram_wide_store(i32 noundef %0, i64 noundef %1, double noundef %2) local_unnamed_addr {
  %4 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %4, ptr noundef nonnull align 16 dereferenceable(32) @__const.qram_wide_store.a, i64 32, i1 false)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2)
  %6 = shl i32 %5, 1
  %7 = and i32 %6, 6
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %8
  store i64 %1, ptr %9, align 8
  %10 = getelementptr inbounds i8, ptr %4, i64 20
  %11 = load i32, ptr %10, align 4
  %12 = getelementptr inbounds i8, ptr %4, i64 8
  %13 = load i32, ptr %12, align 8
  %14 = xor i32 %13, %11
  %15 = tail call i32 @cq_measure_si32(i32 noundef %14)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4)
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @qram_rt_memset(i32 noundef %0, i32 noundef %1, i32 noundef %2, double noundef %3) local_unnamed_addr {
  %5 = alloca [16 x i8], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %5)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %5, i8 1, i64 16, i1 false)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %3)
  %7 = and i32 %6, 15
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [16 x i8], ptr %5, i64 0, i64 %8
  store i8 9, ptr %9, align 1
  %10 = trunc i32 %1 to i8
  %11 = and i32 %2, 15
  %12 = zext nneg i32 %11 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %5, i8 %10, i64 %12, i1 false)
  %13 = getelementptr inbounds i8, ptr %5, i64 3
  %14 = load i8, ptr %13, align 1
  %15 = zext i8 %14 to i32
  %16 = and i32 %6, 7
  %17 = zext nneg i32 %16 to i64
  %18 = getelementptr inbounds [16 x i8], ptr %5, i64 0, i64 %17
  %19 = load i8, ptr %18, align 1
  %20 = zext i8 %19 to i32
  %21 = mul nuw nsw i32 %20, 3
  %22 = add nuw nsw i32 %21, %15
  %23 = tail call i32 @cq_measure_si32(i32 noundef %22)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %5)
  ret i32 %23
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

; Function Attrs: nounwind ssp uwtable
define i32 @qram_q_memcpy(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr {
  %4 = alloca [8 x i8], align 8
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4)
  store i64 0, ptr %4, align 8
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2)
  %7 = and i32 %6, 7
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [8 x i8], ptr %4, i64 0, i64 %8
  store i8 1, ptr %9, align 1
  %10 = and i32 %5, 7
  %11 = zext nneg i32 %10 to i64
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 %4, ptr nonnull align 1 @qram_q_memcpy.src, i64 %11, i1 false)
  %12 = getelementptr inbounds i8, ptr %4, i64 2
  %13 = load i8, ptr %12, align 2
  %14 = zext i8 %13 to i32
  %15 = getelementptr inbounds i8, ptr %4, i64 5
  %16 = load i8, ptr %15, align 1
  %17 = zext i8 %16 to i32
  %18 = shl nuw nsw i32 %17, 1
  %19 = add nuw nsw i32 %18, %14
  %20 = load i8, ptr %9, align 1
  %21 = zext i8 %20 to i32
  %22 = shl nuw nsw i32 %21, 2
  %23 = add nuw nsw i32 %19, %22
  %24 = tail call i32 @cq_measure_si32(i32 noundef %23)
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4)
  ret i32 %24
}

; Function Attrs: nounwind ssp uwtable
define i32 @qram_q_fill(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr {
  %4 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4)
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 16 dereferenceable(16) %4, ptr noundef nonnull align 16 dereferenceable(16) @__const.qram_q_fill.a, i64 16, i1 false)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef %2)
  %7 = and i32 %6, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %8
  store i32 0, ptr %9, align 4
  %10 = trunc i32 %5 to i8
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(8) %4, i8 %10, i64 8, i1 false)
  %11 = load i32, ptr %4, align 16
  %12 = getelementptr inbounds i8, ptr %4, i64 4
  %13 = load i32, ptr %12, align 4
  %14 = add nsw i32 %13, %11
  %15 = getelementptr inbounds i8, ptr %4, i64 8
  %16 = load i32, ptr %15, align 8
  %17 = add nsw i32 %14, %16
  %18 = load i32, ptr %9, align 4
  %19 = add nsw i32 %17, %18
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19)
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4)
  ret i32 %20
}



; CHECK qram_byte_view: call i32 @cqrt_qram_load_i32_hl(i32 %{{a}}, i32 1)
; CHECK qram_byte_view: call i32 @cq_template_lshr_i32_hl(i32 %{{c}}, i32 8)
; CHECK qram_byte_view: call i32 @cq_template_trunc_i32_to_i8(
; CHECK qram_wide_store: call i32 @cq_template_add_i32_hl(i32 %{{i}}, i32 1)
; CHECK-COUNT qram_wide_store: call void @cqrt_qram_store_i32(i32 2
; CHECK-COUNT qram_rt_memset: call void @cqrt_qram_store_i8_hl_controlled( 1
; CHECK-COUNT qram_rt_memset: call void @cqrt_qram_store_i8_hl_controlled_unc( 1
; CHECK-COUNT qram_q_memcpy: call i32 @cq_template_icmp_ugt_i32_hl( 7
; CHECK qram_q_fill: call i32 @cq_template_mul_i32_hl(i32 %{{z}}, i32 16843009)
