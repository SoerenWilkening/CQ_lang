; control_swap_reject_inloop_switch.ll — DECLINE: a FLAT tainted-scrutinee
; `switch` whose N-way phase arms reconverge at a merge that feeds the loop
; backedge (test_C_libtooling-d8jl, the `switch` sibling of the `br` in-loop
; guard). Source shape:
;
;     for (...) { switch (q) { case 1: q=cq_phi(q,a); case 2: q=cq_phi(q,b); } }
;
; BEFORE the d8jl guard this declined via the `classifySwitchRegion` G-ladder
; with the GENERIC `control flow under quantum control` (one of the structural
; off-pattern rows), giving no hint that the loop is the reason. The
; `flatControlInLoop` guard in `detectControlRegions` (run before
; `classifySwitchRegion`, mirroring the `br` Diamond/IfElse guard) declines with
; the accurate `control flow inside a loop body` message. No in-loop tainted
; `switch` is ever soundly ACCEPTED (the N-way route + merge would flatten across
; the backedge), so this only SHARPENS an already-declining path — over-declining
; is always safe (Prime Directive).
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: control flow inside a loop body under quantum control
; NEW: cq controlled lowering: control flow inside a loop body under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_cswap
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %q, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  switch i32 %q, label %merge [ i32 1, label %c1
                                i32 2, label %c2 ]
c1:
  call void @cq_phi(double %a)
  br label %merge
c2:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
