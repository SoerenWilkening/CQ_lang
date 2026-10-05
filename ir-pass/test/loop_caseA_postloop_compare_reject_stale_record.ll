; loop_caseA_postloop_compare_reject_stale_record.ll — DECLINE (bd
; test_C_libtooling-8h7d.16's unsafe neighbour). `clang -O1` output
; (attributes and metadata dropped) of
;
;     int comp(int x, int y, int n) {
;       int q = x; cq_theta(&q, .5);
;       int r = y; cq_theta(&r, .25);
;       int c = (r == 3);                            // a flag on the PRE-loop r
;       for (int i = 0; i < n; i++) cq_theta(&r, .1);
;       int d = c + q;
;       return cq_measure(d) + cq_measure(r);
;     }
;
; WHAT IT PINS. `-O1` SINKS the compare past the loop: `%9 = icmp eq %5, 3`
; sits in the exit block, after the loop, but still names the ROOT record
; `%5`. 8h7d.16's CLOSURE admits a compare that cannot reach the header, so
; this one is admitted by position; after the collapse it would read the
; register the loop's Ry gates have moved, and its adjoint would too. Two walls
; refuse it, and this fixture pins the FIRST, which runs before `lowerLoops`
; on exact SSA: the stale-record pre-pass (`operand predates a non-diagonal
; gate`). Behind it, the record-liveness fence (`staleRailRecordRead`) would
; find the path `%5` → loop Ry → `%9` (argued from the walk, NOT measured: the
; pre-pass fires first, so that wall is unreachable from this module). Declined
; identically on main. Accept twin (the compare written after the loop):
; `loop_caseA_postloop_compare.ll` `@flag`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: operand predates a non-diagonal gate

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @comp(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01)
  %6 = icmp sgt i32 %2, 0
  br i1 %6, label %15, label %7

7:
  %8 = phi i32 [ %5, %3 ], [ %18, %15 ]
  %9 = icmp eq i32 %5, 3
  %10 = zext i1 %9 to i32
  %11 = add nsw i32 %4, %10
  %12 = tail call i32 @cq_measure_si32(i32 noundef %11)
  %13 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %14 = add nsw i32 %13, %12
  ret i32 %14

15:
  %16 = phi i32 [ %19, %15 ], [ 0, %3 ]
  %17 = phi i32 [ %18, %15 ], [ %5, %3 ]
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 1.000000e-01)
  %19 = add nuw nsw i32 %16, 1
  %20 = icmp eq i32 %19, %2
  br i1 %20, label %7, label %15
}
