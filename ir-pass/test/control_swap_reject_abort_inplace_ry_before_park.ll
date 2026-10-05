; control_swap_reject_abort_inplace_ry_before_park.ll — bd test_C_libtooling-x61g
; DECLINE twin of control_swap_abort_park_inplace_ry.ll: the SAME in-place gate on
; the SAME register, moved BEFORE the park. A wrong unitary if accepted.
;
; SOURCE (clang -O1, attributes trimmed):
;     int q = u; cq_theta(&q,.5); int c = q > 5; cq_theta(&q,.3);
;     if (c) abort(); return cq_measure(q);
; -O1 keeps the compare `%3` ABOVE the gate `%4` and the branch below it.
;
; WHY IT MUST STAY LOUD. The park mints its flag at the branch, i.e. AFTER `%4`'s
; `cqrt_ry_i32(h, .3)`, so the flag would read Ry(.3)Ry(.5)|u> while the source
; aborts on Ry(.5)|u> > 5: the cswap would park the wrong component. Verify-clean.
;
; WHO REFUSES IT, AND WHY THAT IS THE RIGHT OWNER. Since x61g the park's
; sole-live-register guard follows the routed register's wire, so the live
; post-gate name `%4` (wire `%4 -> %2 = Q`) no longer stops it there; the guard
; asks only whether the park routes every live register. Whether a gate on the
; condition's wire precedes the flag mint is `reverifyCmpCondReads`'s question:
; the park records its mint `CondReadKind::Unruled`, so the post-round-2 re-ask
; exempts nothing and refuses a gate not provably after the mint, in BOTH entry
; points. Before x61g this module declined `control flow` at the park guard
; instead; its `return 0` twin (post-gate name dead) declined here already.
; MUTANT this file kills: the park's mint recorded `WireRuled` (the taint-blind
; gate `%4` is then exempted and the stale flag compiles, rc 0).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @slice(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %3 = icmp sgt i32 %2, 5
  %4 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 3.000000e-01)
  br i1 %3, label %5, label %6
5:
  tail call void @abort()
  unreachable
6:
  %7 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %7
}
