; lowering_qram_guarded_store_computed_operands_discharged.ll — ACCEPT (bd
; test_C_libtooling-r2j3.1, the GUARDED-store half). In `main` nothing is
; reversed, so a guarded store `if (q < 3) arr[i & 7] = 7;` is never reversed and
; the two rails it reads were never discharged:
;   * its PATH FLAG `icmp_slt(q, 3)` — `GuardedStoreArmEmit` leaves it live so its
;     strip can ride the store's reversal LIFO, and with no reversal there was no
;     strip at all;
;   * its COMPUTED INDEX `and_i32_hl(i, 7)`.
; Both then stood as live CNOT copies of their sources across `q = cq_theta(q,
; -0.5)` (the flag is a record of `q`): `opt` exit 0 and one M-A warning.
; (A second chained `cq_theta` on `i` is left out on purpose: with the `and` inside
; the arm that module declines earlier, `operand predates a non-diagonal gate`, a
; pre-existing over-decline outside this fixture's subject.)
;
; With `isInteriorConsumer` (b″) a store is an interior consumer of every rail it
; reads outside its array slot, so the M-B partition discharges both right after
; the store, against sources that have not moved, before the chained Ry. The
; reversed (non-main) twin is slice_qram_guarded_store, where the spine owns the
; flag and the strip still follows `store_controlled_unc` — unchanged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.cqd0.ll
; DIAG-NOT: live derived record
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %f = icmp slt i32 %q, 3
  br i1 %f, label %arm, label %merge

arm:
  %ii = and i32 %i, 7
  %si = zext nneg i32 %ii to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %si
  store i32 7, ptr %g, align 4                    ; if (q < 3) arr[i & 7] = 7
  br label %merge

merge:
  %sq = sext i32 %i to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %sq
  %v = load i32, ptr %gq, align 4
  %q2 = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %v)
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %m3 = call i32 @cq_measure_si32(i32 %i)
  %s = add i32 %m, %m2
  %s2 = add i32 %s, %m3
  ret i32 %s2
}

; CHECK-LABEL: define i32 @main(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:      %[[I:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:      %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 3)
; CHECK:      %[[IDX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[I]], i32 7)
; CHECK:      call void @cqrt_qram_store_i32_controlled(i32 %[[FLAG]], i32 %[[ARR:[a-zA-Z0-9_.]+]], i32 %[[IDX]], i32 %[[VAL:[a-zA-Z0-9_.]+]])
; Both read rails are discharged against unmoved sources, before the chained Ry:
; CHECK-DAG:  call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[FLAG]], i32 %[[Q]], i32 3)
; CHECK-DAG:  call void @cqrt_free(i32 %[[FLAG]])
; CHECK-DAG:  call void @cq_template_and_i32_hl_unc(i32 %[[IDX]], i32 %[[I]], i32 7)
; CHECK-DAG:  call void @cqrt_free(i32 %[[IDX]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[Q]], double -5.000000e-01)
; Nothing reverses the store (main), and the array is never freed:
; CHECK-NOT:  cqrt_qram_store_i32_controlled_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[ARR]])
; CHECK:      ret i32
