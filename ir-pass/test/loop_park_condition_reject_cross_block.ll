; loop_park_condition_reject_cross_block.ll — DECLINE (bd test_C_libtooling-dm7f.7;
; the "ask it at the branch" wall for every compare CLOSURE admits). `clang -O1`
; output (attributes and metadata dropped) of
;
;     volatile int sink;
;     int s3(int u, int n, int k) {
;       int q = u; cq_theta(&q, .5);
;       for (int i = 0; i < n; i++) cq_theta(&q, .1);
;       int c = (q > 5);                             // a FRESH post-loop read
;       if (k > 3) { q ^= 3; sink = k; }             // moves q's register
;       if (c) abort();                              // the park mints HERE
;       return cq_measure(q);
;     }
;
; WHAT IT PINS. The compare `%8 = icmp sgt %7, 5` reads the loop's exit φ in
; block `%6`, before the classically-guarded in-place `xor` `%17`; the park's
; branch on `%8` is in block `%18`, after it. CLOSURE admits the compare (bd
; 8h7d.16: it cannot reach the loop; and bd dm7f.7: it is a park's condition),
; and the compare's OWN read is fresh. But the park mints its flag at the
; BRANCH, from a register the xor has moved on the k > 3 path: a stale flag,
; the hazard AbortParkEmit's structural refusal (1) used to hold off.
; `railGateBeforeControlUse` asks the branch as a second read point of `%7`
; and the record-liveness fence declines. Before bd dm7f.7 the same binary
; declined `condition predates a non-diagonal gate under quantum control`, and
; only because that condition-wire fence treats the loop's Ry gates BEFORE the
; read as a hazard (a position-free reading that over-declines the post-loop
; kickback `for(…) cq_theta(&r,.1); if (r == 3) cq_phi(.3);`); made positional,
; it would have let this through. On main: `control flow under quantum control`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

@sink = global i32 0, align 4

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare void @abort() noreturn

define i32 @s3(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %10, label %6

6:
  %7 = phi i32 [ %4, %3 ], [ %13, %10 ]
  %8 = icmp sgt i32 %7, 5
  %9 = icmp sgt i32 %2, 3
  br i1 %9, label %16, label %18

10:
  %11 = phi i32 [ %13, %10 ], [ %4, %3 ]
  %12 = phi i32 [ %14, %10 ], [ 0, %3 ]
  %13 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 1.000000e-01)
  %14 = add nuw nsw i32 %12, 1
  %15 = icmp eq i32 %14, %1
  br i1 %15, label %6, label %10

16:
  %17 = xor i32 %7, 3
  store volatile i32 %2, ptr @sink, align 4
  br label %18

18:
  %19 = phi i32 [ %17, %16 ], [ %7, %6 ]
  br i1 %8, label %20, label %21

20:
  tail call void @abort()
  unreachable

21:
  %22 = tail call i32 @cq_measure_si32(i32 noundef %19)
  ret i32 %22
}
