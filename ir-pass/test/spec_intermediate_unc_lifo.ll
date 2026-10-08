; spec_intermediate_unc_lifo.ll — ACCEPT, DISCHARGED (bd test_C_libtooling-p3kd.13):
; the reverse ORDER of clone-twin adjoints, and the two placements beyond a plain
; straight-line consumer.
;
; SOURCE (`clang -O1` IR below, verbatim up to attribute groups and loop metadata):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     int nested(int m)       { int q = m & 7; cq_theta(&q, .5);
;                               int s = h(h(q)) * 5; return cq_measure(s); }
;     int mixed(int m)        { ... int s = h(h(q) * 5); return cq_measure(s); }
;     int dead_rotated(int m) { ... int r = h(q); cq_theta(&r, .3);
;                               cq_theta(&q, .7); return cq_measure(q); }
;     int in_loop(int m)      { int acc = 0; for (int i = 0; i < 3; i++) {
;                               int q = m + i; cq_theta(&q, .5);
;                               int t = h(q) * 5; acc += cq_measure(t); } return acc; }
;
; @nested — CLONE CONSUMED BY A CLONE. Two clone rails in one component: the outer
;   result's twin runs first (it reads the inner result), then the inner's — the
;   reverse of program order, as for any template chain. The inner rail's consumer
;   is the outer clone CALL, admitted because its body provably never writes the
;   formal (`cloneCallPreservesArg`, bd rhk5).
; @mixed — CLONE → TEMPLATE → CLONE. `mul_unc` before the inner twin (LIFO).
; @dead_rotated — a clone result that is a DEAD TERMINAL (rotated in place, never
;   read). The whole-DAG spine reverse-plays its Ry and its twin and frees it, with
;   the measured source wire borrowed — the hand-inlined twin's stream (main
;   db4cf60a left the rail allocated and entangled; with clone results as terminals
;   but the frontier retry's clause-(d) scan still blind to clone calls it was a
;   LOUD `dead chain would free a measured register`, measured on this function).
; @in_loop — an ITERATION-LOCAL discharge: the twin and free run in the loop body,
;   once per trip, against a rail minted once per trip.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; SILENT-NOT: {{.}}

; CHECK-LABEL: define i32 @nested(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[A:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H]])
; CHECK-NEXT: %[[B:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[A]])
; CHECK-NEXT: %[[S:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[B]], i32 5)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[B]], i32 %[[A]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[B]])
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[A]], i32 %[[H]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S]])

; CHECK-LABEL: define i32 @mixed(
; CHECK:      %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK:      %[[A2:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H2]])
; CHECK-NEXT: %[[T2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[A2]], i32 5)
; CHECK-NEXT: %[[B2:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[T2]])
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T2]], i32 %[[A2]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T2]])
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[A2]], i32 %[[H2]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[A2]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[B2]])

; CHECK-LABEL: define i32 @dead_rotated(
; CHECK:      %[[H3:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H3]], double 5.000000e-01)
; CHECK-NEXT: %[[R3:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H3]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R3]], double 3.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R3]], double -3.000000e-01)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R3]], i32 %[[H3]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R3]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H3]], double 0x3FE6666666666666)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H3]])

; CHECK-LABEL: define i32 @in_loop(
; CHECK:      %[[H4:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H4]], double 5.000000e-01)
; CHECK-NEXT: %[[R4:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[H4]])
; CHECK-NEXT: %[[S4:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[R4]], i32 5)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R4]], i32 %[[H4]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R4]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[S4]])
; CHECK:      br i1 %{{[0-9]+}}, label %{{[0-9]+}}, label %{{[0-9]+}}

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @nested(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = tail call fastcc i32 @h(i32 noundef %4)
  %6 = mul nsw i32 %5, 5
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  ret i32 %7
}

define i32 @mixed(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = mul nsw i32 %4, 5
  %6 = tail call fastcc i32 @h(i32 noundef %5)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  ret i32 %7
}

define i32 @dead_rotated(i32 noundef %0) {
  %2 = and i32 %0, 7
  %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) #1
  %4 = tail call fastcc i32 @h(i32 noundef %3)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 3.000000e-01) #1
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 0x3FE6666666666666) #1
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6)
  ret i32 %7
}

define i32 @in_loop(i32 noundef %0) {
  br label %3

2:
  ret i32 %11

3:
  %4 = phi i32 [ 0, %1 ], [ %11, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %12, %3 ]
  %6 = add nsw i32 %5, %0
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01) #1
  %8 = tail call fastcc i32 @h(i32 noundef %7)
  %9 = mul nsw i32 %8, 5
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %11 = add nsw i32 %10, %4
  %12 = add nuw nsw i32 %5, 1
  %13 = icmp eq i32 %12, 3
  br i1 %13, label %2, label %3
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nomerge nounwind }
