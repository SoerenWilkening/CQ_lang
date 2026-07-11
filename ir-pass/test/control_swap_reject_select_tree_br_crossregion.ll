; control_swap_reject_select_tree_br_crossregion.ll — DECLINE PIN (3c6m.12
; design-review probe): a leaf compare shared between an accepted-grammar
; compound SELECT condition and a tainted `br` DIAMOND. The select side alone
; would accept, but the br region's own classification (ArmClassify) declines
; its shape loudly, so the MODULE is rejected (opt exits non-zero, no output
; written) — no cross-region emission can survive half-done. Pinned so a
; future br-side widening cannot silently change the compound select's
; cross-region story without failing red here (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1  = icmp sgt i32 %q, 5
  %c2  = icmp slt i32 %q, 100
  %c   = or i1 %c1, %c2
  %sel = select i1 %c, i32 %q, i32 %x
  br i1 %c1, label %arm, label %merge      ; the shared leaf also gates a diamond
arm:
  br label %merge
merge:
  %m   = call i32 @cq_measure_si32(i32 %sel)
  ret i32 %m
}
