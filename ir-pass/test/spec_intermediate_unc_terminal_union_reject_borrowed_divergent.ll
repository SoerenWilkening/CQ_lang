; spec_intermediate_unc_terminal_union_reject_borrowed_divergent.ll — DECLINE, as
; main, character for character (bd test_C_libtooling-p3kd.13, R11 review round 5,
; the OPEN `!TmplOk` item). Reviewer probe r4_tmplok_false_qram, @ml alone.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int ml(int seed) {
;       int arr[8] = {0}; int q = seed; cq_theta(&q, 0.5); int p = seed + 1;
;       cq_theta(&p, 0.5); if (seed > 3) arr[q] = 7; int v = arr[p];
;       int w = (seed >> 3) & 7; cq_theta(&w, 0.3); int r = h(w); cq_theta(&r, 0.2);
;       int b = cq_measure(v); return b + cq_measure(w); }
;     int main(int argc, char **argv) { (void)argv; return ml(argc); }
;
; WHAT THIS PINS (snapshot d8c1c4bb, measured): a LOUD decline that had turned
; into an accept inside the pre-existing bd 01po.4 array-borrow class (bd
; r2j3.21). The template terminals alone decline (the conditional store at a
; superposed index sits in a divergent arm), so `TmplOk` was false and the union was
; accepted with no subset test. The clone terminal r reads the MEASURED w, so the
; union's FIRST frontier borrowed the QRAM array: its DAG never reached the
; conditional store, and rc 0 left `cqrt_qram_store_i32(arr, q, 7)` and q's prep Ry
; unreversed (stage 2b: 6 frees verified, 0 violations — blind to it). In THIS
; function that is a LEAK, not an observable wrong unitary: q is never touched again
; (R11 r6 F3 corrects r5's "dephasing" wording). Observable forms of the class,
; each with a store's index moved before a measure:
; spec_intermediate_unc_terminal_union_reject_measured_store.ll (the template group
; itself measured) and spec_intermediate_unc_terminal_union_reject_clone_store.ll
; (a store only the clone terminal's walk reaches).
; NOW (`neverWorse`, TerminalGroups.cpp): when the template plan does not emit, the
; union must leave nothing cut (`GroupProbe::Cut` empty; R11 r7-r8, which
; subsumes r5's first-DAG containment and r6's store clause). Here it cuts the
; conditional store and q's prep Ry behind it, so the group splits and the template
; terminals get main's decline.
; The accept direction of the same branch is pinned by
; spec_intermediate_unc_terminal_union_forced.ll (@fr),
; spec_intermediate_unc_terminal_union_open_root_loop.ll (@og, @le) and
; spec_intermediate_unc_terminal_union_percomp.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK-NOT: warning
; CHECK: error: {{.*}}in function ml i32 (i32): cq uncompute: dead chain spans divergent control-flow arms
; CHECK-NOT: internal invariant

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3
declare i32 @cq_theta_si32(i32 noundef, double noundef) #4
declare i32 @cq_measure_si32(i32 noundef) #4
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) #0 {
  %3 = tail call fastcc i32 @ml(i32 noundef %0)
  ret i32 %3
}

define internal fastcc i32 @ml(i32 noundef %0) unnamed_addr #1 {
  %2 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %2) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %2, i8 0, i64 32, i1 false)
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #7
  %4 = add nsw i32 %0, 1
  %5 = tail call i32 @cq_theta_si32(i32 noundef %4, double noundef 5.000000e-01) #7
  %6 = icmp sgt i32 %0, 3
  br i1 %6, label %7, label %10

7:
  %8 = sext i32 %3 to i64
  %9 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %8
  store i32 7, ptr %9, align 4
  br label %10

10:
  %11 = sext i32 %5 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %2, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = lshr i32 %0, 3
  %15 = and i32 %14, 7
  %16 = tail call i32 @cq_theta_si32(i32 noundef %15, double noundef 3.000000e-01) #7
  %17 = tail call fastcc i32 @h(i32 noundef %16)
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 2.000000e-01) #7
  %19 = tail call i32 @cq_measure_si32(i32 noundef %13) #6
  %20 = tail call i32 @cq_measure_si32(i32 noundef %16) #6
  %21 = add nsw i32 %20, %19
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %2) #6
  ret i32 %21
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
