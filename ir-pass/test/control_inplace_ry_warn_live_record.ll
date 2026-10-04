; control_inplace_ry_warn_live_record.ll — the M-A LIVE-RECORD guard sees the
; CONTROLLED spelling of an in-place Ry (bd test_C_libtooling-drbq Inc 1, the
; walker audit).
;
;     int r = 0; cq_theta(&r,.3); int rec = r * 2;  // a DEAD derived record of r
;     if (q > 5) cq_theta(&r, .9);               // a controlled Ry on r's wire
;
; `warnLiveRecordRotations` reports a non-diagonal gate standing over a live
; derived record of its own wire: the record's rail is never restored, so it
; DEPHASES the rotation's answer. Since bd lyyf it is a `DS_Warning` — the owner
; ruled the user's circuit is the user's — so the module LOWERS and `opt` exits 0.
;
; WHAT THIS FIXTURE IS ACTUALLY FOR. The guard re-checks its candidates
; structurally as `arg_size() == 2 && starts_with("cqrt_ry_")`, and a controlled
; rotation is THREE args with the rotated wire at ARG 1 (arg 0 is the flag). It
; therefore SKIPPED every controlled Ry, silently, while that gate relabels a user
; register exactly as the uncontrolled one does — the widened-one-set-not-the-other
; hole (the 8h7d.5 F-1/F-3 lesson). Reading arg 0 instead would have been worse:
; the whole guard would have run against the FLAG. Both spellings are admitted and
; each reads its own wire slot.
;
; MEASURED: with the pre-audit structural test this module lowered SILENTLY.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r   = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %rec = mul i32 %r, 2
  %c   = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}

; WARN: warning{{.*}}non-diagonal gate over a live derived record

; …and it is a WARNING, so the region still lowers to the in-place stream.
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:     call i32 @cq_template_mul_i32_hl(i32 %[[R]], i32 2)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl
; CHECK:     call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[F]])
