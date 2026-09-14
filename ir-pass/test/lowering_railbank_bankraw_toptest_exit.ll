; lowering_railbank_bankraw_toptest_exit.ll — the `BankRaw` VERDICT ANCHOR, clause
; C7(b)'s SINGLE-EXITING-BLOCK conjunct (bd `test_C_libtooling-de8n`, 2026-09-15).
;
; ⚠ THIS FIXTURE EXISTS BECAUSE THE INJECTION MATRIX SAID IT WAS MISSING. Mutant
; M3 — "drop the `getExitingBlock() == Latch` conjunct" — was **MISSED** by all 44
; railbank fixtures on the first pass (`trackA/IMPL_A.md` §5). The matrix is the
; instrument; this file is what it bought.
;
; ⚠ AND THE CONJUNCT IS NOT A STRUCTURAL NICETY — IT CATCHES A CELL THAT IS
; PROVABLY NEVER WRITTEN WHILE C6's OWN COUNTING PASSES. The loop below is
; TOP-TESTED: the exit test is in `%head` and `%latch` only increments, so
; `getExitingBlock()` is `%head`, `getLoopLatch()` is `%latch`, and they DIFFER —
; while the store in `%body` still DOMINATES the latch, so C7(b)'s other conjunct
; holds and this file isolates the first.
;
;   header executions (SCEV's `Trips` = BTC + 1) = 4, with i = 0,1,2,3
;   BODY executions                              = 3, with i = 0,1,2
;   N                                            = 4
;
; So C6's `Trips != N` test PASSES and **cell 3 is never written**. After the
; deferred `[4 x i8]` → `[4 x i32]` rewrite it reads as handle `0`, and `h0` is a
; LIVE RAIL in this runtime (`cqrt_alloc_i1(0) -> h0`) — and the `out` block below
; MEASURES exactly that cell, so the hazard is observable in the program as
; written, not only in principle. `Trips` counts HEADER executions; header and body
; executions coincide only when the single exiting block IS the latch.
;
; ⚠ THE LESSON IS L2's, AND IT IS THE SECOND TIME THIS CLAUSE FAMILY HAS TAKEN IT:
; C2′ already asks `getExitingBlock()` to be NON-NULL and stops there, which proves
; there is only ONE way out and says NOTHING about where it is. When a proof is
; complete, ask what OTHER closure re-runs it — here, which EXECUTION COUNT the
; proof is actually about.
;
; MEASURED, ORACLE vs SUBJECT, on the SAME file:
;   ORACLE   cq-opt 0e280fc6…  ->  carve=[Bank] cells=4     promo=0   <-- THE DEFECT
;   SUBJECT  cq-opt b6554935…  ->  carve=[BankRaw] cells=4  promo=0
;
; ⚠ STILL A DECLINE, AND THE DECLINE DID NOT MOVE — `BankRaw` sets no `outMsg` and
; the module keeps the generic `cq taint escape: tainted value stored to memory` it
; took on the ORACLE. The env-gated `CQ_CTRL_DBG` anchor is the only observable
; (Rule 12 hygiene defect (c)); `--implicit-check-not` closes the other direction.
;
; ⚠ HAND-IR, AND THE REASON IS MEASURED RATHER THAN ASSERTED — say it in the form
; the measurement supports. Every `-O1` bank module this track compiled puts the
; exit test AT THE LATCH: `h1_customer.c`, `p1_cond_store_no_read.c`,
; `p2_uncond_store_no_read.c` and `c1_readcell1_inloop.c` each emit only
; latch-terminating conditional branches carrying `!llvm.loop` (4/4/4/2 of them,
; counted). So I could not produce the top-tested shape from C on this floor, and
; this file is hand-IR. **That is NOT a proof that `-O1` can never emit it**, and
; it is not a reason to drop the conjunct: the carve runs on whatever module
; reaches it — hand-written `.ll`, a `clang` bump, any future front end — and
; `CLAUDE.md` Rule 9's first sentence is that stock LLVM IR is not stable. It IS a
; reason to keep the conjunct CHEAP, which two pointer comparisons are.
;
; ⚠ L8 RETIREMENT TRIGGER: when the L-1a taint rule + type rewrite + D5 allow-list
;   land, `Bank` stops falling through to `kMsgStore`. THIS FILE DOES NOT BECOME AN
;   ACCEPT — it is `BankRaw`, and `BankRaw` must keep declining in every future
;   half. Cell 3 of this program is unwritten in any lowering.
;
; SOURCE: `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackA/probes/p5_toptest_exit_not_latch.ll`, verbatim.
;
; RUN: env CQ_CTRL_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s --implicit-check-not='railbank [Bank]' --implicit-check-not='cq rail bank:'
; CHECK: CQ_CTRL_DBG: railbank [BankRaw] cells=4 abi=i8 trips=4 at:
; CHECK: cq taint escape: tainted value stored to memory

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
declare zeroext i1 @cq_measure_i1(i1 zeroext)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main() {
entry:
  %b = alloca [4 x i8], align 1
  call void @llvm.memset.p0.i64(ptr nonnull align 1 %b, i8 0, i64 4, i1 false)
  br label %head
head:
  %i = phi i64 [ 0, %entry ], [ %i.next, %latch ]
  %a = phi i32 [ 5, %entry ], [ %a.next, %latch ]
  %done = icmp eq i64 %i, 3
  br i1 %done, label %out, label %body
body:
  %g = getelementptr inbounds [4 x i8], ptr %b, i64 0, i64 %i
  %q = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %z = zext i1 %q to i8
  store i8 %z, ptr %g, align 1
  %am3 = add nsw i32 %a, -3
  %a.next = select i1 %q, i32 %am3, i32 %a
  br label %latch
latch:
  %i.next = add nuw nsw i64 %i, 1
  br label %head
out:
  %m = call i32 @cq_measure_si32(i32 %a)
  %g3 = getelementptr inbounds [4 x i8], ptr %b, i64 0, i64 3
  %r3 = load i8, ptr %g3, align 1
  %t3 = trunc nuw i8 %r3 to i1
  %m3 = call zeroext i1 @cq_measure_i1(i1 %t3)
  %z3 = zext i1 %m3 to i32
  %s = add nsw i32 %m, %z3
  ret i32 %s
}
