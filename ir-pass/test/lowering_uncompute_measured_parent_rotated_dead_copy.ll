; lowering_uncompute_measured_parent_rotated_dead_copy.ll — ACCEPT (bd
; test_C_libtooling-ptue; the measured-rail half of bd 01po.8's general
; frontier retry). The `clang -O1` IR of
;     int slice(int x){ int q = x; cq_theta(&q, .25); int t = q ^ 9;
;                       cq_theta(&t, .5); return cq_measure(q); }
; `t` is a DEAD rotated derived copy of the MEASURED register `q`.
;
; WHAT DECLINED, AND WHY THE DECLINE PROTECTED ONLY THE SPINE'S PLAN (L5). The
; whole-DAG walk from the dead terminal `t` hops to `t`'s parent `q`, takes the
; `cqrt_alloc` root and its prep `cqrt_ry` into the DAG, finds `q`'s measure and
; refuses: reversing THAT DAG would un-rotate `q` and act on it before the user's
; measurement reads it. But `t`'s reversal never needs `q`'s chain — only `q`'s
; LABEL, read-only, by the xor's `_unc`. `reverseTerminalGroup` now retries with
; every measured rail BORROWED (`InteriorPlan::Borrowed`: never walked, never
; adjointed, never freed), exactly as bd 01po.4 already borrowed QRAM arrays, and
; emits only if the reduced DAG passes every check the driver asks plus the M-B
; clause-(d) scan (`borrowedParentsUnmoved`) and the measure-after-read test.
;
; HAND TRACE OF THE STREAM PINNED BELOW. Let Ry(.25)|x> = Σ_v a_v|v> on q.
;   xor_hl(q, 9)              Σ a_v |v>|v^9>               (t minted from |0>)
;   ry(t, .5)                 Σ a_v |v> R|v^9>             (R = Ry_i32(.5), unitary)
;   -- reversal, inserted BEFORE the measure (t's free point) --
;   ry(t, -.5)                Σ a_v |v>|v^9>               (R† R = I, exact)
;   xor_hl_unc(t, q, 9)       Σ a_v |v>|0>                 (q's label unchanged since the xor)
;   cqrt_free(t)              t is |0> in a PRODUCT state: the reset learns nothing
;   measure(q)                P(v) = |a_v|^2, the program's distribution
; So the rotated rail IS provably |0> at its free — its own Ry is reverse-played
; (an uncontrolled `cqrt_ry_<W>` on an owned rail always is; only a
; `cqrt_ry_<W>_controlled` rail is frozen). `q`'s prep Ry is never reversed and
; `q` is never freed (NOQ below).
;
; THE DECLINE TWINS keep the genuinely unsafe neighbours loud, char-for-char:
;   * lowering_reject_uncompute_measured_parent_moved.ll — `q` is rotated
;     between the xor and t's free point, so the `_unc` would read a moved label
;     (an ACCEPT since bd 01po.8: that reversal is still never emitted, `t` is
;     left allocated as the record the program keeps across the rotation);
;   * lowering_reject_uncompute_measured_parent_read_after_measure.ll — the dead
;     chain reads `q` AFTER the measurement: bd yiid, a RULED capability (owner
;     2026-09-14; E3 (b) BROAD 2026-09-15) not yet built, so that decline is a
;     loud over-decline kept pending E3, not a physics wall;
;   * the bd eqti kept-rail adjoint fence, when `t` is RECORDED as well as
;     rotated: lowering_reject_uncompute_measured_parent_frozen_{taped,copyout,
;     transitive}.ll (here `t` is not recorded, so it is freed, not kept).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %x) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %t0 = xor i32 %q, 9
  %t  = call i32 @cq_theta_si32(i32 %t0, double 5.000000e-01)   ; t DEAD after this
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK-LABEL: define i32 @slice(i32 %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double -5.000000e-01)
; CHECK-NEXT:  call void @cq_template_xor_i32_hl_unc(i32 %[[T]], i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  ret i32 %[[M]]

; The measured register is never un-rotated and never freed, anywhere after its
; birth (window = alloc -> EOF):
; NOQ:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; NOQ-NOT: call void @cqrt_ry_i32(i32 %[[R]], double -2.500000e-01)
; NOQ-NOT: call void @cqrt_free(i32 %[[R]])
