; lowering_reject_qram_store_dropped_record_clone_value.ll — DECLINE (bd
; test_C_libtooling-r2j3.21, batch 053 unit D). The former @store_value of
; spec_intermediate_unc_user_helper.ll (bd p3kd.13), moved here because the r2j3.21
; fix showed it was a SILENT MISCOMPILE that the accept fixture had pinned.
;
; SOURCE (`clang -O1` IR below, verbatim up to attribute groups):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     int store_value(int m) { int arr[8] = {0}; int q = 0; cq_theta(&q, 0.5);
;       int r = 1; cq_theta(&r, 0.5); arr[q & 7] = h(r) * 5;      /* a QRAM STORE */
;       int p = 4; cq_theta(&p, 0.5); int v = arr[p & 7];
;       cq_theta(&q, -0.5); cq_theta(&r, -0.5);
;       return cq_measure(q) + cq_measure(r) + cq_measure(v); }
;
; main fc6ee653 (cq-opt f4379f18, measured): rc 0, silent. The clone chain feeding
; the store's value and the `and` index are discharged right after the store (M-B),
; the measured `v` is copied out and its load reversed after the copy — so the
; group's reversal point lies after `cqrt_ry_i32(q, -0.5)` and `cqrt_ry_i32(r,
; -0.5)` — and `cqrt_qram_store_i32(arr, q & 7, 5·h(r))` is NEVER reversed. The array
; is dead once `v` has its copy, so that store is a full dead record of q and r
; standing across both Rys. Here p ∈ {4, 5} and q ∈ {0, 1}, so `v` is always 0 and
; carries nothing: in the source q returns to |0⟩ deterministically (P(q=1) = 0),
; while the emitted circuit leaves cell q holding 5·h(r) ≠ 0, a which-path record of
; q, so P(q=1) > 0 (owner ruling 2026-10-05; owner ruling 2026-10-13 for the store).
;
; NOW: the cut store is hazardous (TerminalGroups.h, CUT RECORDS); the array-walking
; retry would reverse it at the group's point, after both moves, which q's and r's
; windows refuse: LOUD at the store. The p3kd.13 capability the old function pinned
; (a clone chain feeding a store's value, discharged LIFO after the store) stays
; pinned in spec_intermediate_unc_user_helper.ll with q and r measured unrotated.
; RETIREMENT TRIGGER (L7): the early-reversal schedule (the store `_unc` right after
; the load, before the moves, keeping `v`; the owner ruling's named follow-up) makes
; this an ACCEPT.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}in function store_value i32 (i32): cq uncompute: dead record cut from the uncompute frontier is not reversed before its parent's next non-diagonal gate

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @store_value(i32 noundef %0) {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #1
  %4 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #1
  %5 = tail call fastcc i32 @h(i32 noundef %4)
  %6 = mul nsw i32 %5, 5
  %7 = and i32 %3, 7
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %8
  store i32 %6, ptr %9, align 4
  %10 = tail call i32 @cq_theta_si32(i32 noundef 4, double noundef 5.000000e-01) #1
  %11 = and i32 %10, 7
  %12 = zext nneg i32 %11 to i64
  %13 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %12
  %14 = load i32, ptr %13, align 4
  %15 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef -5.000000e-01) #1
  %16 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #1
  %17 = tail call i32 @cq_measure_si32(i32 noundef %15)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %16)
  %19 = add nsw i32 %18, %17
  %20 = tail call i32 @cq_measure_si32(i32 noundef %14)
  %21 = add nsw i32 %19, %20
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2)
  ret i32 %21
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nomerge nounwind }
