; lowering_reject_uncompute_measured_parent_moved.ll — ACCEPT since bd
; test_C_libtooling-01po.8 (was a DECLINE, bd ptue's first decline twin of
; lowering_uncompute_measured_parent_rotated_dead_copy.ll). The file name is kept
; so a merge cannot resurrect the old decline under it (L7). The `clang -O1` IR of
;     int slice(int x){ int q = x; cq_theta(&q, .25); int t = q ^ 9;
;                       cq_theta(&q, .3); cq_theta(&t, .5); return cq_measure(q); }
;
; WHY IT DECLINED. The bd ptue retry borrows the measured `q` and would reverse
; `t` (ry(t,-.5); xor_hl_unc(t, q, 9); free(t)) at t's free point, after
; `ry(t, .5)`. `ry(q, .3)` runs BETWEEN the xor and that point, so the `_unc`
; would read a MOVED label: with q = Σ_w b_w|w> after the second Ry, `xor_hl_unc`
; XORs w^9 onto a rail holding v^9, leaving |v^w> ≠ |0>, and `cqrt_free` would
; be a hidden measurement (Rule 5). That reversal is still never emitted.
;
; WHY IT NOW LOWERS — AND WHAT IT LOWERS TO (semantic evidence for the flip, R10).
; `t`'s last use, `ry(t, .5)`, comes AFTER `ry(q, .3)`: the program itself keeps
; `t = q ^ 9` live across the rotation of `q`, a which-path record of q's
; pre-rotation label. After that, `t`'s `_unc` would need that label, which no
; later point has. So NO schedule can return `t` to |0>; the faithful circuit
; leaves it allocated. The frontier fixpoint (`planFrontierFixpoint`) proves
; exactly that (`recordLiveAcrossMove`: a use of `t` after an in-place gate on
; `q` inside its window), borrows `t`, drops it as a terminal, and emits NOTHING
; for it — no adjoint, no free. Stream (hand trace, Ry(.25)|x> = Σ_v a_v|v>):
;   alloc(x); ry(q,.25)           Σ a_v |v>
;   xor_hl(q,9) -> t              Σ a_v |v>|v^9>
;   ry(q,.3)                      Σ a_v (R'|v>)|v^9>   (dephased by the record)
;   ry(t,.5)                      a local unitary on the record
;   measure(q)                    P(w) = Σ_v |a_v|^2 |<w|R'|v>|^2 — the program's
;                                 distribution with `t` alive across the rotation
; `t` is never freed (a reset would be a measurement of the record, Rule 5), and
; `q` is never adjointed or freed. The live-record guard says so at the rotation
; (its "non-diagonal gate over a live derived record" warning, pinned below;
; owner ruling lyyf: dephasing by a record is the user's circuit, warned).
;
; THE DECLINES THAT STAY: a record whose uses END before the move
; (lowering_reject_uncompute_measured_parent_moved_dead_record.ll), a read after
; the collapse (lowering_reject_uncompute_measured_parent_read_after_measure.ll),
; a kept rail whose adjoint reads a borrowed register
; (lowering_reject_uncompute_measured_parent_frozen_{taped,copyout,transitive}.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=WARN < %t.err
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %x) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %t0 = xor i32 %q, 9
  %q2 = call i32 @cq_theta_si32(i32 %q, double 3.000000e-01)    ; moves q INSIDE the window
  %t  = call i32 @cq_theta_si32(i32 %t0, double 5.000000e-01)   ; t DEAD after this
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK-LABEL: define i32 @slice(i32 %x)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK-NEXT:  %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32_hl(i32 %[[H]], i32 9)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT:  call void @cqrt_ry_i32(i32 %[[T]], double 5.000000e-01)
; CHECK-NEXT:  %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT:  ret i32 %[[M]]

; WARN: warning{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; WARN-NOT: error
