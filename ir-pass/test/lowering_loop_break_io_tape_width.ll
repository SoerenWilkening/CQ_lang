; lowering_loop_break_io_tape_width.ll — ACCEPT (bd test_C_libtooling-01po.3,
; round-1 review F2). A value-arm `break` whose answer is printed:
;
;     T p = cq_theta(pseed, 0.5), q = cq_theta(seed, 0.25);
;     for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
;     printf(FMT, q);
;
; `lowerIOSinks` records the printed register on the output tape with
; `cqrt_tape_write_<W>(tape, q)`, `<W>` = q's width. The break answer is
; `%cq.brk.out`, an i32 HANDLE whose width lives only in `taint.HandleWidth`, and
; `collectTapeTargets` (IOSinkLowering.cpp) read the width off the arg's TYPE —
; the laundered i32 — so @print_i64 (`long long`, "%lld") recorded a 64-bit rail
; as `cqrt_tape_write_i32` (verify-clean, opt rc 0, MEASURED on the pre-fix build
; and on main; a plain i64 theta printed the same way gets `tape_write_i64`).
; The tape target now asks `logicalOperandWidth` (the one spelling, R12).
; @print_i32 (`int`, "%d") is the control: unchanged, `tape_write_i32`.
;
; Each function is the clang -O1 IR of the C above (attributes trimmed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

@.str64 = private unnamed_addr constant [6 x i8] c"%lld\0A\00", align 1
@.str32 = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define i64 @print_i64(i64 noundef %0, i64 noundef %1, i32 noundef %2) {
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
  %17 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str64, i64 noundef %16)
  ret i64 0
}
; CHECK-LABEL: define i64 @print_i64(
; CHECK:      %[[O64:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      cq.brk.tail:
; CHECK-NOT:  @cqrt_tape_write_i32
; CHECK:      call i32 @cqrt_tape_write_i64(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[O64]])
; CHECK:      ret i64 0

define i32 @print_i32(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) #0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01) #0
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %15

7:
  %8 = phi i32 [ %12, %7 ], [ 0, %3 ]
  %9 = phi i32 [ %10, %7 ], [ %5, %3 ]
  %10 = xor i32 %9, 5
  %11 = icmp eq i32 %10, %4
  %12 = add nuw nsw i32 %8, 1
  %13 = icmp eq i32 %12, %2
  %14 = select i1 %11, i1 true, i1 %13
  br i1 %14, label %15, label %7

15:
  %16 = phi i32 [ %5, %3 ], [ %10, %7 ]
  %17 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str32, i32 noundef %16)
  ret i32 0
}
; CHECK-LABEL: define i32 @print_i32(
; CHECK:      %[[O32:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      cq.brk.tail:
; CHECK:      call i32 @cqrt_tape_write_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[O32]])
; CHECK:      ret i32 0

declare i64 @cq_theta_sll(i64 noundef, double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @printf(ptr nocapture noundef readonly, ...)

attributes #0 = { nomerge nounwind }
