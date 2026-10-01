; lowering_loop_break_abort_park_width.ll — ACCEPT (bd test_C_libtooling-r2j3.5;
; round-1 review F1 of 01po.3). A value-arm `break` whose answer is then PARKED by a
; noreturn arm (`if (q ...) abort();`, AbortParkEmit): the park swaps the routed
; register into a fresh |0> graveyard rail under the abort flag,
; `cqrt_cswap(flag, q, grave)`, so `grave` must have q's LOGICAL width.
;
; The break answer reaching the park is `%cq.brk.out`, an i32 HANDLE whose width
; lives only in `taint.HandleWidth` (control emission runs after `lowerLoops`).
; AbortParkEmit read the width off `Q->getType()` — the laundered i32 — so it
; minted `%grave = cqrt_alloc_i32(0)` and cswapped a 32-qubit graveyard against a
; 64-qubit (@park_i64) or 8-qubit (@park_i8) rail: verify-clean, opt rc 0
; (MEASURED on the pre-fix build). @park_trunc_print is the round-1 reviewer's
; probe p8f: `printf("%d\n", (int)q)` before the park. Before 01po.3 that program
; was declined ("no template for opcode 'trunc i32'"); 01po.3 made it compile, and
; with it the wrong-width park (L9: a newly reachable customer of this defect).
; The park now asks `logicalOperandWidth` (the one spelling, R12) for both the
; classifier gate and the graveyard mint.
;
; NOGRAVE32 has only NOT directives (whole-output scan): every routed register
; in this module is 8- or 64-bit, so no graveyard may be an i32 rail.
;
; Each function is the clang -O1 IR of the C in its comment (attributes trimmed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOGRAVE32 < %t.cqd0.ll
; NOGRAVE32-NOT: %grave{{[0-9]*}} = call i32 @cqrt_alloc_i32

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; long long p = cq_theta(pseed,.5), q = cq_theta(seed,.25);
; for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
; if (q == 9) abort();
; return cq_measure(q);
define i64 @park_i64(i64 noundef %0, i64 noundef %1, i32 noundef %2) {
  %4 = tail call i64 @cq_theta_sll(i64 noundef %1, double noundef 5.000000e-01) #0
  %5 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef 2.500000e-01) #0
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %15

7:
  %8 = phi i32 [ %12, %7 ], [ 0, %3 ]
  %9 = phi i64 [ %10, %7 ], [ %5, %3 ]
  %10 = xor i64 %9, 5
  %11 = icmp eq i64 %10, %4
  %12 = add nuw nsw i32 %8, 1
  %13 = icmp eq i32 %12, %2
  %14 = select i1 %11, i1 true, i1 %13
  br i1 %14, label %15, label %7

15:
  %16 = phi i64 [ %5, %3 ], [ %10, %7 ]
  %17 = icmp eq i64 %16, 9
  br i1 %17, label %18, label %19

18:
  tail call void @abort() #2
  unreachable

19:
  %20 = tail call i64 @cq_measure_sll(i64 noundef %16) #1
  ret i64 %20
}
; CHECK-LABEL: define i64 @park_i64(
; CHECK:      %[[O64:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      cq.brk.tail:
; CHECK:      %[[F64:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i64_hl(i32 %[[O64]], i64 9)
; CHECK-NEXT: %[[G64:grave[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F64]], i32 %[[O64]], i32 %[[G64]])
; CHECK:      call i64 @cqrt_measure_i64(i32 %[[O64]])

; The same over signed char rails.
define signext i8 @park_i8(i8 noundef signext %0, i8 noundef signext %1, i32 noundef %2) {
  %4 = tail call signext i8 @cq_theta_si8(i8 noundef signext %1, double noundef 5.000000e-01) #0
  %5 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 2.500000e-01) #0
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %15

7:
  %8 = phi i32 [ %12, %7 ], [ 0, %3 ]
  %9 = phi i8 [ %10, %7 ], [ %5, %3 ]
  %10 = xor i8 %9, 5
  %11 = icmp eq i8 %10, %4
  %12 = add nuw nsw i32 %8, 1
  %13 = icmp eq i32 %12, %2
  %14 = select i1 %11, i1 true, i1 %13
  br i1 %14, label %15, label %7

15:
  %16 = phi i8 [ %5, %3 ], [ %10, %7 ]
  %17 = icmp eq i8 %16, 9
  br i1 %17, label %18, label %19

18:
  tail call void @abort() #2
  unreachable

19:
  %20 = tail call signext i8 @cq_measure_si8(i8 noundef signext %16) #1
  ret i8 %20
}
; CHECK-LABEL: define signext i8 @park_i8(
; CHECK:      %[[O8:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK:      cq.brk.tail:
; CHECK:      %[[F8:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i8_hl(i32 %[[O8]], i8 9)
; CHECK-NEXT: %[[G8:grave[0-9]*]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F8]], i32 %[[O8]], i32 %[[G8]])
; CHECK:      call i8 @cqrt_measure_i8(i32 %[[O8]])

; long long p = cq_theta(pseed,.5), q = cq_theta(seed,.25);
; for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
; printf("%d\n", (int)q);
; if (q > 5) abort();
; return cq_measure(q);
define i64 @park_trunc_print(i64 noundef %0, i64 noundef %1, i32 noundef %2) {
  %4 = tail call i64 @cq_theta_sll(i64 noundef %1, double noundef 5.000000e-01) #0
  %5 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef 2.500000e-01) #0
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %15

7:
  %8 = phi i32 [ %12, %7 ], [ 0, %3 ]
  %9 = phi i64 [ %10, %7 ], [ %5, %3 ]
  %10 = xor i64 %9, 5
  %11 = icmp eq i64 %10, %4
  %12 = add nuw nsw i32 %8, 1
  %13 = icmp eq i32 %12, %2
  %14 = select i1 %11, i1 true, i1 %13
  br i1 %14, label %15, label %7

15:
  %16 = phi i64 [ %5, %3 ], [ %10, %7 ]
  %17 = trunc i64 %16 to i32
  %18 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %17)
  %19 = icmp sgt i64 %16, 5
  br i1 %19, label %20, label %21

20:
  tail call void @abort() #2
  unreachable

21:
  %22 = tail call i64 @cq_measure_sll(i64 noundef %16) #1
  ret i64 %22
}
; CHECK-LABEL: define i64 @park_trunc_print(
; CHECK:      %[[OT:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      cq.brk.tail:
; CHECK:      %[[TT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[OT]])
; CHECK-NEXT: call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[TT]])
; CHECK-NEXT: %[[FT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i64_hl(i32 %[[OT]], i64 5)
; CHECK-NEXT: %[[GT:grave[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[FT]], i32 %[[OT]], i32 %[[GT]])
; CHECK:      call i64 @cqrt_measure_i64(i32 %[[OT]])

declare i64 @cq_theta_sll(i64 noundef, double noundef)
declare i8 @cq_theta_si8(i8 noundef signext, double noundef)
declare i64 @cq_measure_sll(i64 noundef)
declare i8 @cq_measure_si8(i8 noundef signext)
declare i32 @printf(ptr nocapture noundef readonly, ...)
declare void @abort()

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }
attributes #2 = { cold noreturn nounwind }
