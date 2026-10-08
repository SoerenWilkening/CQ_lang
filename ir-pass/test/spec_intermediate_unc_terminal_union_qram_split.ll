; spec_intermediate_unc_terminal_union_qram_split.ll — ACCEPT, SPLIT (bd
; test_C_libtooling-p3kd.13, R11 review round 4, F-A): the terminal union's
; "never worse" test covers what a plan REVERSE-PLAYS, not only what it frees.
; Reviewer probe q1: the bd sxuk shape (a non-main QRAM local array, a copy-out
; measured load) plus an unrelated clone terminal over a measured w.
;
; SOURCE (`clang -O1` IR below):
;     __attribute__((noinline)) static int h(int a) { return a * 3 + 1; }
;     __attribute__((noinline)) static int ml(int seed) {
;       int arr[8] = {0}; int q = seed; cq_theta(&q, 0.5); int p = seed + 1;
;       cq_theta(&p, 0.5); arr[q] = 7; int v = arr[p];
;       int w = (seed >> 3) & 7; cq_theta(&w, 0.3); int r = h(w); cq_theta(&r, 0.2);
;       int b = cq_measure(v); return b + cq_measure(w); }
;     int main(void) { return ml(0); }
;
; THE DEFECT THIS PINS (snapshots 12262d16, 0225a9f9). The clone terminal r reads
; the MEASURED w, so the union goes measured-upstream and its frontier BORROWS the
; QRAM array root: the template part's `cqrt_qram_store_i32_unc` and the q/p
; prep-Ry adjoints drop out of the plan. The never-worse test compared FREED rails
; only, and the array, q and p are birth-frozen (reverse-played, never freed), so it
; passed — the array kept 7 at a superposed index ONLY because h(w) joined the
; group (bd sxuk's dephasing disposition; stage 2b cannot see it).
; NOW the test also requires every gate the template-only plan reverse-plays: the
; union is refused, the template terminals plan exactly as main (store `_unc`, load
; `_unc`, both prep Rys undone), and the clone terminal reverses on its own.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=NOERR --allow-empty < %t.err
; RUN: %filecheck %s < %t.ll

; NOERR-NOT: error

; CHECK-LABEL: define internal fastcc i32 @ml(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK-NEXT: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 1)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 5.000000e-01)
; CHECK-NEXT: %[[V7:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[Q]], i32 %[[V7]])
; CHECK-NEXT: %[[L:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]], i32 %[[P]])
; CHECK-NEXT: %[[W:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[W]], double 3.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = tail call fastcc i32 @__cq_q_h_1(i32 noundef %[[W]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double -2.000000e-01)
; CHECK-NEXT: call fastcc void @__cq_q_h_1_unc(i32 %[[R]], i32 %[[W]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[R]])
; The template part, exactly as main:
; CHECK-NEXT: %[[RET:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[L]], i32 %[[RET]])
; CHECK-NEXT: call void @cqrt_qram_load_i32_unc(i32 %[[L]], i32 %[[ARR]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[L]])
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[Q]], i32 %[[V7]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double -5.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[RET]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[W]])
; The kept Q, P, V7 and ARR are never freed after the measures (R11 r5 F2(a)):
; CHECK-NOT:  call void @cqrt_free
; CHECK:      ret i32

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg) #3
declare i32 @cq_theta_si32(i32 noundef, double noundef) #4
declare i32 @cq_measure_si32(i32 noundef) #4
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

define i32 @main() #0 {
  %1 = tail call fastcc i32 @ml()
  ret i32 %1
}

define internal fastcc i32 @ml() unnamed_addr #1 {
  %1 = alloca [8 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %1) #6
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %1, i8 0, i64 32, i1 false)
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #7
  %3 = tail call i32 @cq_theta_si32(i32 noundef 1, double noundef 5.000000e-01) #7
  %4 = sext i32 %2 to i64
  %5 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %4
  store i32 7, ptr %5, align 4
  %6 = sext i32 %3 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %1, i64 0, i64 %6
  %8 = load i32, ptr %7, align 4
  %9 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #7
  %10 = tail call fastcc i32 @h(i32 noundef %9)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.000000e-01) #7
  %12 = tail call i32 @cq_measure_si32(i32 noundef %8) #6
  %13 = tail call i32 @cq_measure_si32(i32 noundef %9) #6
  %14 = add nsw i32 %13, %12
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %1) #6
  ret i32 %14
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
