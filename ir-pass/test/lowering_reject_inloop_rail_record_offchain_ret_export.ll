; lowering_reject_inloop_rail_record_offchain_ret_export.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 3, finding F-3 — the ESCAPE read).
; A CONFIRMED silent miscompile.
;
;     static int inner(int u) {
;       int q = u; cq_theta(&q, .5);
;       for (i<2) { if (q==5) cq_phi(PI); cq_theta(&q,-.5); cq_theta(&q,.5); }
;       int a = q; cq_theta(&a, .125);    /* OFF-CHAIN record */
;       int b = a; cq_theta(&b, .25);     /* a rail gate AFTER it */
;       (void)cq_measure(b);
;       return a;                         /* the STALE read is a `ret`, not a measure */
;     }
;
; WHY THE `ret` NEEDS ITS OWN FIXTURE. The uncovered surface F-3 opened is exactly
; `cq_measure` and `ret`, and for a reason worth restating: every OTHER consumer of
; a stale rail record is already owned by a different loud guard — a value-op read
; declines at `declineStaleRecordOps` ("operand predates a non-diagonal gate"), a
; tainted-condition read at `ArmClassify`'s stale-condition walk. `cq_measure` and
; `ret` are the two consumers no other owner examines, because to them a handle is
; just a handle. `tryCaseA`'s CLOSURE and round 2's collapse both ADMIT them by
; construction, so if this fence does not name them nothing does (Rule 14 — one
; predicate, not a neighbour's coverage).
;
; Measured at the round-2 HEAD: `opt` exit 0, and `inner` emitted
; `cqrt_ry_i32(%h,.125); cqrt_ry_i32(%h,.25); measure(%h)` while returning the
; name of the PRE-`%b` state to a caller that then uses it.
;
; `clang -O1` form (the C's `noinline static` is internalized and its argument
; constant-folded away; the loop body is the same rotated 2-trip do-while).
;
; bd p3kd.21 (2026-10-14): THE `ret` CONSUMER'S PIN. The sibling
; lowering_reject_inloop_rail_record_offchain_ret.ll now compiles `inner` at its
; call site (a gate subroutine), which moves its stale read onto `main`'s `and`.
; Here `inner` is an EXPORT with no caller, so its stale read is still the `ret`,
; and only this fence names it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @inner() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %loop

exit:                                             ; preds = %latch
  %a = call i32 @cq_theta_si32(i32 %qn, double 1.250000e-01)   ; OFF-CHAIN record
  %b = call i32 @cq_theta_si32(i32 %a, double 2.500000e-01)    ; a rail gate AFTER it
  %m1 = call i32 @cq_measure_si32(i32 %b)
  ret i32 %a                                                   ; the STALE read

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
