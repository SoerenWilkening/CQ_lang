; loop_park_condition.ll — ACCEPT (bd test_C_libtooling-dm7f.7). `clang -O1`
; output (attributes and metadata dropped) of
;
;     int slice(int u, int n) {
;       int q = u; cq_theta(&q, .5);
;       if (q > 5) abort();                          // the abort park
;       for (int i = 0; i < n; i++) cq_theta(&q, .1);
;       return cq_measure(q);
;     }
;
; and `@slice_xor`, the do-while twin `int i = 0; do { q ^= 3; } while (++i < n);`.
;
; THE DEFECT (main 7b4e6359, both declined `control flow under quantum
; control`). The park's condition compare `%4 = icmp sgt %3, 5` reads the
; rail's ROOT before the loop. `tryCaseA`'s CLOSURE refused it (a non-rail
; reader), so the loop was unclaimed, its header and exit φs survived to
; `classifyAbortPark`, and the sole-live-register guard (which does not cross a
; φ) counted them as second registers.
;
; THE FIX. CLOSURE admits a compare that is an abort park's own condition
; (`isAbortParkCondition`, AbortParkEmit.h: sole user a conditional `br` with a
; recognized noreturn-sink arm, the arm recognizer `classifyAbortPark` asks).
; The park tapes its flag and never strips it, so no adjoint of the compare runs
; after the loop's gates; the record fence asks the compare and the branch where
; the park mints (`railGateBeforeControlUse`). With the φs collapsed the guard
; accepts unchanged. Decline twins: `loop_park_condition_reject_stale_flag.ll`
; (the flag names the pre-loop register) and
; `loop_park_condition_reject_cross_block.ll` (a fresh compare, but the park's
; branch lies past an in-place xor).
;
; TRACE ARGUMENT (h = q's register, g the graveyard, t the tape):
;   Ry(h,.5); f = [h > 5]; cswap(f, h, g); tape_write(t, f) — the park, exactly
;   the no-loop park's stream. On f = 1 the source aborts (the tape marks the
;   branch); on f = 0 h still holds q (<= 5) and the loop's Ry(.1) x n (resp.
;   xorc(h, 3) x max(n,1)) act on it in place, then measure(h). The loop reads
;   and writes only h, the register the park left holding the survivor. Linked
;   and run from C (n = 2 and n = 0; the do-while n = 2): byte-identical to the
;   agent-E experiment's traces, stage 2b `0 violation(s)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
declare void @abort() noreturn
declare i32 @llvm.smax.i32(i32, i32)

define i32 @slice(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = icmp sgt i32 %3, 5
  br i1 %4, label %7, label %5

5:
  %6 = icmp sgt i32 %1, 0
  br i1 %6, label %11, label %8

7:
  tail call void @abort()
  unreachable

8:
  %9 = phi i32 [ %3, %5 ], [ %14, %11 ]
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9)
  ret i32 %10

11:
  %12 = phi i32 [ %15, %11 ], [ 0, %5 ]
  %13 = phi i32 [ %14, %11 ], [ %3, %5 ]
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 1.000000e-01)
  %15 = add nuw nsw i32 %12, 1
  %16 = icmp eq i32 %15, %1
  br i1 %16, label %8, label %11
}

define i32 @slice_xor(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = icmp sgt i32 %3, 5
  br i1 %4, label %7, label %5

5:
  %6 = tail call i32 @llvm.smax.i32(i32 %1, i32 1)
  br label %8

7:
  tail call void @abort()
  unreachable

8:
  %9 = phi i32 [ %11, %8 ], [ %3, %5 ]
  %10 = phi i32 [ %12, %8 ], [ 0, %5 ]
  %11 = xor i32 %9, 3
  %12 = add nuw nsw i32 %10, 1
  %13 = icmp eq i32 %12, %6
  br i1 %13, label %14, label %8

14:
  %15 = tail call i32 @cq_measure_si32(i32 noundef %11)
  ret i32 %15
}

; CHECK-LABEL: define i32 @slice(
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK-NEXT: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %[[G]])
; CHECK-NEXT: call i32 @cqrt_tape_write_i1(i32 %[[T]], i32 %[[F]])
; CHECK-NOT: cqrt_free
; CHECK: %[[N:[0-9]+]] = icmp sgt i32 %1, 0
; CHECK-NEXT: br i1 %[[N]], label %[[LOOP:[0-9]+]], label %[[EXIT:[0-9]+]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[EXIT]]:
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32 %[[M]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[LOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 1.000000e-01)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32
; CHECK-NEXT: br i1
; CHECK-NEXT: {{^}}}
;
; CHECK-LABEL: define i32 @slice_xor(
; CHECK-NEXT: %[[XT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK-NEXT: %[[XH:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[XH]], double 5.000000e-01)
; CHECK-NEXT: %[[XF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[XH]], i32 5)
; CHECK-NEXT: %[[XG:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_cswap(i32 %[[XF]], i32 %[[XH]], i32 %[[XG]])
; CHECK-NEXT: call i32 @cqrt_tape_write_i1(i32 %[[XT]], i32 %[[XF]])
; CHECK-NOT: cq_template_xor
; CHECK: call void @cqrt_xorc_i32(i32 %[[XH]], i32 3)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32
; CHECK-NEXT: br i1
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}{{[0-9]+}}:
; CHECK-NEXT: %[[XM:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[XH]])
; CHECK-NEXT: ret i32 %[[XM]]
