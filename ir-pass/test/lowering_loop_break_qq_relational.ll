; lowering_loop_break_qq_relational.ll — POSITIVE emission (Phase 7.4 Inc 2, epic
; y05j; coverage rxx8). The ASYMMETRIC sibling of lowering_loop_break_qq.ll: a
; value-arm `break` whose tainted Q==Q condition is a RELATIONAL `q < p` (icmp
; slt) rather than the symmetric `q == p` (icmp eq). Source shape:
;
;     int p = cq_theta(pseed, 0.5);   // second, loop-invariant qubit
;     int q = cq_theta(x, 0.25);
;     for (int i = 0; i < n; i++) {
;         q = q ^ 9;                  // in-place value rail self-update
;         if (q < p) break;           // ASYMMETRIC relational Q==Q break flag
;     }
;     return cq_measure(q);
;
; WHY THIS LOCKS A BLIND SPOT THE SYMMETRIC `eq` CANNOT: `cloneBreakCond`
; (BreakReversePlay.cpp) re-emits the break-cond template into the backward
; reverse-play loop. For the adjoint `C†` to recompute `fire' ≡ fire`, the clone
; must preserve the EXACT OPERAND ORDER — `cq_template_icmp_slt_i32(%rail, %p)` in
; the SAME (rail, p) order forward AND in `cq.brk.rev`. A flipped clone would emit
; `slt(%p, %rail)` = the COMPLEMENTARY comparison (`p < rail`), a DIFFERENT predicate
; that recomputes the WRONG `fire'` ⇒ R/idx un-captured on the wrong branch ⇒ a
; dirty `cqrt_free` (Rule-6 hidden measurement) — a verify-clean silent miscompile.
; The symmetric `eq` (eq(a,b) == eq(b,a)) is structurally INCAPABLE of catching an
; operand-order regression; only an asymmetric predicate (slt/ult/…) pins it. `p` is
; loop-INVARIANT and left allocated (Rule 6, see lowering_loop_break_qq.ll).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PLEAK < %t.cqd0.ll
;
; --- the rail (%h1) + the second qubit p (%h), bound at their alloc points ---
; CHECK: %[[P:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %pseed)
; CHECK: call void @cqrt_ry_i32(i32 %[[P]], double 5.000000e-01)
; CHECK: %[[RAIL:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; --- FORWARD body: in-place rail xor, then the ASYMMETRIC slt(rail, p) + its _unc -
; CHECK: call void @cqrt_xorc_i32(i32 %[[RAIL]], i32 9)
; CHECK: %[[FCMP:[a-z0-9_]+]] = call i32 @cq_template_icmp_slt_i32(i32 %[[RAIL]], i32 %[[P]])
; CHECK: call void @cqrt_toffoli(i32 %[[FCMP]],
; CHECK: call void @cq_template_icmp_slt_i32_unc(i32 %[[FCMP]], i32 %[[RAIL]], i32 %[[P]])
; --- BACKWARD reverse-play clone: the SAME slt in the SAME (rail, p) order + _unc --
; CHECK: cq.brk.rev:
; CHECK: %[[BCMP:[a-z0-9_]+]] = call i32 @cq_template_icmp_slt_i32(i32 %[[RAIL]], i32 %[[P]])
; CHECK: call void @cqrt_toffoli(i32 %[[BCMP]],
; CHECK: call void @cq_template_icmp_slt_i32_unc(i32 %[[BCMP]], i32 %[[RAIL]], i32 %[[P]])
; --- the inverse rail-mut closes the reverse-play; R/idx freed, out measured ----
; CHECK: call void @cqrt_xorc_i32(i32 %[[RAIL]], i32 9)
; CHECK: cq.brk.tail:
; CHECK: call void @cqrt_free(i32 %cq.brk.R)
; CHECK: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
; The two CHECK-NOTs mirror LIVE diagnostics (documentary on this -S stdout stream —
; a decline regression is caught by the positive CHECKs failing on empty stdout).
; CHECK-NOT: cq controlled lowering: loop under quantum control
; CHECK-NOT: cq loop lowering: early break body is not a provable rolled single-rail loop
;
; --- p (the second qubit) is NEVER freed — left allocated-clean (Rule 6) -------
; PLEAK: %[[P2:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %pseed)
; PLEAK-NOT: cqrt_free(i32 %[[P2]])

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_qq_rel(i32 %x, i32 %pseed, i32 %n) {
entry:
  %p = call i32 @cq_theta_si32(i32 %pseed, double 5.000000e-01)   ; second invariant qubit
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted value-mutating rail
  %qn = xor i32 %q, 9                                ; value mutation (tainted)
  %brk = icmp slt i32 %qn, %p                        ; ASYMMETRIC relational Q==Q break flag
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                    ; CLASSICAL loop bound
  %exit.cond = select i1 %brk, i1 true, i1 %bound    ; FUSED select(brk, true, bound)
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; value-class escaping answer
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
