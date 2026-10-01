; lowering_break_abort_park_width_merge_out.ll — ACCEPT (bd test_C_libtooling-r2j3.5,
; review round 2 N1, probe Q2). NO break loop here: the name keeps the fixture in the
; `break|brk` filter beside its companion lowering_loop_break_abort_park_width.ll.
;
;     long long g(long long a) { return a * 3 + 1; }    // plain classical function
;     long long q = cq_theta(seed, 0.5);
;     long long y = 5;
;     if (q > 3) y = g(a);          // classical call under quantum control
;     if (y > t) abort();           // noreturn arm: AbortParkEmit parks y
;     return cq_measure(y);
;
; The first `if` is a value arm (ClassicalCallArmEmit: `g(a)` hoisted into the pred,
; controlled-copy merge into a fresh `%out`). `%out` is an i32 HANDLE for a 64-bit
; rail; its width lives only in `taint.HandleWidth` (written by the emitter). y is
; tainted only after that merge, so the abort arm is claimed in round 2
; (`repropagateControlMerges`) with `%out` as the park's routed register. The park
; read the width off `Q->getType()` — the laundered i32 — and minted
; `%grave = cqrt_alloc_i32(0)`, then `cqrt_cswap(flag, %out, %grave)`: a 32-qubit
; graveyard swapped against a 64-qubit rail, verify-clean, opt rc 0. MEASURED on
; main (cq-opt d5eeb383, 2026-10-01), pre-existing and independent of any break
; loop: r2j3.5 covers ANY laundered merge output that becomes the park's routed
; register in round 2, not only the break answer. The park now asks
; `logicalOperandWidth`, so the graveyard is `cqrt_alloc_i64`.
;
; Stage-1 IR: clang -O1 of the C above (attributes trimmed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOGRAVE32 < %t.cqd0.ll
; NOGRAVE32-NOT: %grave{{[0-9]*}} = call i32 @cqrt_alloc_i32

; `g` keeps clang's memory(none)/willreturn group: the classical-call arm needs a
; pure callee (without it the first `if` is declined as control flow).
define i64 @g(i64 noundef %0) #3 {
  %2 = mul nsw i64 %0, 3
  %3 = add nsw i64 %2, 1
  ret i64 %3
}

define i64 @run(i64 noundef %0, i64 noundef %1, i64 noundef %2) {
  %4 = tail call i64 @cq_theta_sll(i64 noundef %0, double noundef 5.000000e-01) #0
  %5 = icmp sgt i64 %4, 3
  br i1 %5, label %6, label %8

6:
  %7 = tail call i64 @g(i64 noundef %1)
  br label %8

8:
  %9 = phi i64 [ %7, %6 ], [ 5, %3 ]
  %10 = icmp sgt i64 %9, %2
  br i1 %10, label %11, label %12

11:
  tail call void @abort() #2
  unreachable

12:
  %13 = tail call i64 @cq_measure_sll(i64 noundef %9) #1
  ret i64 %13
}

declare i64 @cq_theta_sll(i64 noundef, double noundef)
declare void @abort()
declare i64 @cq_measure_sll(i64 noundef)

attributes #0 = { nomerge nounwind }
attributes #1 = { nounwind }
attributes #2 = { cold noreturn nounwind }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }

; CHECK-LABEL: define i64 @run(
; --- round 1: the classical-call value arm merges into a fresh 64-bit `out` ---
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK:      call void @cqrt_copy_i64_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; --- round 2: the park routes `out` into a 64-bit graveyard -------------------
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i64_hl(i32 %[[OUT]], i64 %2)
; CHECK-NEXT: %[[G:grave[0-9]*]] = call i32 @cqrt_alloc_i64(i64 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[OUT]], i32 %[[G]])
; CHECK:      call i64 @cqrt_measure_i64(i32 %[[OUT]])
