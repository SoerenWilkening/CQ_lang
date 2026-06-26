; lowering_reject_break_addrail_prevalue.ll — DECLINE (Phase 7.4 Inc 2, y05j.2;
; the CRITICAL Rule-13 finding 2026-06-26 — E8). An ADD-rail value-arm break whose
; break-cond reads the rail HEADER PHI (the PRE-increment value), NOT the
; post-mutation rail. `clang -O1` strength-reduces a RELATIONAL add break —
; `q = q + 3; if (q > 100) break;` — into `icmp sgt(headerphi, 97)`: the break-cond
; consumes the pre-increment rail phi directly, while the answer (the exit merge
; phi) carries the POST value `%qn`.
;
; The dtzb collapse RAUWs the header phi onto the ONE in-place handle, and the
; `cqrt_addc` mutation runs BEFORE the break-cond template in program order — so a
; naive emission would read the POST value (`q_post > 97`) instead of the intended
; `q_pre > 97` (= `q_post > 100`), FIRING ONE ITERATION TOO EARLY: a verify-clean
; WRONG UNITARY (off by the stride). The pre/post distinction is unrecoverable
; after the collapse. E8 guards it: the rail header phi must be consumed ONLY by the
; in-place rail-mutation chain; here it is ALSO read by `%brk` (a non-mutation
; consumer of the pre-increment value) ⇒ LOUD decline (Prime Directive: over-
; declining is safe). The canonical xor break reads the POST value and is
; unaffected (lowering_loop_break_value.ll). Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: cqrt_copy_i32_controlled

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_addrail_pre(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted add rail (header phi)
  %qn = add i32 %q, 3                                ; in-place add mutation
  %brk = icmp sgt i32 %q, 97                         ; STRENGTH-REDUCED: reads %q (PRE-add)
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n
  %exit.cond = select i1 %brk, i1 true, i1 %bound
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; answer = POST value %qn
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
