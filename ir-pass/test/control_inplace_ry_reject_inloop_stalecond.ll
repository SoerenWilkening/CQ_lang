; control_inplace_ry_reject_inloop_stalecond.ll — DECLINE (PRD §13.2 row P1): an
; in-loop Ry arm whose CONDITION wire carries a non-diagonal gate that is NOT
; provably after the region's emitted stream.
;
; `%qs = cq_theta(%q, .2)` is a SIBLING Ry on the condition register's own physical
; rail (rotation lowering RAUWs the sibling onto the ONE handle) emitted in the loop
; body BEFORE the branch — so `wireGainsNonDiagonalGate(Prov, BI, DT)` finds a gate
; that `BI` does not dominate and `condWireDisposition` returns `DeclineNow`. The
; flag minted at the branch would read a basis the source compare never described,
; the wrong arm fires, and the uncontrolled `_unc` strip cannot return the flag
; to |0>.
;
; ⚠ THE FIRST DRAFT OF THIS FIXTURE STOPPED DECLINING THE MOMENT §13.4b LANDED, and
; that is recorded rather than quietly fixed. It wrote the gate as
; `%qg = cq_theta(%q, .1)` and then compared `%qg` — which puts the gate ON THE
; COMPARE'S OWN ANCESTRY, and `findNonDiagonalWireGate` EXEMPTS on-ancestry gates by
; design (they PRODUCE the record; they cannot stale it). That shape is a correct
; ACCEPT: the mint reads exactly the basis the source's `qg` names. A gate is stale
; evidence only when it is OFF the seed's own arg-0 chain. The identical mistake was
; made and caught in the FLAT twin
; control_inplace_ry_reject_post_region_theta_stalecond.ll.
;
; THIS IS THE RED HALF OF THE §13.4b PAIR. Its green twin
; (control_inplace_ry_post_region_theta_cond.ll) has the identical arm class and a
; condition-wire gate that IS provably post-region, and Increment 3 widens P1 to
; admit exactly that one. The two must not drift: if the widening ever reached
; `DeclineNow`, this fixture is what goes green and should not.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %qs = call i32 @cq_theta_si32(i32 %q, double 2.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %qn    = call i32 @cq_phi_si32(i32 %q, double 1.000000e-01)
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  %n = call i32 @cq_measure_si32(i32 %qs)
  %t = add i32 %m, %n
  ret i32 %t
}
