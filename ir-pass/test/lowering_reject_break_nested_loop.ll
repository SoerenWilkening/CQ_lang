; lowering_reject_break_nested_loop.ll — DECLINE (Phase 7.4 Inc 1, y05j.1; PRD-7.4
; §2.7, §2.10 nested row): a value-arm early break inside an INNER loop of a nested
; quantum loop nest:
;     int q = cq_theta(x, 0.25);
;     for (int i = 0; i < n; i++)
;         for (int j = 0; j < m; j++) {
;             q = q ^ 9;
;             if ((q & 1) == 0) break;   // tainted break in the INNER loop
;         }
;     return cq_measure(q);
;
; Verified against real `clang -O1` output (Rule 11, /tmp/spike/v6_nested.ll, which
; emits the successor-swapped CONTINUE-polarity fused form `select(not-brk, not-bound,
; false)` — both polarities are decomposed). The INNER loop's break is itself a clean
; single value-arm break, but `Loop::getParentLoop()` is non-null: the break crosses
; into a nested quantum loop. Whole-loop reverse-play (§2.3) over a loop NESTED in
; another quantum loop is an unproven interaction; nested break is blocked-on the
; 7.3 nested-quantum-loop SUBSTRATE (lifting `markIfIterationLocal`'s nested guard,
; its own Rule-13 hazard) ⇒ DECLINE → defer (§2.7). `tryBreak` confirms the break
; SHAPE first (so a genuinely quantum-bounded nested loop stays L1, not relabeled
; "nested break"), then declines on nesting. Decline-safe today (Prime Directive).
; Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break across nested loops

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_nested(i32 %x, i32 %n, i32 %m) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  br label %outer

outer:                                            ; preds = %entry, %outer.latch
  %oi = phi i32 [ 0, %entry ], [ %oinext, %outer.latch ]
  %q.outer = phi i32 [ %q0, %entry ], [ %q.inner.out, %outer.latch ]
  br label %inner

inner:                                            ; preds = %outer, %inner
  %ii = phi i32 [ 0, %outer ], [ %iinext, %inner ]
  %q.inner = phi i32 [ %q.outer, %outer ], [ %qn, %inner ]
  %qn = xor i32 %q.inner, 9
  %a0 = and i32 %qn, 1
  %brk = icmp eq i32 %a0, 0                        ; TAINTED break flag (inner)
  %iinext = add nuw nsw i32 %ii, 1
  %ibound = icmp eq i32 %iinext, %m               ; CLASSICAL inner bound
  %iexit = select i1 %brk, i1 true, i1 %ibound    ; FUSED inner exit
  br i1 %iexit, label %inner.exit, label %inner

inner.exit:                                       ; preds = %inner
  %q.inner.out = phi i32 [ %qn, %inner ]
  br label %outer.latch

outer.latch:                                      ; preds = %inner.exit
  %oinext = add nuw nsw i32 %oi, 1
  %obound = icmp eq i32 %oinext, %n               ; CLASSICAL outer bound
  br i1 %obound, label %final, label %outer

final:                                            ; preds = %outer.latch
  %res = call i32 @cq_measure_si32(i32 %q.inner.out)
  ret i32 %res
}
