; spec_intermediate_unc_user_helper.ll — ACCEPT, DISCHARGED (bd test_C_libtooling-p3kd.13).
; A lifted user helper's result consumed by another tainted op is uncomputed by
; its Bennett twin, LIFO, and freed — exactly as a `cq_template_*` intermediate is.
;
; SOURCE (`clang -O1` IR below, verbatim up to attribute groups and !tbaa):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     static const int tbl[8] = {3, 1, 4, 1, 5, 9, 2, 6};
;     int consumer(int m)   { int q = m & 7; cq_theta(&q, .5); int s = h(q) * 5;
;                             return cq_measure(s); }
;     int dephase(int m)    { ... int s = h(q) * 5; int r = cq_measure(s);
;                             cq_theta(&q, .3); return r + cq_measure(q); }
;     long widen(int m)     { ... long w = (long)h(q); return cq_measure(w); }
;     int fanout(int m)     { ... int p = h(q); int s1 = p * 5; int s2 = p ^ 3;
;                             return cq_measure(s1) + cq_measure(s2); }
;     int qram_index(int m) { ... int v = tbl[h(q) & 7]; return cq_measure(v); }
;
; WHAT main db4cf60a EMITTED for every function: `%r = __cq_q_h_1(%h)`, the
; consumer, the measure — and nothing else for `%r`. The clone's `cqq.out` rail is
; a basis record of q (3q+1 is injective), never uncomputed and never freed: stage
; 2b counts it "left dirty". In @dephase the chained `cq_theta(&q, .3)` then fires
; a non-diagonal gate over that live record — q dephased beyond what the program's
; own live record `s` implies, reported only by the M-A warning `non-diagonal gate
; over a live derived record` (opt exit 0). The hand-inlined twin (`s = (q*3+1)*5`)
; discharged its chain and warned nothing.
;
; NOW (CloneProducer.h): the clone result is an uncompute-spine PRODUCER. The M-B
; interior partition owns it, places `@__cq_q_h_1_unc(%r, %h)` (`out ^= h(x)`,
; the twin the 6.3 inner drain synthesizes) right after its last consumer, and
; frees `%r` — before the Ry in @dephase, so M-A has nothing to report (SILENT).
; Consumers covered here: arithmetic (@consumer), a cast (@widen), two forward
; consumers adjointed ONCE after both (@fanout, R7: the DAG's once-per-gate
; spine, not a bail), a QRAM index whose `and` rail is discharged first, LIFO
; (@qram_index), and a QRAM store's value chain (@store_value, source below). The twin is `fastcc` like the clone, and so is its CALL (a
; calling-convention mismatch is UB `opt -verify` does not flag).
;
; RETIREMENT TRIGGER (L7): if the twin is ever minted per call site rather than
; once per clone, the ONETWIN prefix below goes red first.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=TWIN < %t.ll
; RUN: %filecheck %s --check-prefix=ONETWIN < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define i32 @consumer(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H]])
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 5)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S]])

; CHECK-LABEL: define i32 @dephase(
; CHECK:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[R2:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H2]])
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R2]], i32 5)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R2]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R2]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S2]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H2]], double 3.000000e-01)

; CHECK-LABEL: define i64 @widen(
; CHECK:      %[[R3:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H3:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i32_to_i64(i32 %[[R3]])
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R3]], i32 %[[H3]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R3]])
; CHECK-NEXT: call i64 @cqrt_measure_i64(i32 %[[W]])

; CHECK-LABEL: define i32 @fanout(
; CHECK:      %[[R4:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H4:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call i32 @cq_template_mul_i32_hl(i32 %[[R4]], i32 5)
; CHECK-NEXT: call i32 @cq_template_xor_i32_hl(i32 %[[R4]], i32 3)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R4]], i32 %[[H4]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R4]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(
; CHECK-NOT:  @__cq_q_h_1_unc
; CHECK:      ret i32

; CHECK-LABEL: define i32 @qram_index(
; CHECK:      %[[R5:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H5:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: %[[I:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[R5]], i32 7)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[I]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[I]], i32 %[[R5]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[I]])
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R5]], i32 %[[H5]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R5]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[V]])

; @store_value — the clone chain feeds a QRAM STORE's value slot; the cell keeps a
; copy (the program's array), the chain `mul`, then the clone rail, are discharged
; LIFO right after the store, before the sources are rotated back.
; CHECK-LABEL: define i32 @store_value(
; CHECK:      %[[R6:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H6:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: %[[V6:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R6]], i32 5)
; CHECK-NEXT: %[[I6:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(
; CHECK-NEXT: call void @cqrt_qram_store_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[I6]], i32 %[[V6]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[V6]], i32 %[[R6]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[V6]])
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R6]], i32 %[[H6]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R6]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[H6]], double -5.000000e-01)

; The twin is the clone with its `out` alloc replaced by the parameter: recompute,
; XOR-copy into `out`, uncompute, free the scratch.
; TWIN-LABEL: define internal fastcc void @__cq_q_h_1_unc(i32 %out, i32 noundef %0)
; TWIN-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %0, i32 3)
; TWIN-NEXT:  %[[B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[A]], i32 1)
; TWIN-NEXT:  call void @cqrt_copy_i32(i32 %[[B]], i32 %out)
; TWIN-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[B]], i32 %[[A]], i32 1)
; TWIN-NEXT:  call void @cq_template_mul_i32_hl_unc(i32 %[[A]], i32 %0, i32 3)
; TWIN-NEXT:  call void @cqrt_free(i32 %[[A]])
; TWIN-NEXT:  call void @cqrt_free(i32 %[[B]])
; TWIN-NEXT:  ret void

; ONETWIN-COUNT-1: define {{.*}}@__cq_q_h_1_unc(
; ONETWIN-NOT:     define {{.*}}@__cq_q_h_1_unc(

@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 1, i32 5, i32 9, i32 2, i32 6], align 16

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare i64 @cq_measure_sl(i64 noundef)

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @consumer(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = mul nsw i32 %4, 5
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  ret i32 %6
}

define i32 @dephase(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = mul nsw i32 %4, 5
  %6 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  %9 = add nsw i32 %8, %6
  ret i32 %9
}

define i64 @widen(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = sext i32 %4 to i64
  %6 = tail call i64 @cq_measure_sl(i64 noundef %5)
  ret i64 %6
}

define i32 @fanout(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = mul nsw i32 %4, 5
  %6 = xor i32 %4, 3
  %7 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %8 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %9 = add nsw i32 %8, %7
  ret i32 %9
}

define i32 @qram_index(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = and i32 %4, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %6
  %8 = load i32, ptr %7, align 4
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8)
  ret i32 %9
}

; int store_value(int m) { int arr[8] = {0}; int q = 0; cq_theta(&q, 0.5);
;   int r = 1; cq_theta(&r, 0.5); arr[q & 7] = h(r) * 5;      /* a QRAM STORE */
;   int p = 4; cq_theta(&p, 0.5); int v = arr[p & 7];
;   cq_theta(&q, -0.5); cq_theta(&r, -0.5);
;   return cq_measure(q) + cq_measure(r) + cq_measure(v); }
define i32 @store_value(i32 noundef %0) {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #1
  %4 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #1
  %5 = tail call fastcc i32 @h(i32 noundef %4)
  %6 = mul nsw i32 %5, 5
  %7 = and i32 %3, 7
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %8
  store i32 %6, ptr %9, align 4
  %10 = tail call i32 @cq_theta_si32(i32 noundef 4, double noundef 5.000000e-01) #1
  %11 = and i32 %10, 7
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4
  %15 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #1
  %16 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #1
  %17 = tail call i32 @cq_measure_si32(i32 noundef %15)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %16)
  %19 = add nsw i32 %18, %17
  %20 = tail call i32 @cq_measure_si32(i32 noundef %14)
  %21 = add nsw i32 %19, %20
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2)
  ret i32 %21
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nomerge nounwind }
