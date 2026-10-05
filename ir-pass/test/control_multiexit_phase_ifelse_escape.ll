; control_multiexit_phase_ifelse_escape.ll — ACCEPT (bd test_C_libtooling-dm7f.5):
; a tainted if/else whose two PHASE arms each end in their OWN `ret` (hand IR; the
; shape a `musttail` arm keeps at -O1). `unifyTaintedReturns` (ReturnMerge.cpp)
; merges the two `ret`s into one `cq.retmerge` block; both return `%q`, so the
; `cq.ret` φ is folded to `%q` (`PHINode::hasConstantValue`) and the module is then
; EXACTLY control_swap_ifelse_escape.ll's diamond. `@twin` below IS that fixture's
; function, in the same module: the two CHECK blocks pin the two streams line for
; line, so the multi-exit spelling is byte-identical to the single-exit one.
;
; HAND TRACE (the stream, read top to bottom). q = Ry(0.5)|u0> = sum_x a_x |x>. The
; compare template mints f = [x > 5] into a fresh |0> ancilla. `cqrt_rz_i1(f, a)`
; kicks phase a back onto the f = 1 branch (x > 5), `cqrt_x` flips f, `cqrt_rz_i1(f,
; b)` kicks b onto the original f = 0 branch, `cqrt_x` restores f. The `_unc` strip
; recomputes [x > 5] into f, so f = [x>5] XOR [x>5] = 0 on every branch, and the one
; `cqrt_free` frees a provably-|0> rail. Result: sum_x a_x e^{i phi(x)} |x>, phi = a
; for x > 5 and b otherwise (Rz's convention adds only a global phase) — exactly
; `if (q > 5) { cq_phi(a); return q; } cq_phi(b); return q;`. q ESCAPES via `ret`:
; it is never freed (R5) and exactly one `cqrt_free` (the flag) is emitted.
;
; Before dm7f.5 this module declined `phase-class value escaping` (the OffPattern
; partition: both arms `ret` a tainted value in a function that carries a branch
; phase) — measured on main 7b4e6359.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.ll
; RUN: %filecheck %s --check-prefix=ACNT < %t.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = icmp sgt i32 %q, 5
  br i1 %k, label %then, label %else
then:
  call void @cq_phi(double %a)
  ret i32 %q
else:
  call void @cq_phi(double %b)
  ret i32 %q
}

define i32 @twin(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = icmp sgt i32 %q, 5
  br i1 %k, label %then, label %else
then:
  call void @cq_phi(double %a)
  br label %merge
else:
  call void @cq_phi(double %b)
  br label %merge
merge:
  ret i32 %q
}

; CHECK: define i32 @example(i32 %u0, double %a, double %b) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double %a), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double %b), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: ret i32 %[[H]]
; CHECK-NEXT: }
; CHECK: define i32 @twin(i32 %u0, double %a, double %b) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[TH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[TH]], double 5.000000e-01)
; CHECK-NEXT: %[[TF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[TH]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[TF]], double %a), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[TF]])
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[TF]], double %b), !cq.branchphase
; CHECK-NEXT: call void @cqrt_x(i32 %[[TF]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[TF]], i32 %[[TH]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[TF]])
; CHECK-NEXT: ret i32 %[[TH]]
; CHECK-NEXT: }

; WHOLE-FILE, PURE-NEGATIVE (no positive may enter this prefix).
; NEG-NOT: cq.retmerge
; NEG-NOT: cq.ret
; NEG-NOT: cqrt_copy
; NEG-NOT: _controlled
; NEG-NOT: cqrt_cswap
; NEG-NOT: call void @cq_phi(
; NEG-NOT: phi i32

; COUNTS, one pattern per prefix: one flag free per function, two kickbacks each.
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; ACNT-COUNT-4: call void @cqrt_rz_i1(
; ACNT-NOT:     call void @cqrt_rz_i1(
