; lowering_loop_break_qram_index_narrow.ll — ACCEPT (bd test_C_libtooling-01po.3,
; companion of lowering_loop_break_qram_index_i64.ll). The same value-arm `break`
; + const-table subscript at the NARROW rail widths, plus the i32 control:
;
;     T p = cq_theta(pseed, 0.5);  T q = cq_theta(seed, 0.25);
;     for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
;     return cq_measure(tbl[q]);
;
;   @run_i8   T = signed char     -O1: `sext i8 %q to i64` feeds the gep
;   @run_u16  T = unsigned short  -O1: `zext i16 %q to i64` feeds the gep
;   @run_i32  T = int             -O1: `sext i32 %q to i64` (the CONTROL)
;
; `planIndex` (QramIndexWidth.cpp) strips the -O1 widening, so the index it sees
; is `%cq.brk.out` itself, an i32 HANDLE. Without the break rail's `HandleWidth`
; record (the defect) its width read as the laundered "i32" and the 8/16-bit rail
; went to the QRAM call unbracketed — a narrow rail where the runtime contract
; (runtime/cq_runtime.h, QRAM preamble) requires LOGICAL width 32. With the record
; the narrow index re-extends with the STRIPPED cast's own kind (`sext` for the
; signed char, `zext` for the unsigned short). The i32 control is unchanged by the
; record (record "i32" == the type fallback): no bracket at all.
;
; Stage-1 IR: clang -O1 of the C above (attributes trimmed, functions renamed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

@tbl = internal unnamed_addr constant [8 x i32] [i32 10, i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17], align 16

define i32 @run_i8(i8 noundef signext %0, i8 noundef signext %1, i32 noundef %2) {
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
  %17 = sext i8 %16 to i64
  %18 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %17
  %19 = load i32, ptr %18, align 4
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #1
  ret i32 %20
}

define i32 @run_u16(i16 noundef zeroext %0, i16 noundef zeroext %1, i32 noundef %2) {
  %4 = tail call zeroext i16 @cq_theta_ui16(i16 noundef zeroext %1, double noundef 5.000000e-01) #0
  %5 = tail call zeroext i16 @cq_theta_ui16(i16 noundef zeroext %0, double noundef 2.500000e-01) #0
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %7, label %15

7:
  %8 = phi i32 [ %12, %7 ], [ 0, %3 ]
  %9 = phi i16 [ %10, %7 ], [ %5, %3 ]
  %10 = xor i16 %9, 5
  %11 = icmp eq i16 %10, %4
  %12 = add nuw nsw i32 %8, 1
  %13 = icmp eq i32 %12, %2
  %14 = select i1 %11, i1 true, i1 %13
  br i1 %14, label %15, label %7

15:
  %16 = phi i16 [ %5, %3 ], [ %10, %7 ]
  %17 = zext i16 %16 to i64
  %18 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %17
  %19 = load i32, ptr %18, align 4
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #1
  ret i32 %20
}

define i32 @run_i32(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
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
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %17
  %19 = load i32, ptr %18, align 4
  %20 = tail call i32 @cq_measure_si32(i32 noundef %19) #1
  ret i32 %20
}

declare i8 @cq_theta_si8(i8 noundef signext, double noundef)
declare i16 @cq_theta_ui16(i16 noundef zeroext, double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }

; CHECK-LABEL: define i32 @run_i8(
; CHECK:      %[[A8:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[O8:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK:      cq.brk.tail:
; CHECK:      %[[T8:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i8_to_i32(i32 %[[O8]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[A8]], i32 %[[T8]])
; CHECK-NEXT: call void @cq_template_sext_i8_to_i32_unc(i32 %[[T8]], i32 %[[O8]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T8]])
; CHECK:      ret i32

; CHECK-LABEL: define i32 @run_u16(
; CHECK:      %[[A16:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[O16:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i16(i16 0)
; CHECK:      cq.brk.tail:
; CHECK:      %[[T16:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i16_to_i32(i32 %[[O16]])
; CHECK-NEXT: call i32 @cqrt_qram_load_i32(i32 %[[A16]], i32 %[[T16]])
; CHECK-NEXT: call void @cq_template_zext_i16_to_i32_unc(i32 %[[T16]], i32 %[[O16]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T16]])
; CHECK:      ret i32

; CHECK-LABEL: define i32 @run_i32(
; CHECK:      %[[A32:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[O32:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:      cq.brk.tail:
; CHECK-NOT:  cq_template_{{(sext|zext|trunc)}}
; CHECK:      call i32 @cqrt_qram_load_i32(i32 %[[A32]], i32 %[[O32]])
; CHECK-NOT:  cq_template_{{(sext|zext|trunc)}}
; CHECK:      ret i32
