; lowering_loop_break_later_loop_comparand.ll — ACCEPT (bd test_C_libtooling-01po.3,
; requested by the round-1 review). The answer of one i64 value-arm `break` is the
; loop-invariant Q==Q COMPARAND of a second break loop:
;
;     long long p = cq_theta(pseed, 0.5), q = cq_theta(seed, 0.25);
;     for (int i = 0; i < n; i++) { q = q ^ 5; if (q == p) break; }
;     long long q2 = cq_theta(s2, 0.75);
;     for (int j = 0; j < n; j++) { q2 = q2 ^ 3; if (q2 == q) break; }
;     return cq_measure(q2);
;
; The second loop's break flag `icmp eq i64 %q2rail, %q` reads loop 1's
; `%cq.brk.out`, an i32 HANDLE. The flag is lowered by `lowerOps` as a data
; Q+Q compare, which takes its width from `taint.HandleWidth` RAW
; (CompareLowering.cpp, the agreement-or-decline read) and declines loudly when an
; operand has no record. Without the 01po.3 record on `out` this program declined:
; "no template for opcode 'icmp i1' in tainted context" (MEASURED 2026-10-01 with
; the record deleted, the mutant this fixture kills). With it both operands read
; "i64" and the flag is `cq_template_icmp_eq_i64(%q2rail, %out)`.
;
; Read in the lowered IR (2026-10-01): `out` is filled by loop 1's exit
; consolidation (`cqrt_copy_i64(R, out)`) before loop 2's preheader; loop 2 reads it
; ONLY as the compare's second operand, in the forward body and in the
; reverse-play clone, each paired with its `_unc`; it is never written, copied
; from, measured or freed. That is the loop-invariant comparand discipline of
; lowering_loop_break_qq.ll (`p` there): `out` is entangled with loop 2's answer,
; so it stays allocated (NOFREE), never reset dirty (R5).
;
; Stage-1 IR: clang -O1 of the C above (attributes trimmed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREE < %t.cqd0.ll
; NOFREE-NOT: @cqrt_free(i32 %cq.brk.out)

define i64 @run(i64 noundef %0, i64 noundef %1, i64 noundef %2, i32 noundef %3) {
  %5 = tail call i64 @cq_theta_sll(i64 noundef %1, double noundef 5.000000e-01) #0
  %6 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef 2.500000e-01) #0
  %7 = icmp sgt i32 %3, 0
  br i1 %7, label %8, label %16

8:
  %9 = phi i32 [ %13, %8 ], [ 0, %4 ]
  %10 = phi i64 [ %11, %8 ], [ %6, %4 ]
  %11 = xor i64 %10, 5
  %12 = icmp eq i64 %11, %5
  %13 = add nuw nsw i32 %9, 1
  %14 = icmp eq i32 %13, %3
  %15 = select i1 %12, i1 true, i1 %14
  br i1 %15, label %16, label %8

16:
  %17 = phi i64 [ %6, %4 ], [ %11, %8 ]
  %18 = tail call i64 @cq_theta_sll(i64 noundef %2, double noundef 7.500000e-01) #0
  %19 = icmp sgt i32 %3, 0
  br i1 %19, label %20, label %28

20:
  %21 = phi i32 [ %25, %20 ], [ 0, %16 ]
  %22 = phi i64 [ %23, %20 ], [ %18, %16 ]
  %23 = xor i64 %22, 3
  %24 = icmp eq i64 %23, %17
  %25 = add nuw nsw i32 %21, 1
  %26 = icmp eq i32 %25, %3
  %27 = select i1 %24, i1 true, i1 %26
  br i1 %27, label %28, label %20

28:
  %29 = phi i64 [ %18, %16 ], [ %23, %20 ]
  %30 = tail call i64 @cq_measure_sll(i64 noundef %29) #1
  ret i64 %30
}

declare i64 @cq_theta_sll(i64 noundef, double noundef)
declare i64 @cq_measure_sll(i64 noundef)

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }

; CHECK-LABEL: define i64 @run(
; --- loop 1 mints its answer `out`, fills it at its exit consolidation ---------
; CHECK:      %[[OUT:cq\.brk\.out[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      call void @cqrt_copy_i64(i32 %{{cq\.brk\.R[0-9]*}}, i32 %[[OUT]])
; --- loop 2: its own rail q2, then the forward Q==Q flag against `out` ----------
; CHECK:      cq.brk.tail:
; CHECK:      %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 %2)
; CHECK:      %[[OUT2:cq\.brk\.out[0-9]+]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      call void @cqrt_xorc_i64(i32 %[[Q2]], i64 3)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i64(i32 %[[Q2]], i32 %[[OUT]])
; CHECK:      call void @cq_template_icmp_eq_i64_unc(i32 %[[F]], i32 %[[Q2]], i32 %[[OUT]])
; --- loop 2's reverse-play clone reads the SAME `out` --------------------------
; CHECK:      call void @cqrt_copy_i64(i32 %{{cq\.brk\.R[0-9]+}}, i32 %[[OUT2]])
; CHECK:      %[[FR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i64(i32 %[[Q2]], i32 %[[OUT]])
; CHECK:      call void @cq_template_icmp_eq_i64_unc(i32 %[[FR]], i32 %[[Q2]], i32 %[[OUT]])
; CHECK:      call i64 @cqrt_measure_i64(i32 %[[OUT2]])
