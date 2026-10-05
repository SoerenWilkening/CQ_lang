; control_guarded_store_ifelse_inarm_index_later_ry.ll — bd
; test_C_libtooling-dm7f.3 ACCEPT, the bd 01po.7 neighbour of
; control_guarded_store_ifelse_phase_full_repro.ll.
;
; SOURCE (clang -O1, attributes, lifetime markers and TBAA trimmed):
;     if (c < 3) { arr[q & 7] = 7; cq_phi(0.25); }
;     else       { arr[(q >> 1) & 7] = 9; }
;     int p = argc + 3; cq_theta(&p, 0.5);
;     int v = arr[p & 7];
;     cq_theta(&c, -0.5);
;     cq_theta(&q, -0.5);
;     return cq_measure(c) + cq_measure(q) + cq_measure(v);
;
; The only difference from the full reproducer is that the arms compute
; DIFFERENT indices, so `-O1` leaves `q & 7` (`%10`) inside the true arm instead
; of hoisting it into the pred.
;
; HISTORY. This file was control_guarded_store_ifelse_reject_inarm_index_later_ry.ll,
; a DECLINE (`cq opcode lowering: operand predates a non-diagonal gate` at
; `%10`): the stale-record guard ran before detection, saw an index record of q
; under tainted control and a later Ry on q, and refused. Its header carried a
; retirement trigger on bd 01po.7. 01po.7 (commit ba8148c7) grants that read and
; re-checks its rail after uncompute placed every discharge; the batch-043
; integration composed it with dm7f.3's if/else carve, the module lowered, and
; the trigger fired at the batch gate. On main 7b4e6359 it declined earlier
; still, at the carve (`cq taint escape`, the true arm's gep).
;
; WHY THE STREAM IS RIGHT. Each arm's index chain is a classical function of q,
; minted into fresh rails in the pred, used once as the controlled store's
; index, and discharged by its `_unc` while q is still unrotated:
;   true arm   i = and(q,7)                  store(c<3)   and_unc(i)
;   else arm   l = lshr(q,1); j = and(l,7)   store(c>=3)  and_unc(j); lshr_unc(l)
; so `cqrt_ry_i32(h_q, -0.5)` acts on a register no compiler-made record still
; copies, and the cells hold exactly the source's stores, correlated with c and
; q. The branch phase is a kickback on a fresh c<3 flag (diagonal in c, so it
; commutes with the c-controlled stores). The loaded value v stays entangled with
; p, whose rail is never freed; only p's `and` index is discharged, against p.
; The constant value rails |7> and |9> stay allocated in the basis state they
; were minted in (a leak, not a dirty free).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[C]], double 5.000000e-01)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:      %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[C]], i32 3)
; CHECK:      %[[I:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 7)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[F1]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[I]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cq_template_and_i32_hl_unc(i32 %[[I]], i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[I]])
; CHECK:      %[[F3:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sge_i32_hl(i32 %[[C]], i32 3)
; CHECK:      %[[L:[a-zA-Z0-9_.]+]] = call i32 @cq_template_lshr_i32_hl(i32 %[[Q]], i32 1)
; CHECK-NEXT: %[[J:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[L]], i32 7)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[F3]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[J]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:      call void @cq_template_and_i32_hl_unc(i32 %[[J]], i32 %[[L]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[J]])
; CHECK-NEXT: call void @cq_template_lshr_i32_hl_unc(i32 %[[L]], i32 %[[Q]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[L]])
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[C]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[C]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: br label
; CHECK:      call void @cqrt_ry_i32(i32 %[[C]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double -5.000000e-01)
; CHECK-NOT:  _unc(i32 %[[I]],
; CHECK-NOT:  _unc(i32 %[[J]],
; CHECK-NOT:  _unc(i32 %[[L]],
; CHECK:      ret i32

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
  br i1 %8, label %9, label %13

9:
  %10 = and i32 %7, 7
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %11
  store i32 7, ptr %12, align 4
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %18

13:
  %14 = lshr i32 %7, 1
  %15 = and i32 %14, 7
  %16 = zext nneg i32 %15 to i64
  %17 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %16
  store i32 9, ptr %17, align 4
  br label %18

18:
  %19 = add nsw i32 %0, 3
  %20 = tail call i32 @cq_theta_si32(i32 noundef %19, double noundef 5.000000e-01)
  %21 = and i32 %20, 7
  %22 = zext nneg i32 %21 to i64
  %23 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %22
  %24 = load i32, ptr %23, align 4
  %25 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef -5.000000e-01)
  %26 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef -5.000000e-01)
  %27 = tail call i32 @cq_measure_si32(i32 noundef %25)
  %28 = tail call i32 @cq_measure_si32(i32 noundef %26)
  %29 = add nsw i32 %28, %27
  %30 = tail call i32 @cq_measure_si32(i32 noundef %24)
  %31 = add nsw i32 %29, %30
  ret i32 %31
}
