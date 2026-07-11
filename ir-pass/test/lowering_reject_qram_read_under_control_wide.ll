; lowering_reject_qram_read_under_control_wide.ll — DECLINE, over-accept WIDTH probe
; (bd 3c6m.13, design-review scope lens). A tainted-index read of a CONSTANT `[N x i128]`
; global UNDER tainted control. Structurally it is a QROM read, but the CELL WIDTH (i128)
; has no reversible copy — even STRAIGHT-LINE the identical shape declines on width
; (lowering_reject_qram_i128_cell.ll → "not a reversible cell"). So control is NOT the sole
; blocker here: the width is. The precise `const-global table read under tainted control
; (needs nested-control lowering)` signpost must therefore NOT fire — that would be a FALSE
; promise (de-nesting would not make an i128 cell lowerable). The predicate is width-gated
; (widthHasQramCell) so it falls through to the generic escape decline instead.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK:     error{{.*}}cq taint escape: tainted value reaches an unsupported instruction
; CHECK-NOT: const-global table read under tainted control
@wtbl = internal unnamed_addr constant [2 x i128] [i128 7, i128 9]
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define void @wide_read(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp slt i32 %q, 2
  br i1 %c, label %arm, label %merge
arm:
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [2 x i128], ptr @wtbl, i64 0, i64 %i
  %v = load i128, ptr %g
  %t = trunc i128 %v to i32
  br label %merge
merge:
  %r = phi i32 [ %t, %arm ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}
