; control_multiexit_classical_exit_phase.ll — ACCEPT (bd test_C_libtooling-dm7f.5): a
; CLASSICAL-condition exit mixed with a tainted one,
;     if (k) return q;  if (q > 5) { cq_phi(.25); return q; }  return q;
; with a `ret` per exit (hand IR).
;
; HISTORY, and a decline -> accept flip. This file was
; control_multiexit_reject_classical_exit_phase.ll: the first build merged ALL three
; `ret`s, so the phase triangle's merge got a third, outside predecessor (the classical
; `%k` edge) and the kickback classifier left it to the OffPattern partition, which
; declined `phase-class value escaping under quantum control` (main 7b4e6359 declined
; the un-merged module with the same string). Review round 1 F2 restricted the merge to
; the `ret`s a NEEDING terminator reaches: `br %c` reaches only `%a` and `%b`, so the
; classical `%early` exit keeps its own `ret`, the merge is the region's alone, and the
; triangle lowers by kickback. The result is `@twin`, the same program with the two
; quantum exits merged by hand and the classical exit left alone; both streams are
; pinned line for line. The plain-C spelling is not this CFG (`clang -O1` fuses the two
; branches into `br (k | q < 6)` and declines `control flow`, measured on main).
;
; SEMANTIC EVIDENCE (R10), HAND TRACE. q = Ry(0.5)|u0>. On the classical `k` path the
; function returns q untouched (no gate). Otherwise f = [x > 5] is minted, Rz(f, .25)
; phases the x > 5 branch, the compare `_unc` returns f to 0 on every branch and the
; one `cqrt_free` frees it while provably |0>, and q is returned live (never freed).
; That is the program's unitary on each classical path. The OffPattern `phase-class
; value escaping` row this file used to pin is now pinned by the single-`ret` module
; control_swap_reject_phase_value_escaping_outside_pred.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)

define i32 @example(i32 %u0, i1 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %k, label %early, label %cont
early:
  ret i32 %q
cont:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %b
a:
  call void @cq_phi(double 2.500000e-01)
  ret i32 %q
b:
  ret i32 %q
}

define i32 @twin(i32 %u0, i1 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br i1 %k, label %early, label %cont
early:
  ret i32 %q
cont:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %m
a:
  call void @cq_phi(double 2.500000e-01)
  br label %m
m:
  ret i32 %q
}

; CHECK: define i32 @example(i32 %u0, i1 %k) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: br i1 %k, label %early, label %cont
; CHECK-EMPTY:
; CHECK-NEXT: early:
; CHECK-NEXT: ret i32 %[[H]]
; CHECK-EMPTY:
; CHECK-NEXT: cont:
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: ret i32 %[[H]]
; CHECK-NEXT: }
; CHECK: define i32 @twin(i32 %u0, i1 %k) {
; CHECK-NEXT: entry:
; CHECK-NEXT: %[[TH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[TH]], double 5.000000e-01)
; CHECK-NEXT: br i1 %k, label %early, label %cont
; CHECK-EMPTY:
; CHECK-NEXT: early:
; CHECK-NEXT: ret i32 %[[TH]]
; CHECK-EMPTY:
; CHECK-NEXT: cont:
; CHECK-NEXT: %[[TF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[TH]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[TF]], double 2.500000e-01), !cq.branchphase
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[TF]], i32 %[[TH]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[TF]])
; CHECK-NEXT: ret i32 %[[TH]]
; CHECK-NEXT: }

; NEG-NOT: cq.retmerge
; NEG-NOT: call void @cq_phi(
; NEG-NOT: cqrt_free(i32 %h)
