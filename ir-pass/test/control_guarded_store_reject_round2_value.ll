; control_guarded_store_reject_round2_value.ll — bd test_C_libtooling-dm7f.3
; DECLINE (L1): a stored value in a composed guarded-store region that is
; CLASSICAL when the region is emitted (round 1) and QUANTUM after round 2.
;
; SOURCE (clang -O1, attributes, lifetime markers and TBAA trimmed; @g keeps the
; attributes the 6.5 classical-call arm needs):
;     int y = (p > 3) ? g(argc) : 7;       // a 6.5 classical-call merge
;     if (argc > 100) puts("big");
;     if (c < 3) { arr[q & 7] = y + 1; cq_phi(0.25); }
;     int v2 = arr[q & 7];
;     return cq_measure(c) + cq_measure(y) + cq_measure(v2);
;
; At round 2 `y` becomes the merge's `%out` rail, so the arm's `y + 1`, which the
; flatten hoists into the pred and runs on EVERY branch, becomes a template rail
; that nothing discharges after the guarded store: bd r2j3.9's live copy, reached
; through round 2. A composed region refuses a stored value that is tainted OR
; whose operand cone reaches a merge φ decided by a tainted (or may-turn-tainted)
; branch (`mayTaintAtRound2`; here `%13`, decided by the quantum p), with the
; quantum-value string, at the store.
; PINS (written to kill, not mutation-run in dm7f.3): dropping the `mayTaintAtRound2` conjunct from the
; stored-value clause.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: guarded store of a quantum value in a composed region under quantum control

@.str = private unnamed_addr constant [4 x i8] c"big\00", align 1

define i32 @g(i32 noundef %0) #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) {
  %3 = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) %3, i8 0, i64 32, i1 false)
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = add nsw i32 %0, 3
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01)
  %7 = add nsw i32 %0, 1
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 5.000000e-01)
  %9 = icmp sgt i32 %8, 3
  br i1 %9, label %10, label %12

10:
  %11 = tail call i32 @g(i32 noundef %0)
  br label %12

12:
  %13 = phi i32 [ %11, %10 ], [ 7, %2 ]
  %14 = icmp sgt i32 %0, 100
  br i1 %14, label %15, label %17

15:
  %16 = tail call i32 @puts(ptr noundef nonnull dereferenceable(1) @.str)
  br label %17

17:
  %18 = icmp slt i32 %4, 3
  br i1 %18, label %19, label %24

19:
  %20 = add nsw i32 %13, 1
  %21 = and i32 %6, 7
  %22 = zext nneg i32 %21 to i64
  %23 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %22
  store i32 %20, ptr %23, align 4
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %24

24:
  %25 = and i32 %6, 7
  %26 = zext nneg i32 %25 to i64
  %27 = getelementptr inbounds [8 x i32], ptr %3, i64 0, i64 %26
  %28 = load i32, ptr %27, align 4
  %29 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %30 = tail call i32 @cq_measure_si32(i32 noundef %13)
  %31 = add nsw i32 %30, %29
  %32 = tail call i32 @cq_measure_si32(i32 noundef %28)
  %33 = add nsw i32 %31, %32
  ret i32 %33
}

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare noundef i32 @puts(ptr nocapture noundef readonly)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
