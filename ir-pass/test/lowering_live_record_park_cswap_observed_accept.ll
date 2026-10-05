; lowering_live_record_park_cswap_observed_accept.ll — ACCEPT, M-A SILENT: a
; record whose ONLY post-gate uses are the 7.2 abort park's flag mint and the
; park `cqrt_cswap` (bd test_C_libtooling-vjdo, 2026-10-05).
;
; SOURCE (each function is the clang -O1 IR of its C, attributes trimmed):
;     int q = u; cq_theta(&q, 0.25);
;     int c = q ^ 0x55;            // R: a SIBLING record of the wire, pre-gate
;     int w = q * 2;               // THE WIRE
;     cq_theta(&w, 0.5);           // T: chained in-place Ry on the wire
;     int m = cq_measure(q * 5);   // post-gate read of the parent (exempts `q`)
;     if (c > 5) abort();          // @park_record_observed
;     if (c > 5) cq_phi(M_PI);     // @region_record_unobserved (the control)
;     return m;
;
; WHAT IT PINS. `c`'s rail is minted before `T`, never discharged, and its only
; uses after `T` are (1) the park's flag mint `cq_template_icmp_sgt_i32_hl(c, 5)`
; and (2) the Q slot of `cqrt_cswap(flag, c, grave)`. `reachesObservingSink`
; (RotationLowering.cpp) files `cqrt_cswap` as a NON-USE, so use (2) observes
; nothing. Use (1) exempts `c`: a forward template read HOPS to the flag, and
; the park writes that flag to the output tape, `cqrt_tape_write_i1(tape, flag)`,
; whose WRITTEN slot is an observing SINK. So the guard is silent.
;
; WHY THE CSWAP ROW DOES NOT DECIDE THIS (bd vjdo). `AbortParkEmit` is the only
; `cqrt_cswap` minter. Its stream is contiguous in one block, flag mint, grave
; alloc, cswap, tape write, so a walk that reaches the cswap's flag slot has
; reached the flag, whose users include that tape write. A walk that reaches the
; Q slot has reached a value the flag mint also reads, from the same side of
; the gate. The grave slot is never reached: the cswap is its only user. MEASURED
; on cq-opt mutants of this file's two functions:
;   * cswap row widened to a SINK                  -> identical stderr;
;   * tape written-slot SINK disabled              -> @park_record_observed warns;
;   * both together                                -> silent again;
;   * the park's flag mint recorded in `SpineOps`  -> @park_record_observed warns.
; So the cswap row decides only once the tape sink is gone.
;
; THE CONTROL. @region_record_unobserved is the same record with the noreturn arm
; replaced by a kickback phase arm. Its flag is minted, Rz'd, stripped and freed
; after `T`, so nothing observes `c`, and the guard warns (the F1 shape of
; lowering_reject_live_record_sibling_region_after_theta.ll). Without it a silent
; stderr could also mean the guard never ran on this module.
;
; RETIREMENT TRIGGER (L7): if `AbortParkEmit` stops writing the flag to the tape,
; adds a flag strip, or a second `cqrt_cswap` minter appears, re-derive the cswap
; row in `reachesObservingSink` before touching this file.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WARN < %t.err

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @cq_phi(double)
declare void @abort() noreturn

define i32 @park_record_observed(i32 %u) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 2.500000e-01)
  %c  = xor i32 %q, 85                                         ; R
  %w  = shl nsw i32 %q, 1                                      ; THE WIRE
  %w2 = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %y  = mul nsw i32 %q, 5
  %m  = call i32 @cq_measure_si32(i32 %y)
  %f  = icmp sgt i32 %c, 5
  br i1 %f, label %die, label %cont
die:
  call void @abort()
  unreachable
cont:
  ret i32 %m
}

define i32 @region_record_unobserved(i32 %u) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 2.500000e-01)
  %c  = xor i32 %q, 85                                         ; R
  %w  = shl nsw i32 %q, 1                                      ; THE WIRE
  %w2 = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %y  = mul nsw i32 %q, 5
  %m  = call i32 @cq_measure_si32(i32 %y)
  %f  = icmp sgt i32 %c, 5
  br i1 %f, label %arm, label %cont
arm:
  call void @cq_phi(double 0x400921FB54442D18)
  br label %cont
cont:
  ret i32 %m
}

; The park: `c` is the flag mint's operand and the cswap's Q slot, and the flag
; lands on the tape's written slot right after the cswap.
; CHECK-LABEL: define i32 @park_record_observed(
; CHECK:      %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[H]], i32 85)
; CHECK:      %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_shl_i32_hl(i32 %[[H]], i32 1)
; CHECK:      call void @cqrt_ry_i32(i32 %[[W]], double 5.000000e-01)
; CHECK:      %[[Y:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 5)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[Y]])
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[C]], i32 5)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[C]], i32 %[[G]])
; CHECK-NEXT: call i32 @cqrt_tape_write_i1(i32 %[[TAPE]], i32 %[[F]])
; CHECK-NOT:  @abort
; CHECK-NOT:  cqrt_free
; CHECK:      ret i32

; The control: the same record's flag is stripped and freed, never observed.
; CHECK-LABEL: define i32 @region_record_unobserved(
; CHECK:      %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[C2:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double 0x400921FB54442D18)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[C2]], i32 5)
; CHECK:      call void @cqrt_free(i32 %[[F2]])

; M-A speaks for the control and only for it. Functions are lowered and reported
; in module order, so the two NOTs cover the whole of stderr around the one match.
; WARN-NOT: in function park_record_observed
; WARN:     in function region_record_unobserved {{.*}}: cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: in function park_record_observed
