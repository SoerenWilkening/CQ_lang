; lowering_io_controlled_shared_tape.ll — ACCEPT (Phase 7.6 Increment 2): a
; function with BOTH an uncontrolled `printf("%d", x)` AND a controlled `if (q >
; 5) printf("%d", q)` appends to ONE shared stdout tape — never two separate tapes
; (a split transcript is a verify-clean lost-output bug, PRD-7.6 §2.4 / risk #2).
; The controlled step (before control detection) mints the single
; `cqrt_tape_alloc` into the `taint.IOTapeForFn` registry; the uncontrolled step
; (after control lowering) REUSES it. Exactly ONE `cqrt_tape_alloc`, threaded into
; BOTH the controlled and the uncontrolled write. `x` and `q` are distinct tainted
; values (the SAME value used both controlled and uncontrolled over-declines as
; fan-out — the controlled flag mint becomes a co-user; that is a safe decline,
; not this shape).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %x = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %ux = call i32 (ptr, ...) @printf(ptr @.str, i32 %x)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge

arm:                                              ; preds = %entry
  %cr = call i32 (ptr, ...) @printf(ptr @.str, i32 %q)
  br label %merge

merge:                                            ; preds = %arm, %entry
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mx = call i32 @cq_measure_si32(i32 %x)
  ret void
}

; EXACTLY ONE tape alloc; an uncontrolled write of x AND a controlled write of q,
; both threading the SAME %tape handle:
; CHECK:     %[[TAPE:[a-zA-Z0-9_.]+]] = call i32 @cqrt_tape_alloc()
; CHECK-NOT: call i32 @cqrt_tape_alloc()
; CHECK:     call i32 @cqrt_tape_write_i32(i32 %[[TAPE]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_tape_write_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[TAPE]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call{{.*}}@printf
; CHECK-NOT: br i1
