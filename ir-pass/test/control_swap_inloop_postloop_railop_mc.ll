; control_swap_inloop_postloop_railop_mc.ll — ACCEPT ×2 (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 3, bookkeeping item 4). THE CROSS-FILE
; DEPENDENCY BETWEEN THE LOOP RAIL FENCE AND M-C's G6/G7 PAIR, FROM BOTH SIDES.
;
; `LoopLowering::collectRailGates` extends a loop rail forward to decide which
; gates can stale a rail record, and it deliberately does NOT follow an OFF-CHAIN
; in-place `add`/`xor` — otherwise it would refuse `mark = q; q = q + 9;
; measure(mark)`, which is correct today because that add lands on a FRESH rail
; (control_swap_inloop_postloop_railop.ll). Until this round the stated ground for
; the exclusion was that such an add "is lowered OUT of place by the M-C decision",
; as if unconditionally. THAT IS FALSE, and this file is the measurement:
;
;   @mc_plain      — `int r = q + 9; return cq_measure(r);` with NO later read of
;                    `q`. M-C (`classifyInPlaceReassignment`, ArithLowering.cpp)
;                    FIRES: the add is emitted IN PLACE as `cqrt_addc_i32(%h, 9)`,
;                    on the very register the loop rail owns.
;   @mc_then_theta — the same add with `mark = q` still read afterwards. M-C's
;                    position-aware deadness loop (G6 "no data use AFTER the op",
;                    asked POST-RAUW so every rail alias is already unified onto
;                    `%h`, and G7 "the prior use must be settled") REFUSES, and the
;                    add falls back to the out-of-place `cq_template_add_i32_hl` on
;                    a fresh rail — so `measure(%h)` for `mark` is not stale and
;                    the program keeps lowering.
;
; The exclusion is therefore sound not because M-C never fires in place, but
; because M-C refuses in exactly the case a later record read exists: the two
; dispositions are MUTUALLY EXCLUSIVE. That is a real dependency across two files
; and it is now written down at both ends (`collectRailGates` and the G6/G7 loop).
;
; HOW STRONG A TRIPWIRE THIS ACTUALLY IS — MEASURED, because the comfortable claim
; ("relax G6 and this goes red") is FALSE and was written that way first. Mutating
; G6 alone to accept leaves this file GREEN: G7 refuses the same use on its own.
; Mutating G7 alone leaves it GREEN too: G6 refuses it. Only relaxing BOTH flips
; `@mc_then_theta` to an in-place `cqrt_addc_i32` and reddens this file. So the
; two clauses are REDUNDANT on this shape, the fixture cannot catch a
; single-clause relaxation, and the loop fence's off-chain-`add` exclusion rests on
; the PAIR. Anyone relaxing either one owes `collectRailGates` a fresh derivation
; by hand — this file will not stop them.
;
; Both functions are the `clang -O1` form of their C probes (rotated 2-trip
; do-while, value-propagated `cq_phi(5, PI)` on the equality arm — Rule 9).
; The stderr pin is deliberate: these are accepts, and an accept that starts
; WARNING has changed too (owner ruling 2026-08-29).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s < %t.cqd0.ll
;
; SILENT-NOT: warning
; SILENT-NOT: error
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; M-C FIRES IN PLACE — no later read of the pre-add register.
; CHECK-LABEL: define i32 @mc_plain
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_addc_i32(i32 %[[H]], i32 9)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
define i32 @mc_plain() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %loop

exit:                                             ; preds = %latch
  %r = add nsw i32 %qn, 9
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m

loop:                                             ; preds = %entry, %latch
  %q = phi i32 [ %q0, %entry ], [ %qn, %latch ]
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %arm, label %latch

arm:                                              ; preds = %loop
  call void @cq_phi(double 0x400921FB54442D18)
  br label %latch

latch:                                            ; preds = %arm, %loop
  %qh = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %qn = call i32 @cq_theta_si32(i32 %qh, double 5.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i, 0
  br i1 %done, label %loop, label %exit
}

; M-C REFUSES (G6 and G7 both) — `%qn` is still read after the add, so it goes OUT
; of place onto a fresh rail and the record read of `%h` stays sound.
; CHECK-LABEL: define i32 @mc_then_theta
; CHECK:     %[[H2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H2]], i32 9)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Z]], double 2.500000e-01)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Z]])
define i32 @mc_then_theta() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %loop

exit:                                             ; preds = %latch
  %r = add nsw i32 %qn, 9
  %t = call i32 @cq_theta_si32(i32 %r, double 2.500000e-01)
  %m0 = call i32 @cq_measure_si32(i32 %qn)
  %m1 = call i32 @cq_measure_si32(i32 %t)
  %s = add nsw i32 %m1, %m0
  ret i32 %s

loop:                                             ; preds = %entry, %latch
  %q = phi i32 [ %q0, %entry ], [ %qn, %latch ]
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %arm, label %latch

arm:                                              ; preds = %loop
  call void @cq_phi(double 0x400921FB54442D18)
  br label %latch

latch:                                            ; preds = %arm, %loop
  %qh = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %qn = call i32 @cq_theta_si32(i32 %qh, double 5.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i, 0
  br i1 %done, label %loop, label %exit
}
