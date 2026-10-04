; control_inplace_ry_inloop_leading_gate.ll — ACCEPT: shape S11 (PRD §13.3), the
; in-loop Ry arm whose ROUTED BASE is a derived value defined in the loop header
; ABOVE the compare, not the header φ itself.
;
;     for (...) { cq_theta(&r, .25); if (q > 5) cq_theta(&r, .9); }
;
; WHY IT IS ITS OWN FIXTURE. The routed base here is `%rg`, a `cq_theta` — so the
; header φ `%r` is reached only through the base's BACKWARD wire closure, which is
; exactly the reach R7's clause (b) asks about ("some member of `BaseWire` is a
; PHINode in `L`'s header"). If the closure ever stopped at the base, this fixture
; would flip to a loud `control flow inside a loop body` while the two other
; flagship shapes stayed green — which is the only way to notice.
;
; R6 per activation: the member `%r` has the user `%rg`, whose read position is in
; the header BELOW `%r`, so every `BI -> %rg` path re-enters the header and
; executes `%r` (top of block) first.
;
; The finding-L structural freeze is re-asked here on a DERIVED base: the rotated
; register is frozen by `ChainWalk::railCarriesControlledRotation`, which derives
; the rail from the emitted gate's own arg-1 use, never from a recorded pointer —
; so it survives `lowerOps` RAUWing and erasing any derived producer.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: loop:
; The leading gate is unconditional, then the region's four-call stream:
; CHECK: call void @cqrt_ry_i32(i32 %h1, double 2.5
; CHECK-NEXT: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.0
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %h_cmp)
;
; WHOLE-FILE, via the `NOROUTE` prefix rather than a trailing `CHECK-NOT` (bd
; drbq Inc 3, round-1 lens L6, F-L6-1): a `CHECK-NOT` here would have scanned
; only from the last positive match to EOF, leaving the ENTRY BLOCK — where a
; route or an unlowered rotation would be just as wrong — unchecked.
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: @cq_theta_
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %rg = call i32 @cq_theta_si32(i32 %r, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %rg, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %rg, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
