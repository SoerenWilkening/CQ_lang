; control_classical_call_arm_twin_accept_sdiv_callee.ll — ACCEPT (bd dm7f.30; was
; control_classical_call_arm_twin_reject_sdiv_callee.ll, a DECLINE since bd dm7f.21).
; Immediate UB that is NOT poison: a divisor no `freeze` alone discharges. IR: clang
; 19 -O1 of exactly
;   __attribute__((noinline)) int g(int v){ return v ^ 5; }
;   __attribute__((noinline)) int h(int x){ return g(100 / x); }
;   int ex(int k){ int q = 0; cq_theta(&q, 0.0); int y = q; if (q > 3) y = h(k); return cq_measure(y); }
; target attributes trimmed (R8). `sdiv i32 100, %0` traps for k = 0: hoisting `@h`
; itself out of the zero-amplitude guard would execute it on every basis state (bd
; wve8's SIGFPE). The strict walk refuses the non-constant divisor, so the Direct
; route is closed; the Twin route GUARDS it (TwinTotality.h): the divisor becomes
; `select((d == 0) | (d == -1), 1, freeze d)` and the `d == -1` result is rebuilt as
; `0 - 100`. The `sdiv` result reaches `@g`'s `noundef` parameter and is frozen.
; ANALYTIC (R2): on a basis state where the source runs `h(k)` without UB, k is
; defined and non-zero, so the guard selects k, and for k = -1 the source computes
; 100 / -1 = -100 = 0 - 100; the twin returns `h(k)`. On a state the guard excluded,
; k = 0 divides by 1 (Bennett.jl's divide-by-zero kernel is likewise total and
; unspecified there, src/divider.jl:8-21 at 824458d1) and the value is never merged.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck --check-prefix=ORIG %s < %t.ll
;
; ORIG-LABEL: define noundef i32 @h(i32 noundef %0)
; ORIG-NEXT:    %2 = sdiv i32 100, %0
; ORIG-NEXT:    %3 = tail call i32 @g(i32 noundef %2)
; ORIG-NEXT:    ret i32 %3
;
; CHECK-LABEL: define i32 @ex(
; CHECK:       %[[R:[0-9]+]] = tail call i32 @__cq_specsafe_h(i32 noundef %0)
; CHECK-NOT:   call i32 @h(
; CHECK:       %[[RH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[R]])
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[RH]],
; CHECK:       define internal noundef i32 @__cq_specsafe_h(i32 noundef %0) unnamed_addr #{{[0-9]+}} !cq.specsafe.twin ![[TW:[0-9]+]] {
; CHECK-NEXT:    %cq.div.fr = freeze i32 %0
; CHECK-NEXT:    %cq.div.zero = icmp eq i32 %cq.div.fr, 0
; CHECK-NEXT:    %cq.div.m1 = icmp eq i32 %cq.div.fr, -1
; CHECK-NEXT:    %cq.div.bad = or i1 %cq.div.zero, %cq.div.m1
; CHECK-NEXT:    %cq.div.safe = select i1 %cq.div.bad, i32 1, i32 %cq.div.fr
; CHECK-NEXT:    %2 = sdiv i32 100, %cq.div.safe
; CHECK-NEXT:    %cq.div.res = select i1 %cq.div.m1, i32 -100, i32 %2
; CHECK-NEXT:    %cq.div.res.fr = freeze i32 %cq.div.res
; CHECK-NEXT:    %3 = tail call i32 @g(i32 noundef %cq.div.res.fr)
; CHECK-NEXT:    ret i32 %3
; CHECK:       ![[TW]] = !{ptr @h}

define noundef i32 @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = xor i32 %0, 5
  ret i32 %2
}

define noundef i32 @h(i32 noundef %0) local_unnamed_addr #0 {
  %2 = sdiv i32 100, %0
  %3 = tail call i32 @g(i32 noundef %2)
  ret i32 %3
}

define i32 @ex(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0.000000e+00) #2
  %3 = icmp sgt i32 %2, 3
  br i1 %3, label %4, label %6

4:                                                ; preds = %1
  %5 = tail call i32 @h(i32 noundef %0)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 %8
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
