; lowering_uncompute_measured_parent_per_component.ll — ACCEPT (bd
; test_C_libtooling-01po.12). Three `clang -O1` functions (debug info stripped):
;   @slice   int q=x; cq_theta(&q,.25); int t=q^9; cq_theta(&t,.5);
;            int m=cq_measure(q); int w=y; cq_theta(&w,.3); return m;
;   @slice_b the same plus `int s=w+1; cq_theta(&s,.2);` after `w`
;   @shared  int q=x; cq_theta(&q,.25); int a=q*3; int t=a^9; cq_theta(&t,.5);
;            int u=a+1; cq_theta(&u,.2); int m=cq_measure(q);
;            int w=y; cq_theta(&w,.3); return m;
; Each declined "cq uncompute: dead chain would free a measured register" on
; main 7b4e6359.
;
; WHAT DECLINED. `uncompute` reverses all regular dead terminals of a function as
; ONE group at ONE point, the latest terminal anchor. The bd ptue frontier retry
; borrows the measured `q` and asks clause (d) (`borrowedParentsUnmoved`) over
; q's window: from the first DAG gate that reads q to that shared point. The
; unrelated dead `w` (or `s`) is anchored AFTER `measure(q)`, so the measurement
; falls inside the window and the retry refused. The refusal protected the
; shared reversal point, not the unitary (L5): `t`'s reversal needs q's label
; only up to t's own last use.
;
; THE FIX. When the whole-group retry refuses, the retry is asked again PER
; COMPONENT: terminals whose reduced DAGs (walked with the same borrowed
; frontier) share no gate and no rail are planned at their OWN reversal points,
; each re-asking every check of the whole-group retry. All components are
; planned before any is emitted; one refusal keeps today's decline verbatim.
; Components share at most a BORROWED register, which no reversal writes, so the
; separate reversals act on disjoint registers and commute.
;
; HAND TRACE, @slice. Let Ry(.25)|x> = Σ_v a_v|v> on q, and W = Ry(.3)|y> on w.
;   xor_hl(q,9); ry(t,.5)       Σ a_v |v> R|v^9>             (t minted from |0>)
;   ry(t,-.5)                   Σ a_v |v> |v^9>              (R†R = I)
;   xor_hl_unc(t,q,9)           Σ a_v |v> |0>                (q unmoved since the xor)
;   cqrt_free(t)                |0> in a product state: the reset learns nothing
;   measure(q)                  P(v) = |a_v|^2, the program's distribution
;   alloc(y); ry(w,.3)          w = W, a product with everything else
;   ry(w,-.3)                   w = |y>; no free (bd 5c5b: a `cqrt_alloc(%1)` root
;                               is born |y>, not |0>, so it is left allocated)
; @slice_b: `s = w + 1` is the M-C in-place spelling (w is dead after it), so
; w's own component is the in-place chain ry(w,.3); addc(w,1); ry(w,.2), reversed
; whole in reverse order: ry(w,-.2); addc(w,-1); ry(w,-.3) -> w = |y> again; still
; no free (born |y>). It shares no register with {t}.
;
; HAND TRACE, @shared — one component {t, u} sharing the OWNED prefix a = 3q.
;   mul_hl(q,3) -> a; xor_hl(a,9) -> t; ry(t,.5); add_hl(a,1) -> u; ry(u,.2)
;   reversal at u's anchor, BEFORE measure(q), in reverse program order:
;   ry(u,-.2); add_hl_unc(u,a,1)    u holds 3v+1, a holds 3v -> u = 0; free(u)
;   ry(t,-.5); xor_hl_unc(t,a,9)    t holds 3v^9            -> t = 0; free(t)
;   mul_hl_unc(a,q,3)               q's label unmoved since the mul -> a = 0; free(a)
;   measure(q); then w's component as in @slice.
; The prefix is reversed ONCE: splitting {t} from {u} would leave each half's
; `a` read by the other half (not closed) — the component partition is the
; reduced DAG's connectivity, not one component per terminal.
;
; DECLINE TWIN: lowering_reject_uncompute_measured_parent_per_component_read_after_measure.ll
; (a second component that reads q AFTER its measurement keeps the decline).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %0, i32 %1) {
  %3 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %4 = xor i32 %3, 9
  %5 = tail call i32 @cq_theta_si32(i32 %4, double 5.000000e-01)
  %6 = tail call i32 @cq_measure_si32(i32 %3)
  %7 = tail call i32 @cq_theta_si32(i32 %1, double 3.000000e-01)
  ret i32 %6
}

define i32 @slice_b(i32 %0, i32 %1) {
  %3 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %4 = xor i32 %3, 9
  %5 = tail call i32 @cq_theta_si32(i32 %4, double 5.000000e-01)
  %6 = tail call i32 @cq_measure_si32(i32 %3)
  %7 = tail call i32 @cq_theta_si32(i32 %1, double 3.000000e-01)
  %8 = add nsw i32 %7, 1
  %9 = tail call i32 @cq_theta_si32(i32 %8, double 2.000000e-01)
  ret i32 %6
}

define i32 @shared(i32 %0, i32 %1) {
  %3 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %4 = mul nsw i32 %3, 3
  %5 = xor i32 %4, 9
  %6 = tail call i32 @cq_theta_si32(i32 %5, double 5.000000e-01)
  %7 = add nsw i32 %4, 1
  %8 = tail call i32 @cq_theta_si32(i32 %7, double 2.000000e-01)
  %9 = tail call i32 @cq_measure_si32(i32 %3)
  %10 = tail call i32 @cq_theta_si32(i32 %1, double 3.000000e-01)
  ret i32 %9
}

; CHECK-LABEL: define i32 @slice(i32 %0, i32 %1)
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double -5.000000e-01)
; CHECK-NEXT:  call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  %[[W:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[W]], double 3.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[W]], double -3.000000e-01)
; CHECK-NEXT:  ret i32 %[[M]]

; CHECK-LABEL: define i32 @slice_b(i32 %0, i32 %1)
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double -5.000000e-01)
; CHECK-NEXT:  call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  %[[W:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[W]], double 3.000000e-01)
; CHECK-NEXT:  call void @cqrt_addc_i32(i32 %[[W]], i32 1)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[W]], double 2.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[W]], double -2.000000e-01)
; CHECK-NEXT:  call void @cqrt_addc_i32(i32 %[[W]], i32 -1)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[W]], double -3.000000e-01)
; CHECK-NEXT:  ret i32 %[[M]]

; CHECK-LABEL: define i32 @shared(i32 %0, i32 %1)
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[A]], i32 9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  %[[U:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[A]], i32 1)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[U]], double 2.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[U]], double -2.000000e-01)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[U]], i32 %[[A]], i32 1)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[U]])
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double -5.000000e-01)
; CHECK-NEXT:  call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[A]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  call void @cq_template_mul_i32_hl_unc(i32 %[[A]], i32 %[[H]], i32 3)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[A]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  %[[W:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[W]], double 3.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[W]], double -3.000000e-01)
; CHECK-NEXT:  ret i32 %[[M]]

; The measured register is never un-rotated and never freed (window = alloc -> EOF),
; and the borrowed-root `w` is never freed either (born |y>, bd 5c5b):
; NOQ-LABEL: define i32 @slice(
; NOQ:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; NOQ-NOT: call void @cqrt_ry_i32(i32 %[[R]], double -2.500000e-01)
; NOQ-NOT: call void @cqrt_free(i32 %[[R]])
; NOQ:     %[[W:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %1)
; NOQ-NOT: call void @cqrt_free(i32 %[[W]])
; NOQ-LABEL: define i32 @slice_b(
; NOQ:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; NOQ-NOT: call void @cqrt_ry_i32(i32 %[[R]], double -2.500000e-01)
; NOQ-NOT: call void @cqrt_free(i32 %[[R]])
; NOQ-LABEL: define i32 @shared(
; NOQ:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; NOQ-NOT: call void @cqrt_ry_i32(i32 %[[R]], double -2.500000e-01)
; NOQ-NOT: call void @cqrt_free(i32 %[[R]])
; NOQ:     ret i32
