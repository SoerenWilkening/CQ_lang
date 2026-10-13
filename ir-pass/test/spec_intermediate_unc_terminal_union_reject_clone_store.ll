; spec_intermediate_unc_terminal_union_reject_clone_store.ll — DECLINE, as main,
; character for character (bd test_C_libtooling-p3kd.13, R11 review round 7, the
; F1 condition). Probe P2' of review/B7: the OBSERVABLE form of the benign-leak
; probe P2 (P2 is this function without the last `cq_theta(&k, -0.5)` and its
; measure: k is never touched again, so leaving the store is a leak; main 716269bc
; and the r6-fix WIP 033efa2b, whose extra `T.Stores` clause is implied, both
; decline P2 with this fixture's diagnostic — an over-decline against round 6
; only, see THE `Cut` CLAUSE IS COARSE in TerminalGroups.h).
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int mcs(int s) {
;       int arr[8] = {0};
;       int k = s & 7; cq_theta(&k, 0.5);
;       arr[k] = 7;
;       int q = (s >> 3) & 7; cq_theta(&q, 0.5); int t2 = q * 5; cq_theta(&t2, 0.4);
;       int acc = 0;
;       if (s > 3) { int u = (s >> 2) & 7; cq_theta(&u, 0.3); int t1 = u * 3;
;                    cq_theta(&t1, 0.25); acc = s; }
;       int p = (s >> 1) & 7; cq_theta(&p, 0.35);
;       int v = arr[p];
;       int r = h(v); cq_theta(&r, 0.2);
;       cq_theta(&k, -0.5);
;       return acc + cq_measure(p) + cq_measure(k); }
;     int main(int argc, char **argv) { (void)argv; return mcs(argc) + mcs(argc + 4); }
;
; THE SHAPE. The template terminals {t2, t1} reach NO store and are not measured
; upstream; their one plan declines on the divergent arm (`TmplOk` false; main on
; this module: rc 1, the diagnostic below, measured on cq-opt 716269bc). Only the
; CLONE terminal r reaches the store, through v = arr[p] -> arr -> arr[k] = 7, and
; r reads the MEASURED p, so the union is measured upstream: its first frontier
; borrows the array (and p), the fixpoint plans {t2, q}, {t1, u} and {r, v}, and
; `arr[k] = 7` is never walked.
; WHAT THIS PINS: `neverWorse` (TerminalGroups.cpp) must ask what the UNION leaves
; cut, not what the template terminals reach — here they reach no store.
; Shipped at e075f4ff as `U.Stores ⊆ U.Gates`; since R11 r7 the `GroupProbe::Cut`
; clause, which subsumes it. RED (mutant m1 of R11 r7, cq-opt 37397131): the
; template-only clause `within(T.Stores, U.Gates)` in its place — the R11 r6
; reviewer's proposal, and on this module the same verdict as round 6's 6e3615bf,
; which had no store clause and whose `T.Walked ⊆ U.Walked` holds here — gives rc 0
; with three unlocated M-A `live derived record` warnings: `cqrt_qram_store_i32(arr,
; k, 7)` never reversed, the load, h's twin and r reversed, then
; `cqrt_ry_i32(k, -0.5)` and a measure of k — per bit P(flip) = sin²θ/2 ≈ 0.115
; where the source gives 0 (the dead-record-live-across-move ruling of 2026-10-05),
; a NEW customer of bd r2j3.21 where main declines. GREEN (cq-opt e075f4ff, and
; under the `Cut` clause): the group splits and the template terminals get main's
; decline, the same line as main's.
; RETIREMENT TRIGGERS. (a) bd r2j3.21 lands (the borrowed store reversed at its last
; use, or the array-borrow retry failing loudly): re-measure main; this function may
; then lower, and the union may relax `Cut` for a store main itself reverses.
; (b) The dead-terminal spine stops declining a dead rotated rail in a classical arm
; (kMsgDivergentArm, follow-up of p3kd.13): {t2, t1} then plan (`TmplOk`), the
; `TmplOk` branch governs, and an accept must show `cqrt_qram_store_i32_unc` before
; `cqrt_ry_i32(k, -0.5)` (or the borrow retry's loud decline). Either way this
; fixture changes in the same reviewed capability change, never by reflex.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: warning
; CHECK: error: {{.*}}in function mcs i32 (i32): cq uncompute: dead chain spans divergent control-flow arms
; CHECK-NOT: internal invariant

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3
declare i32 @cq_theta_si32(i32 noundef, double noundef) #4
declare i32 @cq_measure_si32(i32 noundef) #4
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
  %3 = tail call fastcc i32 @mcs(i32 noundef %0)
  %4 = add nsw i32 %0, 4
  %5 = tail call fastcc i32 @mcs(i32 noundef %4)
  %6 = add nsw i32 %5, %3
  ret i32 %6
}

define internal fastcc i32 @mcs(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = and i32 %0, 7
  %4 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 5.000000e-01) #7
  %5 = sext i32 %4 to i64
  %6 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %5
  store i32 7, ptr %6, align 4
  %7 = lshr i32 %0, 3
  %8 = and i32 %7, 7
  %9 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 5.000000e-01) #7
  %10 = mul nsw i32 %9, 5
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 4.000000e-01) #7
  %12 = icmp sgt i32 %0, 3
  br i1 %12, label %13, label %19

13:
  %14 = lshr i32 %0, 2
  %15 = and i32 %14, 7
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 3.000000e-01) #7
  %17 = mul nsw i32 %16, 3
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 2.500000e-01) #7
  br label %19

19:
  %20 = phi i32 [ %0, %13 ], [ 0, %1 ]
  %21 = lshr i32 %0, 1
  %22 = and i32 %21, 7
  %23 = tail call i32 @cq_theta_si32(i32 noundef %22, double noundef 3.500000e-01) #7
  %24 = sext i32 %23 to i64
  %25 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %24
  %26 = load i32, ptr %25, align 4
  %27 = tail call fastcc i32 @h(i32 noundef %26)
  %28 = tail call i32 @cq_theta_si32(i32 noundef %27, double noundef 2.000000e-01) #7
  %29 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef -5.000000e-01) #7
  %30 = tail call i32 @cq_measure_si32(i32 noundef %23) #6
  %31 = add nsw i32 %30, %20
  %32 = tail call i32 @cq_measure_si32(i32 noundef %29) #6
  %33 = add nsw i32 %31, %32
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #6
  ret i32 %33
}

define internal fastcc range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0) unnamed_addr #5 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}
attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }
attributes #7 = { nomerge nounwind }
