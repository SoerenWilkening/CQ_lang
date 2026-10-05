; loop_caseA_postloop_compare_reject_zero_trip.ll — DECLINE (bd
; test_C_libtooling-8h7d.16's unsafe neighbour; bd g35c meets the widening).
; `clang -O1` output (attributes and metadata dropped) of
;
;     int comp(int x, int y, int n) {
;       int q = x; cq_theta(&q, .5);
;       int r = y; cq_theta(&r, .25);
;       int z = r;                                   // PRE-gate record of r
;       cq_theta(&r, (q == 5) ? .9 : .3);            // T moves r's wire
;       for (int i = 0; i < n; i++) { cq_theta(&r, .1); z = r; }
;       int a = x + 1; cq_theta(&a, .7);
;       for (int i = 0; i < n; i++) { a ^= 9; if (a == z) break; }
;       return cq_measure(a) + cq_measure(q);
;     }
;
; WHAT IT PINS. 8h7d.16 lets CLOSURE admit a compare after the loop, here the
; break's comparand `%25 = icmp eq %24, %11`. Its operand is the loop's exit φ
; `%11 = phi [%5, guard], [%18, latch]`, whose ZERO-TRIP edge carries `%5`, the
; record from BEFORE `T` (`%8`). After the collapse the compare would read r's
; register, which on n == 0 holds the post-`T` state, while the source compares
; `a` with the pre-`T` `z`. The record-liveness fence asks the member φ's
; zero-trip edge (bd g35c): `T` lies between `%5` and the guard's branch, so the
; loop declines here. On main the loop was unclaimed and the module declined
; `control flow inside a loop body under quantum control` at the break. Accept
; twin (the comparand is the POST-gate r):
; `loop_caseA_postloop_compare.ll` `@brk`.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @comp(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01)
  %6 = icmp eq i32 %4, 5
  %7 = select i1 %6, double 9.000000e-01, double 3.000000e-01
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %7)
  %9 = icmp sgt i32 %2, 0
  br i1 %9, label %15, label %10

10:
  %11 = phi i32 [ %5, %3 ], [ %18, %15 ]
  %12 = add nsw i32 %0, 1
  %13 = tail call i32 @cq_theta_si32(i32 noundef %12, double noundef 0x3FE6666666666666)
  %14 = icmp sgt i32 %2, 0
  br i1 %14, label %21, label %29

15:
  %16 = phi i32 [ %19, %15 ], [ 0, %3 ]
  %17 = phi i32 [ %18, %15 ], [ %8, %3 ]
  %18 = tail call i32 @cq_theta_si32(i32 noundef %17, double noundef 1.000000e-01)
  %19 = add nuw nsw i32 %16, 1
  %20 = icmp eq i32 %19, %2
  br i1 %20, label %10, label %15

21:
  %22 = phi i32 [ %26, %21 ], [ 0, %10 ]
  %23 = phi i32 [ %24, %21 ], [ %13, %10 ]
  %24 = xor i32 %23, 9
  %25 = icmp eq i32 %24, %11
  %26 = add nuw nsw i32 %22, 1
  %27 = icmp eq i32 %26, %2
  %28 = select i1 %25, i1 true, i1 %27
  br i1 %28, label %29, label %21

29:
  %30 = phi i32 [ %13, %10 ], [ %24, %21 ]
  %31 = tail call i32 @cq_measure_si32(i32 noundef %30)
  %32 = tail call i32 @cq_measure_si32(i32 noundef %4)
  %33 = add nsw i32 %32, %31
  ret i32 %33
}
