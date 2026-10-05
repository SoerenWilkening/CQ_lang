; lowering_reject_uncompute_measured_parent_frozen_copyout.ll — DECLINE (bd
; test_C_libtooling-eqti, repro 2). The `clang -O1` IR of
;     int arr[8] = {0}; bool s = y; cq_theta(&s, 0.0); arr[s] = k;
;     bool q = x; cq_theta(&q, .25); bool t = !q; cq_theta(&t, .5);
;     int v = arr[t]; int mv = cq_measure(v);
;     cq_theta(&q, .3); return mv + cq_measure(q);
;
; The repro-1 hazard (lowering_reject_uncompute_measured_parent_frozen_taped.ll)
; with NO printf: the rotated derived copy `t` of the measured `q` indexes a local
; QRAM array, the loaded `v` is measured directly, so QRAM lowering copies `v` out
; to a kept carrier (`cqrt_copy`), and the correlation reaches `t` backward, so
; step 3b freezes the Ry-bearing `t`. The frontier retry (array + measured `q`
; borrowed) then reverse-played the frozen `t` — `ry(t,-.5); xor_i1_hl_unc(t, q, 1)`
; with `t` never freed — a q-controlled gate onto a rail left entangled with the
; copy, and `q` interferes (`ry(q, .3)`) after it: `opt` exit 0, stage 2b clean,
; q's coherence scaled exactly as in repro 1. The kept-rail adjoint fence
; (`keptRailAdjointReadsBorrowed`) refuses the retry; the decline stands verbatim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)

define i32 @slice(i1 zeroext %0, i1 zeroext %1, i32 %2) {
  %4 = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %4, i8 0, i64 32, i1 false)
  %5 = tail call zeroext i1 @cq_theta_i1(i1 zeroext %1, double 0.000000e+00)
  %6 = zext i1 %5 to i64
  %7 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %6
  store i32 %2, ptr %7, align 4
  %8 = tail call zeroext i1 @cq_theta_i1(i1 zeroext %0, double 2.500000e-01)
  %9 = xor i1 %8, true
  %10 = tail call zeroext i1 @cq_theta_i1(i1 zeroext %9, double 5.000000e-01)
  %11 = zext i1 %10 to i64
  %12 = getelementptr inbounds [8 x i32], ptr %4, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4
  %14 = tail call i32 @cq_measure_si32(i32 %13)
  %15 = tail call zeroext i1 @cq_theta_i1(i1 zeroext %8, double 3.000000e-01)
  %16 = tail call zeroext i1 @cq_measure_i1(i1 zeroext %15)
  %17 = zext i1 %16 to i32
  %18 = add nsw i32 %14, %17
  ret i32 %18
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
