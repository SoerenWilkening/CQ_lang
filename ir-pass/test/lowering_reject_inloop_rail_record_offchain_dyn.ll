; lowering_reject_inloop_rail_record_offchain_dyn.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 3, finding F-3 — the DYNAMIC-bound form).
;
; The same hole as lowering_reject_inloop_rail_record_offchain_theta.ll (an
; off-chain rail record read after a later in-place Ry on the same register), on
; the hand-IR shape the rest of this family is written on: a `%n`-bounded do-while
; with ONE body rotation, rather than the `clang -O1` 2-trip form. It exists
; because those two differ in every structural way the fence could accidentally be
; keyed on — trip count constant vs. dynamic, one body gate vs. two, exit test
; `icmp eq %i, 0` vs. `icmp sgt %inext, %n` — and the predicate is supposed to be
; keyed on NONE of them: it is a pure position question about `def → gate → read`.
;
; Measured at the round-2 HEAD: `opt` exit 0, `%a` measured after `%z`'s in-place
; Ry moved the register.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
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
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %a = call i32 @cq_theta_si32(i32 %qn, double 1.250000e-01)   ; OFF-CHAIN record
  %z = call i32 @cq_theta_si32(i32 %a, double 2.500000e-01)    ; a rail gate AFTER it
  %m0 = call i32 @cq_measure_si32(i32 %a)                      ; the STALE read
  %m1 = call i32 @cq_measure_si32(i32 %z)
  %s = add i32 %m0, %m1
  ret i32 %s
}
