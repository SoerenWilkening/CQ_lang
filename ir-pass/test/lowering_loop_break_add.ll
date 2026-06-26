; lowering_loop_break_add.ll — POSITIVE emission (Phase 7.4 Inc 2, y05j.2): the
; ADD-rail value-arm break, exercising the dtzb `cqrt_addc` reverse-play adjoint
; (the immediate-NEGATE branch deferred from dtzb to y05j.2). A classically-bounded
; loop whose in-place value rail is mutated by `q = q + 3` and whose tainted
; value-arm break reads the POST-mutation rail (`(q+3) & 1`):
;
;     int q = cq_theta(x, 0.25);
;     for (int i = 0; i < n; i++) {
;         q = q + 3;                 // in-place add rail
;         if ((q & 1) == 0) break;   // break-cond reads the POST-add value
;     }
;     return cq_measure(q);
;
; This is the IR-level vehicle (a hand-written, NON-strength-reduced add break):
; `clang -O1` either strength-reduces a RELATIONAL add break into one that reads
; the PRE-increment header phi (declined by E8, see
; lowering_reject_break_addrail_prevalue.ll) or folds a parity add break away
; entirely, so the addc reverse-play is reached only via non-strength-reduced IR —
; exactly as the dtzb forward add path (lowering_loop_value_accum_add.ll).
;
; The rail collapses to ONE in-place handle; the forward body mutates it with
; `cqrt_addc_i32(%h, 3)`; the BACKWARD reverse-play companion loop un-mutates it
; with the immediate-NEGATE adjoint `cqrt_addc_i32(%h, -3)` (NOT a fresh-minting
; `_inv` / `_unc`). The index-gated capture + copy-out + frees are identical to the
; xor case (lowering_loop_break_value.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; CHECK: call void @cqrt_addc_i32(i32 %[[H:[a-z0-9]+]], i32 3)
; CHECK: call void @cqrt_toffoli(
; CHECK: call void @cqrt_copy_i32_controlled(i32 %{{.*}}, i32 %[[H]], i32 %cq.brk.R)
; CHECK: cq.brk.rev:
; CHECK: call void @cqrt_addc_i32(i32 %[[H]], i32 -3)
; CHECK: cq.brk.tail:
; CHECK: call void @cqrt_free(i32 %cq.brk.R)
; CHECK: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
; CHECK-NOT: cq loop lowering: early break body is not a provable rolled single-rail loop

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_add(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction (start 0)
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted in-place add rail
  %qn = add i32 %q, 3                                ; value mutation (in-place)
  %a0 = and i32 %qn, 1                               ; break-cond reads POST (%qn)
  %brk = icmp eq i32 %a0, 0                          ; TAINTED break flag
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                    ; CLASSICAL loop bound
  %exit.cond = select i1 %brk, i1 true, i1 %bound    ; FUSED select(brk, true, bound)
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; value-class escaping answer
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
