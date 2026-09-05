; lowering_reject_inloop_rail_record_three_hops.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 3, finding F-3 — TWO stale records at
; once). A CONFIRMED silent miscompile.
;
;     for (i<2) { if (q==5) q=cq_phi(q,PI); q=cq_theta(q,-.5); q=cq_theta(q,.5); }
;     int a = cq_theta(q, .125);
;     int b = cq_theta(a, .25);
;     int c = cq_theta(b, .5);
;     return cq_measure(a) + cq_measure(b) + cq_measure(c);
;
; The extension walks a FIXPOINT, so the rail here is `%qn → %a → %b → %c` and BOTH
; `%a` and `%b` are stale records: `%a` is read after two later gates, `%b` after
; one. Only `%c` names the register the trace actually leaves behind. Measured at
; the round-2 HEAD: `opt` exit 0 and three `measure(%h)` after three in-place Rys.
;
; WHY IT IS ONE MESSAGE AND NOT TWO. `diagnose` raises a `DS_Error`
; `DiagnosticInfoUnsupported`, and `LLVMContext::diagnose` calls `exit(1)` on
; `DS_Error` — so `opt` stops at the FIRST offender and a repeat-count directive
; here would be pinning a fiction (and FileCheck parses such a directive out of
; this very comment, which is its own small lesson). The fixture therefore checks
; that the fence fires and
; that nothing lowered, which is the whole contract: a decline is not partial.
;
; THE SIBLING THAT ISOLATES THE OTHER HALF is
; lowering_reject_inloop_rail_record_theta_chain.ll (round 2, F-1): the SAME
; `%p1`/`%p2` rotation chain, but with the stale record being the chain member
; `%qn` rather than the off-chain `%p1`. That one already declined before this
; round; this one did not. The pair is why the non-transitivity argument (the walk
; need not chase gates past the first) and the record-set widening are independent
; edits — the first is about which GATES are needed, the second about which
; RECORDS are asked.
;
; `clang -O1` form (rotated 2-trip do-while, value-propagated `cq_phi(5, PI)`).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %loop

exit:                                             ; preds = %latch
  %a = call i32 @cq_theta_si32(i32 %qn, double 1.250000e-01)   ; OFF-CHAIN record #1
  %b = call i32 @cq_theta_si32(i32 %a, double 2.500000e-01)    ; OFF-CHAIN record #2
  %c = call i32 @cq_theta_si32(i32 %b, double 5.000000e-01)
  %m0 = call i32 @cq_measure_si32(i32 %a)                      ; STALE by two gates
  %m1 = call i32 @cq_measure_si32(i32 %b)                      ; STALE by one gate
  %m2 = call i32 @cq_measure_si32(i32 %c)
  %s0 = add nsw i32 %m1, %m0
  %s = add nsw i32 %m2, %s0
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
