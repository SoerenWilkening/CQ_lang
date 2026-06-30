; lowering_reject_break_escape_not_rail.ll — DECLINE (Phase 7.4 Inc 2, y05j.2; the
; Rule-13 RE-review 2026-06-27 — the escape≠rail silent-miscompile fix, E13). The
; escaping/measured answer is a break-cond-DERIVED function of the rail (`t = q*7`),
; NOT the rail's final value `RailLat` (`%qn = q ^ 5`). `mul` is information-losing
; (no in-place reversible form), so `%t` is NOT a rail op — it is a legitimate
; break-cond op (E9) that E8/E11 admit, and the escape phi may carry it. But the
; post-lowering capture (BreakReversePlay.cpp captureRailToR / emitExitConsolidation)
; unconditionally copies the in-place RAIL handle `%h` into `R` and then into `out`
; (the RAUW'd escape phi), so `out` would receive the RAIL value `q^5` instead of the
; measured answer `t = (q^5)*7` — a VERIFY-CLEAN WRONG UNITARY, off by the whole `*7`
; derivation. (Idiomatic-C-reachable: `t = q*7; if((t&8)==0) break; return measure(t)`.)
; E13 requires the escape phi's loop-latch incoming to BE `RailLat`; here it is `%t`
; (≠ `%qn`) ⇒ LOUD decline. The canonical `return measure(q)` shapes carry `RailLat`
; itself (lowering_loop_break_*) and still lower. Mirror-exact (Rule 12).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: early break body is not a provable rolled single-rail loop
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: cqrt_copy_i32_controlled

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_escderiv(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %qn = xor i32 %q, 5                                ; RailLat (rail's final value)
  %t = mul i32 %qn, 7                                ; DERIVED answer t = f(rail), NOT a rail op
  %a0 = and i32 %t, 8                                ; break-cond reads the derived %t
  %brk = icmp eq i32 %a0, 0
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n
  %exit.cond = select i1 %brk, i1 true, i1 %bound
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %t, %loop ]      ; answer = DERIVED %t, NOT RailLat %qn
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
