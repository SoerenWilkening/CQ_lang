; lowering_uncompute_dead_sibling_premeasure.ll — ACCEPT since bd
; test_C_libtooling-ptue (was a DECLINE: test_C_libtooling-3h8). A DEAD tainted
; template terminal whose register lineage is LATER measured through an upstream
; handle (straight-line, NO control region). The file name is kept so a merge
; cannot resurrect the old decline under it (CLAUDE.md L7).
;
; `%q = @cq_theta_si32(...)`; `%dead = q + 7` (never read); `measure(q)`.
;
; THE HISTORY (3h8). The whole-chain adjoint of the dead `%dead` chain re-emitted
; `add_hl_inv`, `cqrt_ry(%h, -θ)` and `cqrt_free(%h)` — undoing the prep Ry and
; freeing the register — BEFORE `cqrt_measure(%h)` read it: a hidden collapse and
; a wrong unitary (Rules 5/6). The fix then declined the whole chain loudly
; ("cq uncompute: dead chain would free a measured register").
;
; WHY IT IS NOW AN ACCEPT (ptue, L5). That decline protected the whole-DAG PLAN,
; which OWNED `q`. `%dead`'s reversal needs only `q`'s label, read-only, so the
; driver now retries with the measured rail BORROWED (never walked, adjointed or
; freed) and emits when the reduced plan proves out — here it does. Hand trace,
; with Ry(.25)|x> = Σ_v a_v|v> on q:
;   add_hl(q, 7)           Σ a_v |v>|v+7>     (dead minted from |0>)
;   add_hl_unc(dead, q, 7) Σ a_v |v>|0>       (q untouched since the add)
;   cqrt_free(dead)        |0> in a product state — the reset learns nothing
;   measure(q)             P(v) = |a_v|^2, the program's distribution
; `q`'s prep Ry is never reversed and `q` is never freed (NOQ). A dead pure op is
; thereby uncomputed at once, which is the program's meaning of "dead".
;
; The no-measure twin (lowering_uncompute_dead_sibling_no_measure.ll) still owns
; `q` and reverses it whole; the neighbours of the borrowed plan are
; lowering_reject_uncompute_measured_parent_moved.ll (an accept that leaves the
; record allocated since bd 01po.8) and the decline
; lowering_reject_uncompute_measured_parent_read_after_measure.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOQ < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %x) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %dead = add i32 %q, 7                          ; DEAD tainted template terminal
  %m    = call i32 @cq_measure_si32(i32 %q)      ; measures the register via the upstream handle
  ret i32 %m
}

; CHECK-LABEL: define i32 @slice(i32 %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 7)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 7)
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  ret i32 %[[M]]

; The measured register is never un-rotated and never freed (window = alloc -> EOF):
; NOQ:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; NOQ-NOT: call void @cqrt_ry_i32(i32 %[[R]], double -2.500000e-01)
; NOQ-NOT: call void @cqrt_free(i32 %[[R]])
