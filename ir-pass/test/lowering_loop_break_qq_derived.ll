; lowering_loop_break_qq_derived.ll — POSITIVE emission (Phase 7.4 Inc 2, epic
; y05j; coverage test_C_libtooling-1784). The DERIVED-COMPARAND sibling of
; lowering_loop_break_qq.ll: a value-arm `break` whose tainted Q==Q condition
; compares the rail against a loop-invariant comparand `p` that is itself a DERIVED
; (non-mint) tainted value — `p = p0 + 5`, an out-of-place template result whose
; producer chain is p0 (cq_theta) -> p (add). Source shape:
;
;     int p0 = cq_theta(pseed, 0.5);
;     int p  = p0 + 5;                // DERIVED loop-invariant comparand (p0 -> p)
;     int q  = cq_theta(x, 0.25);
;     for (int i = 0; i < n; i++) {
;         q = q ^ 9;                  // in-place value rail self-update
;         if (q == p) break;          // TAINTED Q==Q break flag (rail vs derived-p)
;     }
;     return cq_measure(q);
;
; WHY THE DERIVATION CHAIN p0 -> p RIDES INERT AND IS LEFT ALLOCATED (cleared by a
; 5-lens adversarial Rule-13 sign-off 2026-06-30; structurally identical to the
; blessed bare-mint comparand, with the derivation living strictly OUTSIDE the
; permutation): the break construct emits ONLY computational-basis PERMUTATION gates
; (no Ry/Rz/H inside); the lone deriving op `cq_template_add_i32_hl(p0, 5)` is
; PRE-LOOP. Both the derived comparand `p` (=%h_op) AND its ancestor `p0` (=%h) are
; consumed ONLY as operands of the QQ eq-compare (+matched `_unc`) — never rotated,
; copied into `out`, measured, or freed. isTerminalHandle is FALSE for both (p0's
; forward consumer is the add; p's are the live compares) and neither is a
; data-terminal ancestor (the compares feed control toffoli/cnot, not a kept data
; carrier), so the whole-DAG uncompute spine (DagTraversal) never enqueues them: the
; deriving add is NEVER reversed (no cq_template_add_i32_hl_unc) and NEITHER p0 NOR p
; is freed dirty. Both are LEFT ALLOCATED (the Rule-6 safe leak — two entangled rails
; instead of the bare-mint's one). NB the symmetric-XOR fold `p = p0 ^ 3` with an
; xor rail is a DIFFERENT shape: clang -O1 reassociates `(q^9)==(p0^3)` to
; `(q^p0)==10`, making the break-cond read the PRE-mutation rail phi via a two-quantum
; xor — that rides the E8 `kMsgBreakUnemittable` decline (over-declining is safe),
; not this accept.
;
; M-C NOTE (bd test_C_libtooling-6uqc, Increment 2a): the PRE-LOOP derivation
; `p = p0 + 5` lowers IN PLACE, so the derived comparand and its ancestor are ONE
; rail — the shape is now structurally identical to the bare-mint comparand of
; slice_loop_break_qq.c, and the documented safe leak goes from TWO entangled
; rails to ONE. The break construct itself is UNTOUCHED: the in-loop rail
; self-update is still `cqrt_xorc_i32` from `taint.InPlaceRailOps`, which M-C
; refuses by construction (it declines anything already in that set AND anything
; inside a natural loop). MEASURED on the e2e twin: after normalising for the one
; removed rail, the 188-line golden is byte-identical.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=PLEAK < %t.cqd0.ll
;
; --- p0 minted, THEN the pre-loop deriving add p = p0 + 5 (out-of-place template) -
; CHECK: %[[P0:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %pseed)
; CHECK: call void @cqrt_ry_i32(i32 %[[P0]], double 5.000000e-01)
; CHECK: call void @cqrt_addc_i32(i32 %[[P0]], i32 5)
; CHECK: %[[RAIL:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; --- FORWARD body: in-place rail xor, then the bare Q==Q compare (rail vs p) + _unc
; CHECK: call void @cqrt_xorc_i32(i32 %[[RAIL]], i32 9)
; CHECK: %[[FCMP:[a-z0-9_]+]] = call i32 @cq_template_icmp_eq_i32(i32 %[[RAIL]], i32 %[[P0]])
; CHECK: call void @cqrt_toffoli(i32 %[[FCMP]],
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 %[[FCMP]], i32 %[[RAIL]], i32 %[[P0]])
; --- BACKWARD reverse-play clone: the SAME compare reading the SAME derived %p -----
; CHECK: cq.brk.rev:
; CHECK: %[[BCMP:[a-z0-9_]+]] = call i32 @cq_template_icmp_eq_i32(i32 %[[RAIL]], i32 %[[P0]])
; CHECK: call void @cqrt_toffoli(i32 %[[BCMP]],
; CHECK: call void @cq_template_icmp_eq_i32_unc(i32 %[[BCMP]], i32 %[[RAIL]], i32 %[[P0]])
; CHECK: call void @cqrt_xorc_i32(i32 %[[RAIL]], i32 9)
; CHECK: cq.brk.tail:
; CHECK: call void @cqrt_free(i32 %cq.brk.R)
; CHECK: call void @cqrt_free(i32 %cq.brk.idx)
; CHECK: call i32 @cqrt_measure_i32(i32 %cq.brk.out)
; The CHECK-NOTs mirror LIVE diagnostics (documentary on this -S stdout stream — a
; decline regression is caught by the positive CHECKs failing on empty stdout).
; CHECK-NOT: cq controlled lowering: loop under quantum control
; CHECK-NOT: cq loop lowering: early break body is not a provable rolled single-rail loop
;
; --- the deriving add is NEVER reversed, and the comparand rail is never freed
; --- (Rule 6). Since M-C there is ONE such rail, not two: `p` and `p0` are the
; --- same register, so the leak this pins shrank from two entangled rails to one.
; PLEAK: %[[P02:[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %pseed)
; PLEAK: call void @cqrt_addc_i32(i32 %[[P02]], i32 5)
; PLEAK-NOT: cqrt_free(i32 %[[P02]])
; PLEAK-NOT: cqrt_addc_i32(i32 %[[P02]], i32 -5)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @break_qq_derived(i32 %x, i32 %pseed, i32 %n) {
entry:
  %p0 = call i32 @cq_theta_si32(i32 %pseed, double 5.000000e-01)  ; basis superposition
  %p = add i32 %p0, 5                                ; DERIVED loop-invariant comparand
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted value-mutating rail
  %qn = xor i32 %q, 9                                ; value mutation (tainted)
  %brk = icmp eq i32 %qn, %p                         ; TAINTED Q==Q break flag (rail vs derived-p)
  %inext = add nuw nsw i32 %i, 1
  %bound = icmp eq i32 %inext, %n                    ; CLASSICAL loop bound
  %exit.cond = select i1 %brk, i1 true, i1 %bound    ; FUSED select(brk, true, bound)
  br i1 %exit.cond, label %exit, label %loop

exit:                                             ; preds = %loop, %entry
  %ans = phi i32 [ %q0, %entry ], [ %qn, %loop ]     ; value-class escaping answer
  %m = call i32 @cq_measure_si32(i32 %ans)
  ret i32 %m
}
