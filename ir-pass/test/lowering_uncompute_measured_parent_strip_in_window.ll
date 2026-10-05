; lowering_uncompute_measured_parent_strip_in_window.ll — ACCEPT (bd
; test_C_libtooling-7xsh, Rule-11 round-1 finding F1: the disclosure of row (4)'s
; SECOND customer). Hand IR (the reviewer's probe 6, @ptue) because `clang -O1`
; sinks the xor past the region (R8):
;     q = cq_theta(x, .25); t0 = q ^ 9; if (q < 9) cq_phi(.75);
;     t = cq_theta(t0, .5); return cq_measure(q);
;
; WHY IT IS 7xsh's FIXTURE. `borrowedParentsUnmoved` has two callers: the M-B
; interior discharge (bd 7xsh's own customer) and the dead-terminal FRONTIER
; RETRY (bd 01po.4's array borrow, bd ptue's measured-rail borrow). Row (4) of
; `preservesBorrowedParent` — an emitter-RECORDED strip reading the borrowed
; parent outside its slot-0 flag is label-preserving — therefore widened the
; retry as well. Here the dead terminal `t` (a rotated copy of the measured `q`)
; is minted BEFORE a phase region on `q`, so the region's recorded strip
; `icmp_slt_i32_hl_unc(f, q, 9)` lies strictly inside the retry's window
; [the xor, t's free point]. Declined before 7xsh ("dead chain would free a
; measured register"); now accepted. (`t` is not recorded, so it is freed, not
; kept: the bd eqti kept-rail fence does not apply, re-checked after eqti.)
;
; HAND TRACE, Ry(.25)|x> = Σ_v a_v|v> on q:
;   xor_hl(q, 9)                 t = v^9                (t minted from |0>)
;   icmp_slt_hl(q, 9)            f = [v<9]; rz_i1(f, .75): the branch phase
;   icmp_slt_hl_unc(f, q, 9)     f = 0 — Σ_v |v><v|_q ⊗ X_f^{[v<9]}: reads q,
;                                writes only f; free(f)
;   ry(t, .5); ry(t, -.5)        cancel exactly
;   xor_hl_unc(t, q, 9)          t = v^9 ⊕ v^9 = 0: only label readers of q ran
;                                inside the window
;   cqrt_free(t)                 |0> in a product state — nothing learned
;   measure(q)                   P(v) = |a_v|^2; q never un-rotated or freed
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @ptue(i32 %x) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %t0 = xor i32 %q, 9
  %c  = icmp slt i32 %q, 9
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 7.500000e-01)
  br label %merge
merge:
  %t  = call i32 @cq_theta_si32(i32 %t0, double 5.000000e-01)
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK-LABEL: define i32 @ptue(i32 %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[H]], i32 9)
; CHECK-NEXT:  %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_rz_i1(i32 %[[F]], double 7.500000e-01)
; CHECK-NEXT:  call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double -5.000000e-01)
; CHECK-NEXT:  call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  ret i32 %[[M]]

; The measured register is never un-rotated and never freed (window = alloc -> EOF):
; NOQ:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; NOQ-NOT: call void @cqrt_ry_i32(i32 %[[R]], double -2.500000e-01)
; NOQ-NOT: call void @cqrt_free(i32 %[[R]])
