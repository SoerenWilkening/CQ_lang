; lowering_uncompute_interior_leak_no_common_postdom.ll — LEAK PROBE (M-B
; Increment 5, bd test_C_libtooling-4p7j Rule-13 round, finding F4d). INVARIANT 7
; (the post-dominator discipline) on the two shapes where the consumers DO NOT
; RECONVERGE: an arm that ends in `unreachable`, and a function with two `ret`s.
;
; Until this fixture, invariant 7 was pinned only by the classical-if shape
; (`lowering_uncompute_interior_leak_divergent_placement.ll`), where a common
; post-dominator exists and the refusal comes from the per-gate
; `PDT.dominates(At, G)` re-proof. Here there is NO common post-dominator at all:
; LLVM's post-dominator tree hangs each exiting block off a VIRTUAL root, so
; `PDT.findNearestCommonDominator(%A, %B)` returns null, `dagInsertPoint` returns
; null, and the group leaks before any gate is examined. Same outcome, entirely
; different code path — and one that a future per-component `At` (the F3/Q2
; refinement) will change, so it needs its own pin.
;
; @interior_unreachable_arm — `%h_op` is read by a compare in `%A` (which calls
; `abort()` and ends in `unreachable`) and by another in `%B` (which returns).
; @interior_two_rets      — the same, with `%A` returning instead of aborting.
;
; In BOTH the arm-local compare rails are provably dead at the end of their own
; arm, so a per-CONNECTED-COMPONENT anchor would discharge them; the shipped
; single-`At` group cannot, and leaks. THAT IS THE SAFE DIRECTION (an unplaced
; rail is left allocated, Rule 6) and it is deliberately pinned as the CURRENT
; behaviour, not as the desired one — the refinement is tracked as follow-on
; work.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEANY < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @abort()

define i32 @interior_unreachable_arm(i32 %u0, i1 %c0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = mul i32 %q, %q
  br i1 %c0, label %A, label %B
A:
  %c = icmp ult i32 %r, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  call void @abort()
  unreachable
B:
  %c2 = icmp ult i32 %r, 20
  %z2 = zext i1 %c2 to i32
  %m2 = call i32 @cq_measure_si32(i32 %z2)
  %m3 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m2, %m3
  ret i32 %s
}

define i32 @interior_two_rets(i32 %u0, i1 %c0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = mul i32 %q, %q
  br i1 %c0, label %A, label %B
A:
  %c = icmp ult i32 %r, 10
  %z = zext i1 %c to i32
  %m = call i32 @cq_measure_si32(i32 %z)
  ret i32 %m
B:
  %c2 = icmp ult i32 %r, 20
  %z2 = zext i1 %c2 to i32
  %m2 = call i32 @cq_measure_si32(i32 %z2)
  %m3 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m2, %m3
  ret i32 %s
}

; Both functions lower their forward streams in full:
; CHECK-LABEL: define i32 @interior_unreachable_arm(
; CHECK:      %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(
; CHECK:      %[[C:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32_hl(i32 %[[OP]], i32 10)
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32(i32 %[[C]])
; CHECK-NEXT: call i32 @cqrt_measure_i32
; CHECK:      %[[C2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32_hl(i32 %[[OP]], i32 20)
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32(i32 %[[C2]])
; CHECK-LABEL: define i32 @interior_two_rets(
; CHECK:      %[[OPB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(
; CHECK:      %[[CB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32_hl(i32 %[[OPB]], i32 10)
; CHECK-NEXT: call i32 @cq_template_zext_i1_to_i32(i32 %[[CB]])

; NOTHING is adjointed and NOTHING is freed anywhere in the module. One anchor
; in the FIRST function, so the window runs anchor -> EOF and covers both (bd
; memory [filecheck-check-not-window-trap]; `tools/fixture_guard_liveness.py`
; injects its `cqrt_free` before the first `ret`, i.e. inside that window):
; NOFREEANY:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; NOFREEANY-NOT: _unc(
; NOFREEANY-NOT: call void @cqrt_free(
