; control_guarded_store_ifelse_phase_full_repro.ll — bd test_C_libtooling-dm7f.3
; ACCEPT: the ORIGINAL reproducer, including the later Ry on q (the index source).
;
; SOURCE (clang -O1, attributes, lifetime markers and TBAA trimmed):
;     int arr[8] = {0};
;     int c = argc + 1; cq_theta(&c, 0.5);
;     int q = argc + 2; cq_theta(&q, 0.5);
;     if (c < 3) { arr[q & 7] = 7; cq_phi(0.25); }
;     else       { arr[(q ^ 5) & 7] = 9; }
;     int p = argc + 3; cq_theta(&p, 0.5);
;     int v = arr[p & 7];
;     cq_theta(&c, -0.5);
;     cq_theta(&q, -0.5);
;     return cq_measure(c) + cq_measure(q) + cq_measure(v);
;
; On main 7b4e6359 this declined `cq taint escape: tainted value reaches an
; unsupported instruction` at the true arm's gep. It now lowers with the region
; stream control_guarded_store_ifelse_phase.ll argues (that file is this program
; without the `cq_theta(&q, -0.5)` line). WHAT THIS FILE ADDS is the later Ry on
; q: `-O1` hoists the shared index `q & 7` into the pred, and both index rails
; (`i = and(h_q,7)`, `j = xor(i,5)`) are discharged right after the second store,
; so `cqrt_ry_i32(h_q, -0.5)` acts on a register no compiler-made record still
; copies. The array cells stay correlated with c and q exactly as the source's
; stores make them.
;
; NEIGHBOUR THAT STILL DECLINES: when an arm computes its own index from q (`else
; { arr[(q >> 1) & 7] = 9; }` keeps `q & 7` in the true arm), the stale-record
; guard refuses the in-arm index before detection runs:
; control_guarded_store_ifelse_reject_inarm_index_later_ry.ll (bd 01po.7).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

; CHECK-LABEL: define i32 @main(
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[C]], double 5.000000e-01)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[I:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 7)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[C]], i32 3)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[F1]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[I]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i32_hl(i32 %[[C]], i32 3)
; CHECK:      %[[J:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[I]], i32 5)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[F3]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[J]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cq_template_xor_i32_hl_unc(i32 %[[J]], i32 %[[I]], i32 5)
; CHECK:      call void @cq_template_and_i32_hl_unc(i32 %[[I]], i32 %[[Q]], i32 7)
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[C]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[C]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: br label
; CHECK:      call void @cqrt_ry_i32(i32 %[[C]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double -5.000000e-01)
; CHECK-NOT:  call void @cq_template_and_i32_hl_unc(i32 %[[I]]
; CHECK-NOT:  call void @cq_template_xor_i32_hl_unc(i32 %[[J]]

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = add nsw i32 %0, 1
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 5.000000e-01)
  %6 = add nsw i32 %0, 2
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 5.000000e-01)
  %8 = icmp slt i32 %5, 3
  %9 = and i32 %7, 7
  br i1 %8, label %10, label %13

10:
  %11 = zext nneg i32 %9 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %11
  store i32 7, ptr %12, align 4
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %17

13:
  %14 = xor i32 %9, 5
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %15
  store i32 9, ptr %16, align 4
  br label %17

17:
  %18 = add nsw i32 %0, 3
  %19 = tail call i32 @cq_theta_si32(i32 noundef %18, double noundef 5.000000e-01)
  %20 = and i32 %19, 7
  %21 = zext nneg i32 %20 to i64
  %22 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %21
  %23 = load i32, ptr %22, align 4
  %24 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef -5.000000e-01)
  %25 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef -5.000000e-01)
  %26 = tail call i32 @cq_measure_si32(i32 noundef %24)
  %27 = tail call i32 @cq_measure_si32(i32 noundef %25)
  %28 = add nsw i32 %27, %26
  %29 = tail call i32 @cq_measure_si32(i32 noundef %23)
  %30 = add nsw i32 %28, %29
  ret i32 %30
}
