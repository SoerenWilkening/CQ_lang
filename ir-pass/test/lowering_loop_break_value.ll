; lowering_loop_break_value.ll — POSITIVE recognition (Phase 7.4 Inc 1, y05j.1;
; PRD-7.4 §2.5 B1-B5, §2.10 accept row): a classically-bounded, DATA-MUTATING
; loop with a SINGLE tainted-condition value-arm early break, measured after:
;     int q = x; cq_theta(&q, 0.25);
;     for (int i = 0; i < n; i++) {
;         q = q ^ 9;                 // value mutation (the dirty rail)
;         if ((q & 1) == 0) break;   // TAINTED value-arm break
;     }
;     return cq_measure(q);
;
; Verified against real `clang -O1` output (Rule 11, /tmp/spike/v1_value.ll): the
; tainted break flag (`%brk`) and the CLASSICAL loop bound (`%bound = icmp eq
; %i.next, %n`) are FUSED into one `select(%brk, i1 true, %bound)` exit, so the
; loop-exit branch is TAINTED — today (7.3) indistinguishable by terminator-taint
; alone from a genuinely quantum-bounded `while(q<k)`, and both decline identically
; via the L1 `loop under quantum control` (PRD-7.4 §1.1).
;
; Increment 2 (y05j.2) — the EMISSION (the index-gated copy-not-move capture +
; whole-loop reverse-play, §2.2/§2.3). `tryBreak`/`emitBreakForward` collapses the
; rail to ONE in-place handle (`cqrt_xorc_i32(%h, 9)`), strips the loop terminator
; to the CLASSICAL bound (the rolled loop runs its full trip count — the break is
; virtual), mints `R`/`idx`/`out`, and RAUWs the exit phi → `out`. The post-lowering
; `lowerBreakReversePlay` then emits, in the body, the index-gated capture
; (`fire = brk ∧ (idx==0)` via `cqrt_toffoli`; `cqrt_copy_i32_controlled(fire, %h,
; R)` — rail INTACT) with the per-iteration scratch uncomputed in-iteration; at the
; exit, the `idx==0` consolidation + `cqrt_copy_i32(R, out)` copy-out; and a
; BACKWARD-counted reverse-play companion loop (`cq.brk.rev`) — the whole-loop
; adjoint (note the inverse rail-mut `cqrt_xorc_i32(%h, 9)` at its tail) that
; returns `R`/`idx`/rail to their pre-capture state — then `cqrt_free` of `R`/`idx`
; and the measure of the disentangled `out`. ZERO measurements inserted; the rail is
; left allocated (Rule 6). Partition still holds: NOT the L1 quantum-bounded decline.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; CHECK: call void @cqrt_xorc_i32(i32 %[[H:[a-z0-9]+]], i32 9)
; CHECK: call void @cqrt_toffoli(
; CHECK: call void @cqrt_copy_i32_controlled(i32 %{{.*}}, i32 %[[H]], i32 %cq.brk.R)
; CHECK: call void @cqrt_copy_i32(i32 %cq.brk.R, i32 %cq.brk.out)
; CHECK: cq.brk.rev:
; CHECK: call void @cqrt_xorc_i32(i32 %[[H]], i32 9)
; CHECK: cq.brk.tail:
; CHECK: call void @cqrt_free(i32 %cq.brk.R)
; CHECK: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
; The two CHECK-NOTs mirror LIVE diagnostics (rxx8: the second was the retired
; kMsgBreakPending, swapped for the live break-emit decline kMsgBreakUnemittable).
; Documentary here — diagnostics land on stderr, not this -S stdout stream — but a
; regression to either decline is still caught: the positive CHECKs fail on the
; empty stdout opt emits on a loud decline.
; CHECK-NOT: cq controlled lowering: loop under quantum control
; CHECK-NOT: cq loop lowering: early break body is not a provable rolled single-rail loop

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_value(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted value-mutating rail
  %qn = xor i32 %q, 9                                ; value mutation (tainted)
  %a0 = and i32 %qn, 1
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
