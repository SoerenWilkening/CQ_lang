; railwindow_accept_initializers.ll — ACCEPT (bd 01po.19 S4, design addendum
; notes 1-2): whole-object initializers AFTER the quantization point.
; Contract: RailWindow.h (bd `test_C_libtooling-01po.19` S4; owner rulings
; `owner-ruling-01po19-rolled-not-unrolled-2026-10-15`,
; `owner-ruling-01po19-rolled-design-2026-10-15`, Q1/Q3/Q4 (a)).
; Analytic reading per function:
;   @full        memset(q,1) after the walk: four rebinds to fresh |1> rails.
;   @partial     memset(q,0,2): cells 0,1 rebound to |0>, cells 2,3 keep their
;                rotated rails.
;   @runtime_len a runtime-length memset: a guarded rolled rebind walk over
;                cells [0, n&3); the rest keep their rails.
;   @chars       `signed char q[3] = {5,6,7}`: a constant-global memcpy BEFORE Q
;                is classical; the rails are i8 (alloc_i8(5/6/7)), rotated twice.
; Traced: main's four calls give exactly that stream.
;
; SOURCE (clang -O1, verbatim below):
;   #include <string.h>
;   /* bd 01po.19 S4 addendum notes 1-2: whole-object initializers AFTER the quantization
;      point are per-cell rebinds. */
;   int full(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3 + .1 * i);
;     memset(q, 1, sizeof q);              /* every cell rebound to |1> */
;     int r = 0;
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int partial(void) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3 + .1 * i);
;     memset(q, 0, 2);                     /* cells 0,1 rebound to |0>, 2,3 kept */
;     int r = 0;
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int runtime_len(int n) {
;     bool q[4] = {0};
;     for (int i = 0; i < 4; i++) cq_theta(&q[i], .3 + .1 * i);
;     __builtin_memset(q, 0, n & 3);               /* cells [0, n&3) rebound */
;     int r = 0;
;     for (int i = 0; i < 4; i++) r = 2 * r + cq_measure(q[i]);
;     return r;
;   }
;   int chars(void) {
;     signed char q[3] = {5, 6, 7};        /* not _Bool: the rail is i8 */
;     for (int i = 0; i < 3; i++) cq_theta(&q[i], .5);
;     for (int i = 0; i < 3; i++) cq_theta(&q[i], .25);
;     int r = 0;
;     for (int i = 0; i < 3; i++) r += cq_measure(q[i]);
;     return r;
;   }
;   int main(void) { return full() + partial() + runtime_len(3) + chars(); }
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --check-prefix=S4 --implicit-check-not='error:' --implicit-check-not=cqrt_free
; S4-LABEL: define {{.*}} @full(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %3)
; S4: %h6 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %h5 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %h4 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %h3 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double %14)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail2)
; S4-LABEL: define {{.*}} @partial(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %3)
; S4: %h4 = call i32 @cqrt_alloc_i1(i1 false)
; S4: %h3 = call i32 @cqrt_alloc_i1(i1 false)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double %12)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail2)
; S4-LABEL: define {{.*}} @runtime_len(
; S4: %.rails = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %h = call i32 @cqrt_alloc_i1(i1 %4)
; S4: %h5 = call i32 @cqrt_alloc_i1(i1 false)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail, double %18)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail2)
; S4-LABEL: define {{.*}} @chars(
; S4: %.rails = alloca i32, i64 3, align 4, !cq.railwindow !15
; S4: %h = call i32 @cqrt_alloc_i8(i8 %cq.rail.init)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i8(i32 %.rail, double 5.000000e-01)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: call void @cqrt_ry_i8(i32 %.rail2, double 2.500000e-01)
; S4: store i32 %.rail2, ptr %cq.rail.addr1, align 4
; S4: %.rail4 = load i32, ptr %cq.rail.addr3, align 4
; S4: %m = call i8 @cqrt_measure_i8(i32 %.rail4)
; S4-LABEL: define {{.*}} @main(
; S4: %.rails23 = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %.rails15 = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %.rails5 = alloca i32, i64 4, align 4, !cq.railwindow !6
; S4: %.rails = alloca i32, i64 3, align 4, !cq.railwindow !15
; S4: %h = call i32 @cqrt_alloc_i1(i1 %6)
; S4: %h34 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %h33 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %h32 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %h31 = call i32 @cqrt_alloc_i1(i1 true)
; S4: %.rail25 = load i32, ptr %cq.rail.addr24, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail25, double %17)
; S4: store i32 %.rail25, ptr %cq.rail.addr24, align 4
; S4: %.rail27 = load i32, ptr %cq.rail.addr26, align 4
; S4: %m = call i1 @cqrt_measure_i1(i32 %.rail27)
; S4: %h35 = call i32 @cqrt_alloc_i1(i1 %30)
; S4: %h37 = call i32 @cqrt_alloc_i1(i1 false)
; S4: %h36 = call i32 @cqrt_alloc_i1(i1 false)
; S4: %.rail17 = load i32, ptr %cq.rail.addr16, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail17, double %39)
; S4: store i32 %.rail17, ptr %cq.rail.addr16, align 4
; S4: %.rail19 = load i32, ptr %cq.rail.addr18, align 4
; S4: %m41 = call i1 @cqrt_measure_i1(i32 %.rail19)
; S4: %h38 = call i32 @cqrt_alloc_i1(i1 %52)
; S4: %h39 = call i32 @cqrt_alloc_i1(i1 false)
; S4: %.rail7 = load i32, ptr %cq.rail.addr6, align 4
; S4: call void @cqrt_ry_i1(i32 %.rail7, double %62)
; S4: store i32 %.rail7, ptr %cq.rail.addr6, align 4
; S4: %.rail9 = load i32, ptr %cq.rail.addr8, align 4
; S4: %m42 = call i1 @cqrt_measure_i1(i32 %.rail9)
; S4: %h40 = call i32 @cqrt_alloc_i8(i8 %cq.rail.init)
; S4: %.rail = load i32, ptr %cq.rail.addr, align 4
; S4: call void @cqrt_ry_i8(i32 %.rail, double 5.000000e-01)
; S4: store i32 %.rail, ptr %cq.rail.addr, align 4
; S4: %.rail2 = load i32, ptr %cq.rail.addr1, align 4
; S4: call void @cqrt_ry_i8(i32 %.rail2, double 2.500000e-01)
; S4: store i32 %.rail2, ptr %cq.rail.addr1, align 4
; S4: %.rail4 = load i32, ptr %cq.rail.addr3, align 4
; S4: %m43 = call i8 @cqrt_measure_i8(i32 %.rail4)

; ModuleID = 'inits.c'
source_filename = "inits.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.chars.q = private unnamed_addr constant [3 x i8] c"\05\06\07", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @full() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  store i32 0, ptr %1, align 4
  br label %3

2:                                                ; preds = %3
  store i32 16843009, ptr %1, align 4
  br label %16

3:                                                ; preds = %0, %3
  %4 = phi i64 [ 0, %0 ], [ %13, %3 ]
  %5 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %4
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = trunc nuw i8 %6 to i1
  %8 = trunc nuw nsw i64 %4 to i32
  %9 = uitofp nneg i32 %8 to double
  %10 = tail call double @llvm.fmuladd.f64(double %9, double 1.000000e-01, double 3.000000e-01)
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef %10) #7
  %12 = zext i1 %11 to i8
  store i8 %12, ptr %5, align 1, !tbaa !6
  %13 = add nuw nsw i64 %4, 1
  %14 = icmp eq i64 %13, 4
  br i1 %14, label %2, label %3, !llvm.loop !12

15:                                               ; preds = %16
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 %25

16:                                               ; preds = %2, %16
  %17 = phi i64 [ 0, %2 ], [ %26, %16 ]
  %18 = phi i32 [ 0, %2 ], [ %25, %16 ]
  %19 = shl nsw i32 %18, 1
  %20 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %17
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = trunc nuw i8 %21 to i1
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %22) #6
  %24 = zext i1 %23 to i32
  %25 = or disjoint i32 %19, %24
  %26 = add nuw nsw i64 %17, 1
  %27 = icmp eq i64 %26, 4
  br i1 %27, label %15, label %16, !llvm.loop !15
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #2

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #4

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @partial() local_unnamed_addr #0 {
  %1 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %1) #6
  store i32 0, ptr %1, align 4
  br label %3

2:                                                ; preds = %3
  store i16 0, ptr %1, align 4
  br label %16

3:                                                ; preds = %0, %3
  %4 = phi i64 [ 0, %0 ], [ %13, %3 ]
  %5 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %4
  %6 = load i8, ptr %5, align 1, !tbaa !6, !range !10, !noundef !11
  %7 = trunc nuw i8 %6 to i1
  %8 = trunc nuw nsw i64 %4 to i32
  %9 = uitofp nneg i32 %8 to double
  %10 = tail call double @llvm.fmuladd.f64(double %9, double 1.000000e-01, double 3.000000e-01)
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %7, double noundef %10) #7
  %12 = zext i1 %11 to i8
  store i8 %12, ptr %5, align 1, !tbaa !6
  %13 = add nuw nsw i64 %4, 1
  %14 = icmp eq i64 %13, 4
  br i1 %14, label %2, label %3, !llvm.loop !16

15:                                               ; preds = %16
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %1) #6
  ret i32 %25

16:                                               ; preds = %2, %16
  %17 = phi i64 [ 0, %2 ], [ %26, %16 ]
  %18 = phi i32 [ 0, %2 ], [ %25, %16 ]
  %19 = shl nsw i32 %18, 1
  %20 = getelementptr inbounds [4 x i8], ptr %1, i64 0, i64 %17
  %21 = load i8, ptr %20, align 1, !tbaa !6, !range !10, !noundef !11
  %22 = trunc nuw i8 %21 to i1
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %22) #6
  %24 = zext i1 %23 to i32
  %25 = or disjoint i32 %19, %24
  %26 = add nuw nsw i64 %17, 1
  %27 = icmp eq i64 %26, 4
  br i1 %27, label %15, label %16, !llvm.loop !17
}

; Function Attrs: nounwind ssp uwtable
define i32 @runtime_len(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #6
  store i32 0, ptr %2, align 4
  br label %6

3:                                                ; preds = %6
  %4 = and i32 %0, 3
  %5 = zext nneg i32 %4 to i64
  call void @llvm.memset.p0.i64(ptr nonnull align 4 %2, i8 0, i64 %5, i1 false)
  br label %19

6:                                                ; preds = %1, %6
  %7 = phi i64 [ 0, %1 ], [ %16, %6 ]
  %8 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %7
  %9 = load i8, ptr %8, align 1, !tbaa !6, !range !10, !noundef !11
  %10 = trunc nuw i8 %9 to i1
  %11 = trunc nuw nsw i64 %7 to i32
  %12 = uitofp nneg i32 %11 to double
  %13 = tail call double @llvm.fmuladd.f64(double %12, double 1.000000e-01, double 3.000000e-01)
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %10, double noundef %13) #7
  %15 = zext i1 %14 to i8
  store i8 %15, ptr %8, align 1, !tbaa !6
  %16 = add nuw nsw i64 %7, 1
  %17 = icmp eq i64 %16, 4
  br i1 %17, label %3, label %6, !llvm.loop !18

18:                                               ; preds = %19
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #6
  ret i32 %28

19:                                               ; preds = %3, %19
  %20 = phi i64 [ 0, %3 ], [ %29, %19 ]
  %21 = phi i32 [ 0, %3 ], [ %28, %19 ]
  %22 = shl nsw i32 %21, 1
  %23 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %20
  %24 = load i8, ptr %23, align 1, !tbaa !6, !range !10, !noundef !11
  %25 = trunc nuw i8 %24 to i1
  %26 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %25) #6
  %27 = zext i1 %26 to i32
  %28 = or disjoint i32 %22, %27
  %29 = add nuw nsw i64 %20, 1
  %30 = icmp eq i64 %29, 4
  br i1 %30, label %18, label %19, !llvm.loop !19
}

; Function Attrs: nounwind ssp uwtable
define i32 @chars() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #6
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, ptr noundef nonnull align 1 dereferenceable(3) @__const.chars.q, i64 3, i1 false)
  br label %2

2:                                                ; preds = %0, %2
  %3 = phi i64 [ 0, %0 ], [ %7, %2 ]
  %4 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %3
  %5 = load i8, ptr %4, align 1, !tbaa !20
  %6 = tail call signext i8 @cq_theta_si8(i8 noundef signext %5, double noundef 5.000000e-01) #7
  store i8 %6, ptr %4, align 1, !tbaa !20
  %7 = add nuw nsw i64 %3, 1
  %8 = icmp eq i64 %7, 3
  br i1 %8, label %9, label %2, !llvm.loop !21

9:                                                ; preds = %2, %9
  %10 = phi i64 [ %14, %9 ], [ 0, %2 ]
  %11 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %10
  %12 = load i8, ptr %11, align 1, !tbaa !20
  %13 = tail call signext i8 @cq_theta_si8(i8 noundef signext %12, double noundef 2.500000e-01) #7
  store i8 %13, ptr %11, align 1, !tbaa !20
  %14 = add nuw nsw i64 %10, 1
  %15 = icmp eq i64 %14, 3
  br i1 %15, label %17, label %9, !llvm.loop !22

16:                                               ; preds = %17
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #6
  ret i32 %24

17:                                               ; preds = %9, %17
  %18 = phi i64 [ %25, %17 ], [ 0, %9 ]
  %19 = phi i32 [ %24, %17 ], [ 0, %9 ]
  %20 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %18
  %21 = load i8, ptr %20, align 1, !tbaa !20
  %22 = tail call signext i8 @cq_measure_si8(i8 noundef signext %21) #6
  %23 = sext i8 %22 to i32
  %24 = add nsw i32 %19, %23
  %25 = add nuw nsw i64 %18, 1
  %26 = icmp eq i64 %25, 3
  br i1 %26, label %16, label %17, !llvm.loop !23
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #5

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #3

declare signext i8 @cq_measure_si8(i8 noundef signext) local_unnamed_addr #3

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 {
  %1 = alloca [3 x i8], align 1
  %2 = alloca [4 x i8], align 4
  %3 = alloca [4 x i8], align 4
  %4 = alloca [4 x i8], align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #6
  store i32 0, ptr %4, align 4
  br label %6

5:                                                ; preds = %6
  store i32 16843009, ptr %4, align 4
  br label %18

6:                                                ; preds = %6, %0
  %7 = phi i64 [ 0, %0 ], [ %16, %6 ]
  %8 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %7
  %9 = load i8, ptr %8, align 1, !tbaa !6, !range !10, !noundef !11
  %10 = trunc nuw i8 %9 to i1
  %11 = trunc nuw nsw i64 %7 to i32
  %12 = uitofp nneg i32 %11 to double
  %13 = tail call double @llvm.fmuladd.f64(double %12, double 1.000000e-01, double 3.000000e-01)
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %10, double noundef %13) #7
  %15 = zext i1 %14 to i8
  store i8 %15, ptr %8, align 1, !tbaa !6
  %16 = add nuw nsw i64 %7, 1
  %17 = icmp eq i64 %16, 4
  br i1 %17, label %5, label %6, !llvm.loop !12

18:                                               ; preds = %18, %5
  %19 = phi i64 [ 0, %5 ], [ %28, %18 ]
  %20 = phi i32 [ 0, %5 ], [ %27, %18 ]
  %21 = shl nsw i32 %20, 1
  %22 = getelementptr inbounds [4 x i8], ptr %4, i64 0, i64 %19
  %23 = load i8, ptr %22, align 1, !tbaa !6, !range !10, !noundef !11
  %24 = trunc nuw i8 %23 to i1
  %25 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %24) #6
  %26 = zext i1 %25 to i32
  %27 = or disjoint i32 %21, %26
  %28 = add nuw nsw i64 %19, 1
  %29 = icmp eq i64 %28, 4
  br i1 %29, label %30, label %18, !llvm.loop !15

30:                                               ; preds = %18
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #6
  store i32 0, ptr %3, align 4
  br label %32

31:                                               ; preds = %32
  store i16 0, ptr %3, align 4
  br label %44

32:                                               ; preds = %32, %30
  %33 = phi i64 [ 0, %30 ], [ %42, %32 ]
  %34 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %33
  %35 = load i8, ptr %34, align 1, !tbaa !6, !range !10, !noundef !11
  %36 = trunc nuw i8 %35 to i1
  %37 = trunc nuw nsw i64 %33 to i32
  %38 = uitofp nneg i32 %37 to double
  %39 = tail call double @llvm.fmuladd.f64(double %38, double 1.000000e-01, double 3.000000e-01)
  %40 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %36, double noundef %39) #7
  %41 = zext i1 %40 to i8
  store i8 %41, ptr %34, align 1, !tbaa !6
  %42 = add nuw nsw i64 %33, 1
  %43 = icmp eq i64 %42, 4
  br i1 %43, label %31, label %32, !llvm.loop !16

44:                                               ; preds = %44, %31
  %45 = phi i64 [ 0, %31 ], [ %54, %44 ]
  %46 = phi i32 [ 0, %31 ], [ %53, %44 ]
  %47 = shl nsw i32 %46, 1
  %48 = getelementptr inbounds [4 x i8], ptr %3, i64 0, i64 %45
  %49 = load i8, ptr %48, align 1, !tbaa !6, !range !10, !noundef !11
  %50 = trunc nuw i8 %49 to i1
  %51 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %50) #6
  %52 = zext i1 %51 to i32
  %53 = or disjoint i32 %47, %52
  %54 = add nuw nsw i64 %45, 1
  %55 = icmp eq i64 %54, 4
  br i1 %55, label %56, label %44, !llvm.loop !17

56:                                               ; preds = %44
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #6
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #6
  store i32 0, ptr %2, align 4
  br label %58

57:                                               ; preds = %58
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 4 dereferenceable(3) %2, i8 0, i64 3, i1 false)
  br label %70

58:                                               ; preds = %58, %56
  %59 = phi i64 [ 0, %56 ], [ %68, %58 ]
  %60 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %59
  %61 = load i8, ptr %60, align 1, !tbaa !6, !range !10, !noundef !11
  %62 = trunc nuw i8 %61 to i1
  %63 = trunc nuw nsw i64 %59 to i32
  %64 = uitofp nneg i32 %63 to double
  %65 = tail call double @llvm.fmuladd.f64(double %64, double 1.000000e-01, double 3.000000e-01)
  %66 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %62, double noundef %65) #7
  %67 = zext i1 %66 to i8
  store i8 %67, ptr %60, align 1, !tbaa !6
  %68 = add nuw nsw i64 %59, 1
  %69 = icmp eq i64 %68, 4
  br i1 %69, label %57, label %58, !llvm.loop !18

70:                                               ; preds = %70, %57
  %71 = phi i64 [ 0, %57 ], [ %80, %70 ]
  %72 = phi i32 [ 0, %57 ], [ %79, %70 ]
  %73 = shl nsw i32 %72, 1
  %74 = getelementptr inbounds [4 x i8], ptr %2, i64 0, i64 %71
  %75 = load i8, ptr %74, align 1, !tbaa !6, !range !10, !noundef !11
  %76 = trunc nuw i8 %75 to i1
  %77 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %76) #6
  %78 = zext i1 %77 to i32
  %79 = or disjoint i32 %73, %78
  %80 = add nuw nsw i64 %71, 1
  %81 = icmp eq i64 %80, 4
  br i1 %81, label %82, label %70, !llvm.loop !19

82:                                               ; preds = %70
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #6
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %1) #6
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 1 dereferenceable(3) %1, ptr noundef nonnull align 1 dereferenceable(3) @__const.chars.q, i64 3, i1 false)
  br label %83

83:                                               ; preds = %83, %82
  %84 = phi i64 [ 0, %82 ], [ %88, %83 ]
  %85 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %84
  %86 = load i8, ptr %85, align 1, !tbaa !20
  %87 = tail call signext i8 @cq_theta_si8(i8 noundef signext %86, double noundef 5.000000e-01) #7
  store i8 %87, ptr %85, align 1, !tbaa !20
  %88 = add nuw nsw i64 %84, 1
  %89 = icmp eq i64 %88, 3
  br i1 %89, label %90, label %83, !llvm.loop !21

90:                                               ; preds = %83, %90
  %91 = phi i64 [ %95, %90 ], [ 0, %83 ]
  %92 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %91
  %93 = load i8, ptr %92, align 1, !tbaa !20
  %94 = tail call signext i8 @cq_theta_si8(i8 noundef signext %93, double noundef 2.500000e-01) #7
  store i8 %94, ptr %92, align 1, !tbaa !20
  %95 = add nuw nsw i64 %91, 1
  %96 = icmp eq i64 %95, 3
  br i1 %96, label %97, label %90, !llvm.loop !22

97:                                               ; preds = %90, %97
  %98 = phi i64 [ %105, %97 ], [ 0, %90 ]
  %99 = phi i32 [ %104, %97 ], [ 0, %90 ]
  %100 = getelementptr inbounds [3 x i8], ptr %1, i64 0, i64 %98
  %101 = load i8, ptr %100, align 1, !tbaa !20
  %102 = tail call signext i8 @cq_measure_si8(i8 noundef signext %101) #6
  %103 = sext i8 %102 to i32
  %104 = add nsw i32 %99, %103
  %105 = add nuw nsw i64 %98, 1
  %106 = icmp eq i64 %105, 3
  br i1 %106, label %107, label %97, !llvm.loop !23

107:                                              ; preds = %97
  %108 = add nsw i32 %53, %27
  %109 = add nsw i32 %108, %79
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %1) #6
  %110 = add nsw i32 %109, %104
  ret i32 %110
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"_Bool", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{i8 0, i8 2}
!11 = !{}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
!17 = distinct !{!17, !13, !14}
!18 = distinct !{!18, !13, !14}
!19 = distinct !{!19, !13, !14}
!20 = !{!8, !8, i64 0}
!21 = distinct !{!21, !13, !14}
!22 = distinct !{!22, !13, !14}
!23 = distinct !{!23, !13, !14}
