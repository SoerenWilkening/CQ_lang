; control_inplace_ry_inloop_rz_reflection.ll — ACCEPT: the in-loop Ry arm with an
; Rz REFLECTION on the CONDITION register in the body (bd test_C_libtooling-drbq
; Inc 3). This is the C-reachable spelling of shape S2.
;
;     for (...) { if (q == 5) r = cq_theta(r, .9); q = cq_phi(q, .1); }
;
; TWO THINGS IT PINS THAT NO INVARIANT-CONDITION FIXTURE CAN.
;
; (1) FROM C THE CONDITION REGISTER MUST BE LOOP-VARIANT (PRD §13.1). With no gate
;     on `q` in the body, `clang -O1` LICM-hoists the compare into the preheader
;     and `condWireDisposition`'s P4 precondition (`Cond->getParent() != R.Pred`)
;     declines BEFORE any rotation clause is reached — PRD §13.2 row W, an
;     over-decline. An `Rz` on `q` is the cheapest gate that defeats the hoist,
;     and it is DIAGONAL, so `condWireDisposition` still returns `None` and the
;     P1 fence is never consulted. (An `Ry` reflection here is the Grover customer
;     and needs §13.4b — see control_inplace_ry_post_region_theta_cond.ll.)
;
; (2) The condition rail and the rotated rail are DISJOINT (R4), so the flag the
;     mint reads is the basis the source compare describes and the uncontrolled
;     `_unc` strip returns it to |0> — per activation, exactly as flat.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: loop:
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, double 9.0
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
;
; NOROUTE-NOT: call void @cqrt_cswap
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %q, %merge ]
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %ma = call i32 @cq_measure_si32(i32 %q)
  %mb = call i32 @cq_measure_si32(i32 %rm)
  %sum = add i32 %ma, %mb
  ret i32 %sum
}
