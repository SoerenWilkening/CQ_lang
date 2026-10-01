; lowering_loop_break_qram_index_i64.ll — ACCEPT (bd test_C_libtooling-01po.3,
; round-1 review F2 of 01po.1). An i64-rail value-arm `break` whose escaping
; answer `q` then subscripts a const table:
;
;     long long p = cq_theta(pseed, 0.5);
;     long long q = cq_theta(seed, 0.25);
;     for (int i = 0; i < n; i++) {
;         q = q ^ 5;
;         if (q == p) break;
;     }
;     return cq_measure(tbl[q]);
;
; `emitBreakForward` (LoopLowering.cpp) RAUWs the i64 exit phi to `%cq.brk.out`,
; an i32 HANDLE from `cqrt_alloc_i64`. Its LOGICAL width (64) lives only in the
; `taint.HandleWidth` record; `resolveQramIndex` (QramIndexWidth.cpp) reads the
; width through `logicalOperandWidth`, which falls back to the laundered i32 SSA
; type when the record is absent. Before the fix the break rails were minted with
; NO record, so the QRAM call got the 64-bit rail as its index —
; `cqrt_qram_load_i32(%arr, %cq.brk.out)` — breaking the runtime/cq_runtime.h
; contract (every QRAM index, forward and `_unc`, is a rail of LOGICAL width 32).
; With the record the call is bracketed by the per-call trunc (four consecutive
; calls; the cast rail never outlives the load).
;
; The NOBARE prefix has only NOT directives, so it scans the WHOLE output: the
; bare 64-bit rail must never reach a QRAM index slot.
;
; Stage-1 IR: clang -O1 of the C above (attributes trimmed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOBARE < %t.cqd0.ll

@tbl = internal unnamed_addr constant [8 x i32] [i32 10, i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17], align 16

define i32 @run(i64 noundef %0, i64 noundef %1, i32 noundef %2) {
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
  %17 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %16
  %18 = load i32, ptr %17, align 4
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18) #1
  ret i32 %19
}

declare i64 @cq_theta_sll(i64 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }

; CHECK-LABEL: define i32 @run(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[OUT:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      cq.brk.tail:
; CHECK:      %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[OUT]])
; CHECK-NEXT: %[[L:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[T]])
; CHECK-NEXT: call void @cq_template_trunc_i64_to_i32_unc(i32 %[[T]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[L]])

; NOBARE-NOT: @cqrt_qram_load_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %cq.brk.out
