; spec_stateprep_runtime_seed_side_door.ll — ACCEPT (bd test_C_libtooling-z0re,
; OWNER RULING 2026-09-28 option (a)): THE SPEC-CLASSICAL SIDE DOOR, pinned to the
; SAME stream as its hand-inlined twin `spec_stateprep_runtime_seed_side_door_twin.ll`.
;
;     int t = h(q, m);                 // Phase-6 site; the clone proves h classical
;     int r = t; if (q2 > 3) r = cq_theta(t, .2);        // d88e probe l12C
;
; THE SIDE DOOR bd z0re NAMED. At round 1 `t = h(q, m)` is CONSERVATIVELY tainted
; (its first argument is `q`), so `classifyArms` classifies the arm as an IN-PLACE
; controlled Ry on the "register" `t` — F1/F2 are never asked — and after
; `specialize()` scrubs `t` (the clone reads `a` only in a branch and returns
; `k + 1`), `lowerRotations` sees `Chained = false` and emits a controlled state
; prep seeded by the RUNTIME value `t`. Until 2026-09-28 the direct path refused the
; very same shape at F1 (literal-only seed), so the side door compiled a shape the
; owner had scoped OUT. The owner took option (a): the direct path now ACCEPTS the
; runtime seed, so the twin and the side door agree — this file and its twin carry
; the SAME CHECK block, stream for stream.
;
; ⚠ HAND-WRITTEN IR, and why: since bd vsfp the dead-argument drop replaces an
; argument the callee does not read, and the fenv pre-pass erases the `volatile int
; z = a;` spelling first (`tests/e2e/spec_lift_classical_lib.c`'s header), so from
; C the call becomes `h(0, m)` and the module IS the twin. A callee that READS its
; argument and still returns classical needs a read that survives `clang -O1` and
; the fenv stages yet dies in the clone — only hand IR provides it: the BRANCH-ONLY
; read below (the d88e `lowering_*_spec_scrubbed_*` idiom).
;
; On the ORACLE (main 9a230646) this module ACCEPTS with this very stream (the side
; door is pre-existing); its twin DECLINES there at F1. MEASURED.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = getelementptr inbounds i8, ptr %1, i64 16
  %7 = load ptr, ptr %6, align 8
  %8 = tail call i32 @atoi(ptr nocapture noundef %7)
  %9 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01)
  %10 = tail call i32 @h(i32 noundef %9, i32 noundef %5)
  %11 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef 3.000000e-01)
  %12 = icmp sgt i32 %11, 3
  br i1 %12, label %13, label %15
13:
  %14 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 2.000000e-01)
  br label %15
15:
  %16 = phi i32 [ %14, %13 ], [ %10, %2 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %16)
  %18 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %19 = add nsw i32 %18, %17
  ret i32 %19
}

declare i32 @atoi(ptr nocapture noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @h(i32 noundef %0, i32 noundef %1) #0 {
  %c = icmp eq i32 %0, 0   ; a BRANCH-ONLY read keeps this parameter LIVE (bd vsfp r2)
  br i1 %c, label %arm, label %join
arm:
  br label %join
join:
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) }

; The SAME block as the twin's (m's register `%9` is allocated and rotated; the
; seed is whatever the specialized call returns, `k + 1` at run time).
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:      %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %8)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q2]], double 3.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q2]], i32 3)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[T:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q2]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q2]])
