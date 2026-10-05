; lowering_lift_reader_two_lifts_accept.ll — ACCEPT (bd test_C_libtooling-r2j3.11,
; the guard against the new post-lift reader re-ask over-declining). `clang -O1` of
;
;     int q = 7; cq_theta(&q, .5);
;     if (c) cq_theta(&q, .125);
;     if (d) cq_theta(&q, .25);
;     return cq_measure(q);
;
; Two one-register lifts onto `%3`. The second phi's edges are `%11 =
; cq_theta(%8, .25)` and `%8` itself, so BOTH derive from the first phi and its
; record (`%6`) is inherited; the measure is exempt from `%6` and `%11`.
;
; Trace (by hand): h = alloc(7); Ry(.5); [c] Ry(.125); [d] Ry(.25); measure h.
; On every one of the four paths the wire holds exactly the gates the name `q`
; records (the source rotates `q` in place each time), so the measurement reads
; `q`. No rail is freed (h is measured), nothing is uncomputed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; DIAG-NOT: warning
; CHECK-LABEL: define i32 @f(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NOT:  cqrt_free
; CHECK:      ret i32

define i32 @f(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01)
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = icmp eq i32 %1, 0
  br i1 %9, label %12, label %10

10:                                               ; preds = %7
  %11 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 2.500000e-01)
  br label %12

12:                                               ; preds = %10, %7
  %13 = phi i32 [ %11, %10 ], [ %8, %7 ]
  %14 = tail call i32 @cq_measure_si32(i32 noundef %13)
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)
