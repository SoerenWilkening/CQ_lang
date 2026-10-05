; lowering_reject_uncompute_trailing_gate_in_arm.ll — DECLINE (bd
; test_C_libtooling-dm7f.2; decline twin of
; lowering_uncompute_trailing_gate_after_tape.ll). The `clang -O1` IR of
;     static const int tbl[8] = {3,1,4,7,5,9,2,6};
;     int f(_Bool u, int c){ _Bool b = u; cq_theta(&b, .5); int v = tbl[b];
;                            printf("%d %d\n", b, v);
;                            if (c) cq_theta(&b, -.5); return 0; }
;
; THE NEIGHBOUR THE TRAILING-GATE PLACEMENT MUST NOT TAKE. The trailing Ry now
; runs on ONE classical path. Moving the single reversal past it lands at the
; merge, which the arm's gate does not dominate: one unconditional adjoint
; there would fire `ry(b, +.5)` on the path that never ran the forward gate (the
; reverted-543bd85 divergent-arm miscompile). The new point is refused and the
; module keeps its decline, and here the message is TRUE: the dead chain spans
; a divergent control-flow arm. A loud gap (per-arm reverse-play is not built
; for the dead-terminal spine), not a physics wall (R1).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@tbl = internal unnamed_addr constant [8 x i32] [i32 3, i32 1, i32 4, i32 7, i32 5, i32 9, i32 2, i32 6], align 16
@.str = private unnamed_addr constant [7 x i8] c"%d %d\0A\00", align 1

define noundef i32 @f(i1 noundef zeroext %0, i32 noundef %1) {
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %0, double noundef 5.000000e-01)
  %4 = zext i1 %3 to i64
  %5 = getelementptr inbounds [8 x i32], ptr @tbl, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4
  %7 = zext i1 %3 to i32
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %7, i32 noundef %6)
  %9 = icmp eq i32 %1, 0
  br i1 %9, label %12, label %10

10:
  %11 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %3, double noundef -5.000000e-01)
  br label %12

12:
  ret i32 0
}

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare noundef i32 @printf(ptr nocapture noundef readonly, ...)

; CHECK: error{{.*}}cq uncompute: dead chain spans divergent control-flow arms
