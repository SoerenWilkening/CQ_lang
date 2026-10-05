; control_guarded_store_ifelse_reject_inarm_index_later_ry.ll — bd
; test_C_libtooling-dm7f.3 DECLINE, the bd 01po.7 neighbour of
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
; The only difference from the accepted full reproducer is that the arms compute
; DIFFERENT indices, so `-O1` leaves `q & 7` (`%10`) inside the true arm instead of
; hoisting it into the pred. The stale-record guard runs before detection, sees
; an index record of q under tainted control and a later Ry on q, and declines
; `operand predates a non-diagonal gate` at `%10`. The region emitter would hoist
; `%10` into the pred and discharge it right after its store (the stream the full
; reproducer shows), so this protects bookkeeping rather than the unitary.
; A plain one-armed guarded store with the same in-arm index and later Ry on q
; declines identically on main 7b4e6359; dm7f.3 does not change that guard.
; On main this module declined earlier, at the carve (`cq taint escape: tainted
; value reaches an unsupported instruction`, the true arm's gep).
;
; RETIREMENT TRIGGER: bd 01po.7 (agent B's late re-check route for the
; stale-record guard). When it lands this module should ACCEPT with the full
; reproducer's stream (an extra `lshr` rail in the else arm's index chain,
; discharged after its store). Re-derive that stream and turn this file into an
; accept then; do not delete it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

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
