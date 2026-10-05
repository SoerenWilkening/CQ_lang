; control_multiexit_classical_tail_recursion.ll — ACCEPT (bd test_C_libtooling-dm7f.5,
; review round 1 F2). A CLASSICAL tail recursion (`if (n > 0) musttail return
; example(n - 1, u);`) sits BEFORE the quantum part; the tainted `br %c` that needs the
; merge reaches only `%a`'s and `%b`'s `ret`s. The first build asked the `musttail`
; refusal about EVERY `ret` of the function, so this valid module was refused with the
; wrong words, `recursive musttail call under quantum control` — that call is under no
; quantum control. `unifyTaintedReturns` now merges, and asks the refusal about, only
; the `ret`s a needing branch reaches: `%rec` keeps its `musttail` and its own `ret`,
; `%a`/`%b` merge, and the module is `@twin` (the same body with the quantum `ret`s
; merged by hand). Both streams are pinned line for line.
;
; HAND TRACE (quant path). q = Ry(0.5)|u>; f = [x > 5]; Rz(f, .25) phases x > 5; X f;
; Rz(f, .75) phases x <= 5; X f; the compare `_unc` returns f to 0 and frees it. The
; recursion path is classical and untouched; each activation that reaches `%quant`
; allocates its own q (a void function: q stays allocated, never freed dirty).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)

define void @example(i32 %n, i32 %u) {
entry:
  %k = icmp sgt i32 %n, 0
  br i1 %k, label %rec, label %quant
rec:
  %n1 = sub i32 %n, 1
  musttail call void @example(i32 %n1, i32 %u)
  ret void
quant:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %b
a:
  call void @cq_phi(double 2.500000e-01)
  ret void
b:
  call void @cq_phi(double 7.500000e-01)
  ret void
}

define void @twin(i32 %n, i32 %u) {
entry:
  %k = icmp sgt i32 %n, 0
  br i1 %k, label %rec, label %quant
rec:
  %n1 = sub i32 %n, 1
  musttail call void @twin(i32 %n1, i32 %u)
  ret void
quant:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %b
a:
  call void @cq_phi(double 2.500000e-01)
  br label %m
b:
  call void @cq_phi(double 7.500000e-01)
  br label %m
m:
  ret void
}

; CHECK: define void @example(i32 %n, i32 %u) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %k = icmp sgt i32 %n, 0
; CHECK-NEXT: br i1 %k, label %rec, label %quant
; CHECK-EMPTY:
; CHECK-NEXT: rec:
; CHECK-NEXT: %n1 = sub i32 %n, 1
; CHECK-NEXT: musttail call void @example(i32 %n1, i32 %u)
; CHECK-NEXT: ret void
; CHECK-EMPTY:
; CHECK-NEXT: quant:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
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
; CHECK: define void @twin(i32 %n, i32 %u) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %k = icmp sgt i32 %n, 0
; CHECK-NEXT: br i1 %k, label %rec, label %quant
; CHECK-EMPTY:
; CHECK-NEXT: rec:
; CHECK-NEXT: %n1 = sub i32 %n, 1
; CHECK-NEXT: musttail call void @twin(i32 %n1, i32 %u)
; CHECK-NEXT: ret void
; CHECK-EMPTY:
; CHECK-NEXT: quant:
; CHECK-NEXT: %[[TH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
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

; NEG-NOT: cq.retmerge
; NEG-NOT: call void @cq_phi(
