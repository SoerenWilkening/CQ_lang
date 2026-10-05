; loop_park_condition_reject_stale_flag.ll — DECLINE (bd test_C_libtooling-dm7f.7's
; unsafe neighbour; agent E's stale-flag probe `s2.c`). `clang -O1` output
; (attributes and metadata dropped) of
;
;     int slice_ry(int u, int n) {
;       int q = u; cq_theta(&q, .5);
;       int c0 = q;                                  // PRE-loop record of q
;       for (int i = 0; i < n; i++) cq_theta(&q, .1);
;       if (c0 > 5) abort();                         // a park on the OLD record
;       return cq_measure(q);
;     }
;
; WHAT IT PINS. `-O1` sinks the park's compare past the loop: `%7 = icmp sgt
; %3, 5` reads the ROOT `%3` in the exit block. It is both an abort park's
; condition (bd dm7f.7) and a compare that cannot reach the loop (bd 8h7d.16),
; so CLOSURE admits it; after the collapse it would read the register the loop's
; Ry gates moved, and the park would park on the post-loop state where the
; source tests the pre-loop `c0`. The record-liveness fence finds `%3` → loop
; Ry → `%7` and declines. This is structural refusal (1)'s replacement wall
; (AbortParkEmit.cpp, `namesRoutedRegister`). On main the module declined
; `control flow under quantum control` at the park's register guard. Accept
; twin: `loop_park_condition.ll` (the park BEFORE the loop).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare void @abort() noreturn

define i32 @slice_ry(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %8, label %5

5:
  %6 = phi i32 [ %3, %2 ], [ %11, %8 ]
  %7 = icmp sgt i32 %3, 5
  br i1 %7, label %14, label %15

8:
  %9 = phi i32 [ %12, %8 ], [ 0, %2 ]
  %10 = phi i32 [ %11, %8 ], [ %3, %2 ]
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 1.000000e-01)
  %12 = add nuw nsw i32 %9, 1
  %13 = icmp eq i32 %12, %1
  br i1 %13, label %5, label %8

14:
  tail call void @abort()
  unreachable

15:
  %16 = tail call i32 @cq_measure_si32(i32 noundef %6)
  ret i32 %16
}
