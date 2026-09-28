; spec_angle_select_runtime_base_side_door.ll — ACCEPT (bd test_C_libtooling-z0re,
; OWNER RULING 2026-09-28 option (a)): the SPEC-CLASSICAL SIDE DOOR into the Ry-stem
; angle select, pinned to the SAME stream as its hand-inlined twin
; `spec_angle_select_runtime_base_side_door_twin.ll`.
;
;     int t = h(q, m); int r;
;     if (q > 3) r = cq_theta(t, .7); else r = cq_theta(t, .2);   // d88e probe a01C
;
; `-O1` sinks the two thetas into one reading an angle select. At round 1 `t` is a
; conservatively-tainted Phase-6 site, so `classifyAngleSelect` proves the TAINTED-base
; Ry stem (S8/S9 over `t`'s wire); after `specialize()` scrubs `t`, `lowerRotations`
; lowers the emitter's unconditional twin as a SOURCE — `alloc(t); ry(h, .2)` — and
; the consumer as `ry_controlled(f, h, .7 - .2)`. The hand-inlined twin used to
; DECLINE `rotation angle` at S3's untainted-base return (no reason written there);
; under the ruling S3 admits the runtime base and the two agree stream for stream.
; `0x3FDFFFFFFFFFFFFF` is `fl(0.7 - 0.2)`, the difference `clang` gives the manual
; twin, inside S1's constant-arms rounding fence.
;
; ⚠ HAND-WRITTEN IR for the reason `spec_stateprep_runtime_seed_side_door.ll` gives
; (from C the vsfp dead-argument drop makes the call `h(0, m)` and the module IS the
; twin): the BRANCH-ONLY read keeps `a` live into the clone.
;
; On the ORACLE (main 9a230646) this module ACCEPTS with this stream; its twin
; DECLINES there. MEASURED.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01)
  %7 = tail call i32 @h(i32 noundef %6, i32 noundef %5)
  %8 = icmp sgt i32 %6, 3
  %9 = select i1 %8, double 0x3FE6666666666666, double 2.000000e-01
  %10 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef %9)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %6)
  %13 = add nsw i32 %12, %11
  ret i32 %13
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

; CHECK-LABEL: define i32 @main(
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[T:[a-zA-Z0-9_.]+]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FDFFFFFFFFFFFFF)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
