; lowering_reject_inloop_rail_record_escape.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 round 1, finding F1). THE CONFIRMED SILENT
; MISCOMPILE of Increment 3, in its smallest form.
;
;     for (...) { if (q == 5) q = cq_phi(q, b); acc = q * 7; q += 3; }
;     return cq_measure(q) + cq_measure(acc);
;
; `%qm` (after the flatten, the loop-carried header phi) denotes the register at
; the TOP of an iteration. `clang -O1` SINKS the `mul` out of the loop — `acc` is
; loop-carried and only its last value is read — so the emitted
; `cq_template_mul_i32_hl` lands in the EXIT block, after every `cqrt_addc_i32`
; has already fired. The source says `(q0 + 3(k-1)) * 7`; the emitted stream
; computes `(q0 + 3k) * 7`. A DIFFERENT UNITARY, and every shipped gate is blind
; to it: `opt` exits 0, `opt -verify` is clean, and STRICT stage-2b free-pairing
; is clean (the rails all pair — they are just fed the wrong register state).
;
; ROOT CAUSE. Round 2 (`collapseFlattenedLoopRails`) collapsed the rail phi to its
; root mint while stating that it "deliberately does NOT re-prove tryCaseA's
; COVERAGE/CLOSURE" — but CLOSURE is what refuses a rail record whose consumer
; reads the register at a position where the register no longer holds it. Round 1
; declines this program (the `mul` is an out-of-rail consumer); round 2 did not.
;
; THE FENCE is `staleRailRecordRead` (LoopLowering.cpp): for every rail member and
; every non-member consumer, no rail-relabelling gate (`cq_theta`/Ry or a dtzb
; in-place `add`/`xor`; `cq_phi`/Rz is diagonal and does not count) may execute
; between the member's definition and the consumer's read position, without the
; member's definition re-executing in between. Here the `addc` does.
;
; The ACCEPT twin — the same program with the read at a position where the record
; IS live — is control_swap_inloop_rail_record_live.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cq_template_mul_i32_hl
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %g = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %g, %mid ], [ %q, %loop ]
  %qn = add i32 %qm, 3                                 ; in-place rail self-update
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %acc = mul i32 %qm, 7                                ; the STALE read — post-loop
  %m1 = call i32 @cq_measure_si32(i32 %qn)
  %m2 = call i32 @cq_measure_si32(i32 %acc)
  %s = add i32 %m1, %m2
  ret i32 %s
}
