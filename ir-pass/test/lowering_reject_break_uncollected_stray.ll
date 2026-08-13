; lowering_reject_break_uncollected_stray.ll — DECLINE (bd test_C_libtooling-9g9n).
; THE CLAUSE-(B) HALF of the break reverse-play's post-lowering body-coverage gate: an
; uncollected call in the body that feeds NOTHING the break-cond chain reads.
;
; WHY THIS FIXTURE EXISTS AND WHAT IT HONESTLY PINS. The gate has two clauses, and the
; full red-green matrix was MEASURED by disabling each clause in turn and rebuilding
; (not inferred — an earlier draft of this very paragraph asserted the wrong half):
;
;     fixture                          (A) only     (B) only     both
;     uncollected_clone.ll             decline      decline      decline
;     uncollected_mint.ll              decline      decline      decline
;     uncollected_stray.ll (this one)  rc=0 LOWERS  decline      decline
;
; So clause (B) SUBSUMES clause (A) on every input anyone has been able to reach, and
; this fixture is the only one that discriminates either clause — it pins (B). The
; reason (B) subsumes (A) is structural, not accidental: every reachable uncollected
; producer is a CALL (a Phase-6 clone, a select-merge `cqrt_alloc`), and (B) sweeps
; every call while (A) sweeps only operands.
;
; CLAUSE (A) THEREFORE HAS NO DISCRIMINATING FIXTURE, and that is stated rather than
; papered over. It is kept because it is the PRECISE statement of the dangling
; invariant, where (B) is a coarse over-approximation that happens to cover it today.
; (A) uniquely covers two shapes (B) structurally cannot see: a body-defined NON-call
; operand of a collected gate, and a rail-gate operand that IS a collected break-cond
; call (`emitInverseCall` remaps nothing, so a collected operand still dangles there —
; the per-mechanism closure sets). Both are unreachable today, the first because E9
; partitions break-cond operands into untainted-Header-defined (declines) and tainted
; (which lowers to a `cq_template_*` call, hence collected), the second because rail
; immediates are fenced loop-invariant by E10. If a future minting stage produces a
; non-call body value, (A) is what catches it and (B) is what misses it.
;
; AND STATE ITS REACH EXACTLY, because the honest version is the useful one: NO input is
; known to reach clause (B) without clause (A) firing first, from C at any `-O` level.
; There are two disjoint routes to a stray body call and BOTH are closed, which is what
; makes this defense-in-depth rather than a live hole:
;
;   * MINTED (a stage adds the call after the loop is claimed) — the only post-claim
;     minting stage that survives its upstream fences is the 4.4 select merge
;     (`lowerControlRegions`, step 292), and its merged rail is necessarily an ARGUMENT
;     of a collected gate, so (A) wins the race every time. `lowerIOSinks` (317) needs a
;     side-effecting call and `lowerQramReads` (327) / `lowerShadowMemory` (339) need a
;     tainted-index memory access; LoopLowering's B4 body fence rejects both, so the
;     loop is never claimed.
;   * SOURCE-LEVEL (the call is written in the loop, as in THIS fixture) — closed by a
;     complementary pair, which is why no C program reaches it: if the call has side
;     effects, B4 declines the loop; if it does not, then either its result is unused
;     and `clang` DCEs it, or it is loop-invariant and LICM hoists it out of a
;     header==latch body, or its result IS used — at which point every use site is
;     already fenced (break-cond operand → E9, rail immediate → E10, counter → E3,
;     bound → E4, escaping classical → the recognizer declines). Measured: the
;     `extern __attribute__((const))` and `((pure))` variants, with loop-invariant and
;     loop-variant arguments, all decline UPSTREAM and identically before and after this
;     change ("loop under quantum control" / "early break body is not a provable rolled
;     single-rail loop").
;
; So this fixture is hand-written lowered-adjacent IR rather than a C program by
; necessity, not by convenience. Do not upgrade this prose to a reachability claim
; without a C reproducer to back it.
;
; THE SHAPE. This is `lowering_loop_break_value.ll` — the canonical accepted value-arm
; break, unchanged — plus ONE extra call in the loop body: a `memory(none)
; nounwind willreturn` classical helper whose result nothing uses. It is invisible to
; every earlier fence: B4 admits it (no side effects), E9 never sees it (it is not in
; the break flag's lineage), and E11 skips it (E11 sweeps only TAINTED body values and
; this one is untainted). It reaches `discoverLoweredBreak`, which collects the rail
; gate and the break-cond chain and simply does not mention it — the residue clause (B)
; exists to see.
;
; NOTE WHAT IS BEING DECLINED, so nobody "fixes" it later by narrowing the predicate.
; A purely classical side-effect-free call carries NO rail, is never re-emitted into
; `cq.brk.rev`, is not an operand of any collected gate, and — being pure — is
; unobservable when the virtualized break runs the body its full trip count instead of
; stopping early. Pre-change this module lowered correctly and verify-clean. So clause
; (B) genuinely OVER-declines here, which is safe and deliberate (Prime Directive), and
; the tempting narrowing — restrict (B) to a `cqrt_` / `cq_template_` / `__cq_q_` name
; prefix, or to `taint.Tainted` membership — is exactly the mistake that created bd
; 9g9n: a NAME-PREFIX test over a re-emission gate is what made `isBreakCondTemplate`
; and `isInverseEmittable` incomparable and let the Phase-6 clone through. A broad
; structural predicate that declines a harmless call is the correct trade here.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; Pure and unused — no side effects, no taint, no rail. Untouched by B4, E9 and E11.
declare i32 @stray_pure(i32) #0

define i32 @break_stray_call(i32 %x, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %loop, label %exit

loop:                                             ; preds = %entry, %loop
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]      ; classical induction
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]       ; tainted value-mutating rail
  %qn = xor i32 %q, 9                                ; value mutation (tainted)
  %stray = call i32 @stray_pure(i32 %i)              ; UNCOLLECTED, feeds nothing
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

attributes #0 = { nounwind willreturn memory(none) }

; CHECK: error:
; CHECK-SAME: cq loop lowering: break reverse-play cannot re-emit an uncollected body value

; CHECK-NOT: Instruction does not dominate all uses
; CHECK-NOT: Broken module found
