; control_inplace_ry_inloop_derived_cond.ll — ACCEPT: the in-loop Ry arm under a
; DERIVED condition (`q * 3 == 6`), bd test_C_libtooling-drbq Inc 3.
;
; THE PREDICATE IS DELIBERATELY SATISFIABLE, AND THAT IS A MEASURED REQUIREMENT,
; not a style note (PRD §13.8). Written `q * 3 == 5`, `clang -O1` proves it
; unsatisfiable under `nsw` and DELETES the region outright — leaving a fixture
; that passes because there is nothing to lower. A vacuous accept looks exactly
; like a capability.
;
; The derived condition mints template rails INSIDE the body, one per activation.
; They are on `q`'s rail, which carries NO controlled rotation (R4 guarantees it),
; so they are not frozen and still discharge in-body exactly as on the shipped
; phase path — `markIfRailLocal`'s marking is what grants the spine that
; permission, and its `onRail` classification is what the round-4 OD-A finding was
; about. If the derived-condition chain ever stopped discharging, the rolled trace
; stops matching its hand-unrolled twin.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: loop:
; the derived condition's own template, then the four-call region stream:
; CHECK: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 3)
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[T]], i32 6)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, double 9.0
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[T]], i32 6)
; the derived condition's OWN rail is uncomputed and freed in-body, per activation
; — that discharge is what `markIfRailLocal` grants and is the difference between
; the rolled trace and its hand-unrolled twin if it is ever lost:
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
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
  %t = mul i32 %q, 3
  %c = icmp eq i32 %t, 6
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
