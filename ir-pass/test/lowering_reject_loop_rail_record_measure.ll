; lowering_reject_loop_rail_record_measure.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 round 1, finding F1 — the PRE-EXISTING half).
;
;     for (...) { last = q; q += off; }
;     return cq_measure(last);
;
; VERIFIED PRE-EXISTING on a base build at 7ba8b2d (a worktree, CQPass built, the
; probe run): `opt` exit 0 and the same wrong stream. Filed as
; test_C_libtooling-5sva; fixed here with the same predicate round 2 now asks.
;
; NO tainted control, so this is ROUND 1 (`tryCaseA`), and it has been an accept
; since Increment 1 shipped: CLOSURE explicitly admits `isMeasureCall` and
; `ReturnInst` users of a rail value AT ANY POSITION. That admission is what makes
; this a silent miscompile — the emitted stream is
;
;     alloc; ry; loop { addc(h, 3) }; measure(h)
;
; which measures `q0 + 3k`, while the source measures `last` = `q0 + 3(k-1)`, the
; register at the TOP of the last iteration. `opt` exits 0 and the free-pairing
; gate is clean, because the shape is perfect and only the state is wrong.
;
; The ONE user that may read a rail record from outside the loop is the
; LATCH-CARRIED value — the state the register actually holds at the exit, which
; is what every shipped Grover-loop slice measures. `%q` here is the header phi,
; one `addc` short of it. Same predicate, same message, both rounds
; (`staleRailRecordRead`, LoopLowering.cpp).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %g, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double %g)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %qn = add i32 %q, 3                                  ; in-place rail self-update
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, %n
  br i1 %done, label %loop, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %q)               ; the TOP-of-last-iteration record
  ret i32 %m
}
