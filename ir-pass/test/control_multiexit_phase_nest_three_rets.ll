; control_multiexit_phase_nest_three_rets.ll — ACCEPT (bd test_C_libtooling-dm7f.5):
; THREE `ret`s, one of them INSIDE a depth-2 tainted nest:
;     if (q > 5) { cq_phi(.25); if (q < 9) { cq_phi(.75); return q; } return q; }
;     return q;
; spelled with a `ret` per exit (hand IR). `unifyTaintedReturns` merges the three
; `ret`s into `cq.retmerge`, folds the all-`%q` φ to `%q`, and folds the two EMPTY
; former-`ret` blocks (`%early`, `%out`) into their predecessors with SimplifyCFG's
; `TryToSimplifyUncondBranchFromEmptyBlock` — neither predecessor already reaches the
; merge, so no conditional branch gains two identical successors. The result is
; control_phase_nest_kickback.ll's nest (`@twin`, the same body returning `%q`), and
; the two streams are pinned line for line. On main 7b4e6359 `@example` declined
; `nested control flow under quantum control` (measured).
;
; HAND TRACE. q = Ry(0.5)|u0>. f1 = [x > 5]; Rz(f1, .25) phases x > 5. f2 = [x < 9]
; is minted unconditionally (a pure compare, reversed below). g = |0>; Toffoli(f1,
; f2, g) makes g = [5 < x < 9]; Rz(g, .75) phases exactly that band; the second
; Toffoli returns g to 0 and g is freed. The f2 strip, then the f1 strip, return both
; flags to 0 on every branch before their frees. Net: sum_x a_x e^{i(.25[x>5] +
; .75[5<x<9])} |x> (up to Rz's global phase), q returned live (never freed). Three
; frees, all of provably-|0> ancillas.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=RCNT < %t.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %out
mid:
  call void @cq_phi(double 2.500000e-01)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %inner, label %early
inner:
  call void @cq_phi(double 7.500000e-01)
  ret i32 %q
early:
  ret i32 %q
out:
  ret i32 %q
}

define i32 @twin(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %m
mid:
  call void @cq_phi(double 2.500000e-01)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %inner, label %m
inner:
  call void @cq_phi(double 7.500000e-01)
  br label %m
m:
  ret i32 %q
}

; CHECK: define i32 @example(i32 %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F1]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H]], i32 9)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[G]], double 7.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[F1]], i32 %[[F2]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: ret i32 %[[H]]
; CHECK-NEXT: }
; CHECK: define i32 @twin(i32 %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[TH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[TH]], double 5.000000e-01)
; CHECK-NEXT: %[[TF1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[TH]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[TF1]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: %[[TF2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[TH]], i32 9)
; CHECK-NEXT: %[[TG:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[TF1]], i32 %[[TF2]], i32 %[[TG]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[TG]], double 7.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[TF1]], i32 %[[TF2]], i32 %[[TG]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[TG]])
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[TF2]], i32 %[[TH]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[TF2]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[TF1]], i32 %[[TH]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[TF1]])
; CHECK-NEXT: ret i32 %[[TH]]
; CHECK-NEXT: }

; WHOLE-FILE, PURE-NEGATIVE.
; NEG-NOT: cq.retmerge
; NEG-NOT: call void @cq_phi(
; NEG-NOT: _controlled
; NEG-NOT: phi i32

; Exactly one `ret` per function.
; RCNT-COUNT-2: ret i32
; RCNT-NOT:     ret i32
