; control_angle_select_ry_runtime_base.ll — ACCEPT (bd test_C_libtooling-z0re,
; OWNER RULING 2026-09-28 option (a)): the Ry-stem angle select on an UNTAINTED
; RUNTIME base — controlled STATE PREP by difference on a fresh rail.
;
;     int t = m + 1; int r;
;     if (q > 3) { r = t; cq_theta(&r, .7); } else { r = t; cq_theta(&r, .2); }  // probe a01T
;     return cq_measure(r) + cq_measure(q) + t;                   // `t` read after
;
; `-O1` sinks the two thetas into ONE `cq_theta(%t, select(%c, .7, .2))`. S3 now
; admits a runtime untainted base (`isRuntimeStatePrepSeed`, Ry stem only) and the
; emitter lowers it by difference exactly as it lowers a register base — the
; unconditional twin `cq_theta(%t, B)` becomes a SOURCE (`alloc(t); ry(h, B)`), and
; the consumer becomes `ry_controlled(f, h, A−B)`:
;   f=0: Ry(B)|t⟩            f=1: Ry(B)·Ry(A−B)|t⟩ = Ry(A)|t⟩
; which is the source's if/else on ONE rail prepared UNCONDITIONALLY at |t⟩ (the
; theta runs on both branches; only its angle is conditional). S1's constant-arms
; and 2^-40 rounding fences are unchanged: `0.7 − 0.2` rounds to
; 0x3FDFFFFFFFFFFFFF (0.49999999999999994) — the same double `clang` gives the
; manual twin's `0.7 - 0.2`.
;
; The trailing `+ t` pins the SKIP of S7's rail prong / S8 / S9 for an untainted
; base: `t` is a CLASSICAL value read after the gate, not a stale record of the
; rotated rail (which is minted by the twin and has no pre-region name). Asking
; S9 of `railWireClosure(%t)` would have declined `stale rail record read past a
; controlled Ry` on it.
;
; On the ORACLE this module DECLINES `rotation angle under quantum control` (S3's
; untainted-base return). A LITERAL base still does, and why is in S3's comment
; and in `control_angle_select_reject_literal_base_offwire_fold.ll` (bd drbq.13).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %m) {
entry:
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %t = add nsw i32 %m, 1
  %c = icmp sgt i32 %q, 3
  %ang = select i1 %c, double 0x3FE6666666666666, double 2.000000e-01
  %r = call i32 @cq_theta_si32(i32 %t, double %ang)
  %mr = call i32 @cq_measure_si32(i32 %r)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %s1 = add nsw i32 %mq, %mr
  %s2 = add nsw i32 %s1, %t
  ret i32 %s2
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %m)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %t = add nsw i32 %m, 1
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %t)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 0x3FDFFFFFFFFFFFFF)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK:      add nsw i32 %{{[a-zA-Z0-9_.]+}}, %t

; NEG-NOT: = select
; NEG-NOT: cq_theta_
; NEG-NOT: cq_template_add

; ACNT-COUNT-2: call i32 @cqrt_alloc_i32(
; ACNT-NOT:     call i32 @cqrt_alloc_i32(
