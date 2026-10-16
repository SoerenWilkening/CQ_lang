; loop_acc_reject_dead_escaped.ll — DECLINE (bd test_C_libtooling-01po.19.18.1; ruling
; ruling-01po19-18-dead-accumulator-leak-warn-2026-10-16): the gate SET of the
; dead-accumulator postcondition includes ESCAPES.
;     int f(int n) { int q = 0; cq_theta(&q, 1.0); int acc = 0;
;                    for (i < n) acc += q;   return q; }      // q escapes
; `acc` is the seeded accumulator and is never read after the loop: a dead record
; of `q`. `q` then leaves the function as a register handle, where the CALLER may
; move it non-diagonally; "its sources are only measured afterwards" cannot be
; proved, so the leak-with-warning of option (a) must not apply: loud.
; MEASURED: the refusal arrives BEFORE the postcondition's escape class
; (`kMsgDeadAccumulatorEscaped`, "... records a register that escapes after its
; last read"): in a helper the dead-record discipline places `acc`'s discharge
; after its last use, inside the loop, and FreePoint refuses the back edge. In
; `main` a returned register is `declineTaintedMainReturns`'; a store or an
; unknown callee is `declineTaintEscapes`'. The escape class is the backstop for
; an escape none of those owners sees; this file pins that the shape is loud.
; RETIREMENT TRIGGER: bd 8h7d.20's post-loop reverse loop uncomputes `acc` before
; the `ret`; this becomes an accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq uncompute: tainted handle live range crosses a loop backedge

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define i32 @f(i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %acc = phi i32 [ 0, %entry ], [ %accn, %loop ]
  %accn = add i32 %acc, %q
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %loop, !llvm.loop !0

exit:
  ret i32 %q
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
