; control_multiexit_void_phase_ifelse.ll — ACCEPT (bd test_C_libtooling-dm7f.5): the
; VOID-return row. A tainted if/else whose two phase arms each end in `ret void`.
; `mergeReturnBlocks` takes the void branch (no φ: `ret void` in `cq.retmerge`), and
; the module is then the plain phase if/else diamond that `@twin` spells directly
; (the same body with one shared `ret void`); both streams are pinned line for line.
;
; HAND TRACE. q = Ry(0.5)|u0>; f = [q > 5] minted on a |0> ancilla; Rz(f, 0.25)
; phases the x > 5 branch; X f; Rz(f, 0.75) phases the x <= 5 branch; X f; the
; compare `_unc` returns f to 0 on every branch, and the one free is of a provably
; |0> rail. q is a rotated register nobody measures or returns: it stays allocated
; (R5 — never freed dirty).
;
; Before dm7f.5: `control flow under quantum control` (OffPattern; neither arm a
; value `ret`), measured on main 7b4e6359.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=RCNT < %t.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = icmp sgt i32 %q, 5
  br i1 %k, label %then, label %else
then:
  call void @cq_phi(double 2.500000e-01)
  ret void
else:
  call void @cq_phi(double 7.500000e-01)
  ret void
}

define void @twin(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = icmp sgt i32 %q, 5
  br i1 %k, label %then, label %else
then:
  call void @cq_phi(double 2.500000e-01)
  br label %m
else:
  call void @cq_phi(double 7.500000e-01)
  br label %m
m:
  ret void
}

; CHECK: define void @example(i32 %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 7.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: ret void
; CHECK-NEXT: }
; CHECK: define void @twin(i32 %u0) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[TH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[TH]], double 5.000000e-01)
; CHECK-NEXT: %[[TF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[TH]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[TF]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[TF]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[TF]], double 7.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[TF]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[TF]], i32 %[[TH]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[TF]])
; CHECK-NEXT: ret void
; CHECK-NEXT: }

; WHOLE-FILE, PURE-NEGATIVE.
; NEG-NOT: cq.retmerge
; NEG-NOT: call void @cq_phi(
; NEG-NOT: _controlled
; NEG-NOT: cqrt_free(i32 %h)

; Exactly two `ret`s in the module: one per function.
; RCNT-COUNT-2: ret void
; RCNT-NOT:     ret void
