; lowering_loop_break_out_width_overdecline.ll — ACCEPT (bd test_C_libtooling-01po.3
; audit; decline -> accept). Three uses of an i64 break answer `%cq.brk.out` that
; the pre-fix build DECLINED loudly, because the break rails carried no
; `taint.HandleWidth` record and each width consumer saw the laundered i32 handle:
;
;   @trunc_i64      `(int)q`         cast FROM-width captured "i32":
;                                    "no template for opcode 'trunc i32' in
;                                    tainted context"
;   @qqcmp_i64      `q == r` as data the raw Q+Q compare read an ABSENT record
;                   (r a 2nd i64 qubit) for `%cq.brk.out` and took its loud bail:
;                                    "no template for opcode 'icmp i1' in
;                                    tainted context"
;   @sel_theta_i64  `(q == r) ? r + 3 : r ^ 6`  `qqSelectLeafWidth` saw
;                                    "i32" (out) vs "i64" (r), disagreed, and
;                                    the select fell through to "cq controlled
;                                    lowering: control flow under quantum control"
;
; (MEASURED on the pre-fix build, one probe per function; opt stops at the first
; error, so only the first of these surfaces for this whole module.) With the
; record each consumer reads "i64" and the existing i64 template is minted:
; `cq_template_trunc_i64_to_i32`, the bare Q+Q `cq_template_icmp_eq_i64`, and
; the 4.4 select's Q+Q leaf `cq_template_icmp_eq_i64` on (out, r).
;
; Each function is the clang -O1 IR of the C in its comment (attributes trimmed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

; long long p = pseed, q = seed; cq_theta(&p,.5); cq_theta(&q,.25);
; for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
; return cq_measure((int)q);
define i32 @trunc_i64(i64 noundef %0, i64 noundef %1, i32 noundef %2) {
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
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #1
  ret i32 %18
}
; CHECK-LABEL: define i32 @trunc_i64(
; CHECK:      %[[TO:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      cq.brk.tail:
; CHECK:      %[[TC:[a-zA-Z0-9_.]+]] = call i32 @cq_template_trunc_i64_to_i32(i32 %[[TO]])
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[TC]])

; long long p = pseed, r = rseed, q = seed; cq_theta(&p,.5); cq_theta(&r,.75); cq_theta(&q,.25);
; for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
; return cq_measure(q == r);
define i32 @qqcmp_i64(i64 noundef %0, i64 noundef %1, i64 noundef %2, i32 noundef %3) {
  %5 = tail call i64 @cq_theta_sll(i64 noundef %1, double noundef 5.000000e-01) #0
  %6 = tail call i64 @cq_theta_sll(i64 noundef %2, double noundef 7.500000e-01) #0
  %7 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef 2.500000e-01) #0
  %8 = icmp sgt i32 %3, 0
  br i1 %8, label %9, label %17

9:
  %10 = phi i32 [ %14, %9 ], [ 0, %4 ]
  %11 = phi i64 [ %12, %9 ], [ %7, %4 ]
  %12 = xor i64 %11, 5
  %13 = icmp eq i64 %12, %5
  %14 = add nuw nsw i32 %10, 1
  %15 = icmp eq i32 %14, %3
  %16 = select i1 %13, i1 true, i1 %15
  br i1 %16, label %17, label %9

17:
  %18 = phi i64 [ %7, %4 ], [ %12, %9 ]
  %19 = icmp eq i64 %18, %6
  %20 = zext i1 %19 to i32
  %21 = tail call i32 @cq_measure_si32(i32 noundef %20) #1
  ret i32 %21
}
; CHECK-LABEL: define i32 @qqcmp_i64(
; CHECK:      %[[QR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %2)
; CHECK:      %[[QO:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      cq.brk.tail:
; CHECK:      call i32 @cq_template_icmp_eq_i64(i32 %[[QO]], i32 %[[QR]])
; CHECK:      ret i32

; long long p = pseed, r = rseed, q = seed; cq_theta(&p,.5); cq_theta(&r,.75); cq_theta(&q,.25);
; for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
; return cq_measure((q == r) ? r + 3 : r ^ 6);
define i64 @sel_theta_i64(i64 noundef %0, i64 noundef %1, i64 noundef %2, i32 noundef %3) {
  %5 = tail call i64 @cq_theta_sll(i64 noundef %1, double noundef 5.000000e-01) #0
  %6 = tail call i64 @cq_theta_sll(i64 noundef %2, double noundef 7.500000e-01) #0
  %7 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef 2.500000e-01) #0
  %8 = icmp sgt i32 %3, 0
  br i1 %8, label %9, label %17

9:
  %10 = phi i64 [ %12, %9 ], [ %7, %4 ]
  %11 = phi i32 [ %14, %9 ], [ 0, %4 ]
  %12 = xor i64 %10, 5
  %13 = icmp eq i64 %12, %5
  %14 = add nuw nsw i32 %11, 1
  %15 = icmp eq i32 %14, %3
  %16 = select i1 %13, i1 true, i1 %15
  br i1 %16, label %17, label %9

17:
  %18 = phi i64 [ %7, %4 ], [ %12, %9 ]
  %19 = icmp eq i64 %18, %6
  %20 = add nsw i64 %6, 3
  %21 = xor i64 %6, 6
  %22 = select i1 %19, i64 %20, i64 %21
  %23 = tail call i64 @cq_measure_sll(i64 noundef %22) #1
  ret i64 %23
}
; CHECK-LABEL: define i64 @sel_theta_i64(
; CHECK:      %[[SR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %2)
; CHECK:      %[[SO:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      %[[SF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i64(i32 %[[SO]], i32 %[[SR]])
; CHECK:      call void @cq_template_icmp_eq_i64_unc(i32 %[[SF]], i32 %[[SO]], i32 %[[SR]])
; CHECK:      ret i64

declare i64 @cq_theta_sll(i64 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare i64 @cq_measure_sll(i64 noundef)

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }
