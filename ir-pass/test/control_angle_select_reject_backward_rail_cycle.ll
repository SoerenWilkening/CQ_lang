; control_angle_select_reject_backward_rail_cycle.ll — DECLINE (S7 rail prong;
; bd 3paw's decline twin). The mirror of
; `control_angle_select_forward_rail_cycle_frozen.ll`: the counting loop on `r`
; runs BEFORE the angle select instead of after it. `clang -O1` output of
; (attributes and `!llvm.loop` dropped):
;
;     int slice(int u0, int u1, int n) {
;       int q = u0; cq_theta(&q, .5);  int r = u1; cq_theta(&r, .25);
;       for (int i = 0; i <= n; i++) cq_theta(&r, .1);
;       cq_theta(&r, q == 5 ? .9 : .3);
;       return cq_measure(q) + cq_measure(r);
;     }
;
; WHAT IT PINS. bd 3paw lets S7's rail prong and S9 skip a member / reader of a
; Case-A-CLAIMED rail only when the consumer `T` DOMINATES it, i.e. only a name
; the collapse re-spelt from a POST-gate value. Here Case-A also claims the rail
; and collapses the header φ onto the root `%5`, so the loop's
; `cq_theta(%5, .1)` is again a member of the base's wire on a cycle — but it
; runs BEFORE `T` (in the exit block `%7`), `T` does not dominate it, and the
; prong keeps declining. Dropping the dominance conjunct (bd 3paw mutant M1)
; accepts this module.
;
; WHY IT STAYS LOUD. This is the L2-1 family the rail prong was built for (bd
; drbq Inc 2b round 1; `control_angle_select_reject_loop_rail_exit_block.ll`):
; a loop that relabels the rotated register BEFORE the select, analysed by
; `lowerLoops` before the emitter adds the unconditional twin `T0`. Whether this
; collapsed, control-free spelling is sound is unproven, not disproven, so it is
; a recorded over-decline (R1) for its own bead, not a physics decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01)
  %6 = icmp slt i32 %2, 0
  br i1 %6, label %7, label %15

7:
  %8 = phi i32 [ %5, %3 ], [ %18, %15 ]
  %9 = icmp eq i32 %4, 5
  %10 = select i1 %9, double 9.000000e-01, double 3.000000e-01
  %11 = tail call i32 @cq_theta_si32(i32 noundef %8, double noundef %10)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %14 = add nsw i32 %13, %12
  ret i32 %14

15:
  %16 = phi i32 [ %19, %15 ], [ 0, %3 ]
  %17 = phi i32 [ %18, %15 ], [ %5, %3 ]
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 1.000000e-01)
  %19 = add nuw i32 %16, 1
  %20 = icmp eq i32 %16, %2
  br i1 %20, label %7, label %15
}
