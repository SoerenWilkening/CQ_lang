; lowering_lift_reader_tape_accept.ll — ACCEPT (bd test_C_libtooling-r2j3.12, the
; guard against the tape re-ask over-declining). `clang -O1` of
;
;     int q = 7; cq_theta(&q, .5);
;     if (c) { cq_theta(&q, .125); cq_theta(&q, .25); }
;     printf("%d\n", q);
;     return cq_measure(q);
;
; The printed name is the lifted phi over BOTH arm gates, so both are on the record
; the tape write reads and the re-ask exempts them.
;
; Trace (by hand): tape = tape_alloc; h = alloc(7); Ry(.5); [c] Ry(.125); Ry(.25);
; tape_write(tape, h) records the register `q` names on each path; measure(h).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.ll
; DIAG-NOT: error
; CHECK-LABEL: define i32 @f(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:      call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[H]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[H]])

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define i32 @f(i32 noundef %0, i32 %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %8, label %5

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01)
  br label %8

8:                                                ; preds = %5, %2
  %9 = phi i32 [ %7, %5 ], [ %3, %2 ]
  %10 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %9)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %9)
  ret i32 %11
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare noundef i32 @printf(ptr nocapture noundef readonly, ...)

declare i32 @cq_measure_si32(i32 noundef)
