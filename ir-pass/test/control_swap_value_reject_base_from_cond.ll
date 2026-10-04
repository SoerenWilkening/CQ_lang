; control_swap_value_reject_base_from_cond.ll — HALF ONE OF A PAIR. A value
; register DERIVED FROM the condition register declines on the `br`-DIAMOND path
; and ACCEPTS through the `select` front door. bd test_C_libtooling-3qlq Inc 2,
; Rule-13 round-2 review finding F-I2-7.
;
; The other half is `control_swap_select_base_from_cond.ll` — SAME source program,
; the arm hoisted by hand into a `?:`. Read them together or neither: the point of
; this file is not the decline (that is correct and conservative) but the
; ASYMMETRY, which is an OVER-DECLINE of the `br` path and is recorded as an owner
; item (`RETIRE_SWAP_ROUTE_INC2_NOTES.md` §4, "the base-from-cond asymmetry").
;
; PROVENANCE — captured from real `clang -O1`, SSA values renamed for reading and
; nothing else. Source (`$SP/progress/fix_inc2_r2_work/p/q1e_ent.c`):
;
;   int slice(void){ int q=3; cq_theta(&q,0.5); int p=q+11;
;     if (q>3){ p=p+3; p=p*5; p=p^9; p=p+1; p=p*7; p=p^2; }
;     return cq_measure(p); }
;
; ⚠ NOTE WHAT `-O1` DID, because it is the whole reason the two halves differ:
; reassociation rewrote the arm chain so that it bottoms at **%q**, not at the
; routed slot %p = `add(q,11)`. `p+3` became `mul(q,5)` + `add(·,70)` and so on.
; So the merge muxes two INDEPENDENTLY q-derived values, `ChainBase != Routed`,
; and `classifyValueArm` declines with the dedicated data-mux string. Nothing in
; the source says "two bases"; the optimiser created them.
;
; WHAT THIS ADDS OVER `control_swap_reject_value_mux_derived.ll`, which pins the
; same STRING on the same class: that file is a hand-shaped two-op module written
; to exhibit `ChainBase != Routed`. This one is a real `-O1` survivor with a SIX-op
; arm chain and, decisively, it has a committed accept twin. Neither half is
; redundant with it, and the pair is not redundant with itself.
;
; MEASURED on THREE binaries (pre-3qlq oracle 52d7764, `main` a3c1513 with Inc 0+1
; landed, and this branch): this module DECLINES identically on all three, and its
; twin ACCEPTS identically on all three with a BYTE-IDENTICAL lowering. So the
; asymmetry is PRE-EXISTING — it is not Inc 2's, and Inc 2 neither widened nor
; narrowed it. It is pinned here because the round-2 review found the OPPOSITE
; asymmetry (the reviewer flag, §1.11 item 1: the diamond accepts where the select
; refuses) written down and this one not, and two asymmetries pointing in opposite
; directions are only legible together.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: non-routable value multiplexer under quantum control
; Nothing is lowered on a decline (Prime Directive), and the message must be the
; DEDICATED mux one — not §3c (the arm never rewrites %q; it only reads it) and
; not the generic control-flow string.
; CHECK-NOT: arm rewrites a condition operand
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @slice() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %p = add nsw i32 %q, 11        ; straight-through incoming, DERIVED from %q
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:                             ; -O1 reassociated the chain onto %q, not %p
  %a1 = mul i32 %q, 5
  %a2 = add i32 %a1, 70
  %a3 = xor i32 %a2, 9
  %a4 = mul i32 %a3, 7
  %a5 = add i32 %a4, 7
  %a6 = xor i32 %a5, 2
  br label %merge
merge:
  %pm = phi i32 [ %a6, %arm ], [ %p, %entry ]   ; two independently q-derived values
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}
