; control_multiexit_round2_onward_phase.ll — ACCEPT (bd test_C_libtooling-dm7f.5), the
; L1 ROUND-2 row. `%c2` reads the 6.5 classical-call merge `%y`, which is CLASSICAL
; until round 1 emits it as the `%out` rail, so the multi-exit `br %c2` is tainted
; ONLY at round 2 (`detectAndLowerOnwardControl`). The early normalization slot sees
; a classical `br` and (correctly) leaves the function alone; the round-2 slot, beside
; the round-2 `peelIndependentMergePhis`, merges the two `ret %y`s before the round-2
; detection, which then lowers the onward branch phase exactly as for `@twin`
; (control_classical_call_arm_accept_onward_ctl_phase.ll's shape, returning `%y`).
; Both streams are pinned line for line. On main 7b4e6359 `@example` declined
; `phase-class value escaping under quantum control` at round 2 (measured).
;
; HAND TRACE. q = Ry(0.5)|u0>; r = f(a) = a + 100 runs once, classically (hoisted);
; f1 = [x > 3]; out = |0>, XOR-copied from alloc(r) under f1 and from alloc(5) under
; NOT f1, so out = (x > 3 ? a+100 : 5) on every branch; f1 stripped and freed. Round
; 2: f2 = [out > 7]; Rz(f2, .25) phases the branches with out > 7; f2 stripped and
; freed. `out` escapes via `ret`. That is `y = q>3 ? f(a) : 5; if (y > 7) cq_phi(.25);
; return y;` — whichever `ret` the source wrote.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @example(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %c2 = icmp sgt i32 %y, 7
  br i1 %c2, label %ph, label %m2
ph:
  call void @cq_phi(double 0.25)
  ret i32 %y
m2:
  ret i32 %y
}

define i32 @twin(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %c2 = icmp sgt i32 %y, 7
  br i1 %c2, label %ph, label %m2
ph:
  call void @cq_phi(double 0.25)
  br label %m2
m2:
  ret i32 %y
}

attributes #0 = { nounwind willreturn memory(none) }

; CHECK: define i32 @example(i32 %u0, i32 %a) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @f(i32 %a)
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[S1]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[S2]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[OUT]], i32 7)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[OUT]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: ret i32 %[[OUT]]
; CHECK-NEXT: }
; CHECK: define i32 @twin(i32 %u0, i32 %a) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[TH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[TH]], double 5.000000e-01)
; CHECK-NEXT: %[[TR:[a-zA-Z0-9_.]+]] = call i32 @f(i32 %a)
; CHECK-NEXT: %[[TF1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[TH]], i32 3)
; CHECK-NEXT: %[[TOUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: %[[TS1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[TR]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[TF1]], i32 %[[TS1]], i32 %[[TOUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[TF1]])
; CHECK-NEXT: %[[TS2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 5)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[TF1]], i32 %[[TS2]], i32 %[[TOUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[TF1]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[TF1]], i32 %[[TH]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[TF1]])
; CHECK-NEXT: %[[TF2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[TOUT]], i32 7)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[TF2]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[TF2]], i32 %[[TOUT]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[TF2]])
; CHECK-NEXT: ret i32 %[[TOUT]]
; CHECK-NEXT: }

; NEG-NOT: cq.retmerge
; NEG-NOT: call void @cq_phi(
; NEG-NOT: phi i32
