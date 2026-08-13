; lowering_reject_break_uncollected_mint.ll — DECLINE (bd test_C_libtooling-9g9n).
; THE POST-LOWERING BODY-COVERAGE GATE of the 7.4 break reverse-play, entry path (2):
; a producer minted into an ALREADY-CLAIMED loop body by a stage that runs AFTER the
; pre-lowering coverage check.
;
; THIS IS THE STRUCTURAL HALF OF THE BUG, and it is why the fix cannot be a smarter
; discovery predicate. Path (1) (`lowering_reject_break_uncollected_clone.ll`) is a
; producer that EXISTS at E11 time and is mis-classified. This one does not exist at
; E11 time AT ALL: E11 runs inside `lowerLoops` (CQLoweringPass.cpp step ~279) and the
; 4.4 `SelectMergeEmit` mints `%out = cqrt_alloc_i32(0)` into the body at
; `lowerControlRegions` (step ~292). No amount of care at E11 can see it — which is
; exactly why the gate this fixture pins is stated POST-lowering, at step 382, the one
; point where nothing further is minted.
;
; FOUR STAGES SIT IN THAT WINDOW; EXACTLY ONE IS DEMONSTRATED TO REACH A CLAIMED BODY.
; An earlier draft said "the same hole is open to EVERY stage between the claim and the
; reverse-play" and listed `lowerIOSinks` (317), `lowerQramReads` (327) and
; `lowerShadowMemory` (339) alongside 292. Measured, those three are fenced UPSTREAM of
; the claim and their source constructs never survive to be minted: LoopLowering's B4
; body fence rejects an I/O sink (a side-effecting call) and a tainted-index memory
; access (a GEP/load/store with a tainted operand) alike, so the loop is never claimed.
; `kMsgQramLoop` (QramLowering.cpp) usually declines the QRAM programs even earlier, but
; it is not the guarantee and is not the blanket its name suggests — it carries a
; tainted-control carve-out ahead of its loop test. B4 is what this stage depends on.
; Only the 292 route is real today. The gate's placement at step 382
; is correct on that one route's merits alone; inflating the list would mislead anyone
; sizing the follow-on work, and this fixture already retracted one unverified claim on
; exactly that ground (see the sibling clone fixture on the bead's QROM control).
;
; THE SOURCE, five lines of ordinary C, nothing hand-declared:
;   int f(int x, int n) {
;     int q = cq_theta(x, 0.25);
;     for (int i = 0; i < n; i++) { q ^= 9; int s = (q&1) ? 3 : 5; if ((q & s) == 0) break; }
;     return cq_measure(q);
;   }
; The tainted-condition `select` is a legitimate 4.4 accept (controlled-XOR copy merge);
; E9 records it in `BreakCondOps` (tainted, Header-defined) so E11 whitelists it, and
; the loop is CLAIMED. `SelectMergeEmit` then replaces it with a `|0>` rail `%out` plus
; two `cqrt_copy_i32_controlled` — and `%out` becomes an ARGUMENT of the collected
; `cq_template_and_i32` while being a body definition the chain does not collect.
;
; MEASURED on the pre-fix pass (rc=134, SIGABRT):
;   Instruction does not dominate all uses!
;     %out = call i32 @cqrt_alloc_i32(i32 0)
;     %10  = call i32 @cq_template_and_i32(i32 %out, i32 %h)
;   (+ the same for the `_unc` twin)
;   LLVM ERROR: Broken module found, compilation aborted!
; `cloneBreakCond` remaps ONLY operands it holds a clone for (the `VMap` of collected
; members) and carries every other operand VERBATIM into `cq.brk.rev`, which the forward
; body does not dominate.
;
; NOTE WHICH CLAUSE FIRES, AND DO NOT READ THIS FIXTURE AS PINNING IT. Clause (A)
; (operand closure over every re-emitted gate) is what fires here, at `%out` in the
; `and`'s argument list, because (A) is checked first. But clause (B) catches this
; module too — measured: with (A) disabled this fixture still declines, since `%out`
; and the merge's `cqrt_copy_i32_controlled` are themselves uncollected body calls. So
; this fixture does NOT discriminate (A) from (B); only
; `lowering_reject_break_uncollected_stray.ll` discriminates either clause, and it pins
; (B). See that fixture for the full measured red-green matrix and for why (A) is kept
; despite having no discriminating probe of its own.
;
; SUPPORTING a tainted select inside a break condition is a WIDENING (the merge rails
; would have to be carried into the companion loop's re-emission), tracked under the
; 7.x widenings epic — not this bug, whose whole content is that the crash must become
; a Rule-1 decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @break_uncollected_mint(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %17

5:                                                ; preds = %2, %5
  %6 = phi i32 [ %8, %5 ], [ %3, %2 ]
  %7 = phi i32 [ %14, %5 ], [ 0, %2 ]
  %8 = xor i32 %6, 9                              ; the in-place rail self-update
  %9 = and i32 %8, 1
  %10 = icmp eq i32 %9, 0
  %11 = select i1 %10, i32 5, i32 3               ; 4.4 tainted select → mints `%out`
  %12 = and i32 %11, %8                           ; collected; arg 0 is the minted rail
  %13 = icmp eq i32 %12, 0                        ; the break flag
  %14 = add nuw nsw i32 %7, 1
  %15 = icmp eq i32 %14, %1
  %16 = select i1 %13, i1 true, i1 %15            ; the -O1 fused exit (PRD-7.4 §1.1)
  br i1 %16, label %17, label %5

17:                                               ; preds = %5, %2
  %18 = phi i32 [ %3, %2 ], [ %8, %5 ]
  %19 = tail call i32 @cq_measure_si32(i32 noundef %18)
  ret i32 %19
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; CHECK: error:
; CHECK-SAME: cq loop lowering: break reverse-play cannot re-emit an uncollected body value

; CHECK-NOT: Instruction does not dominate all uses
; CHECK-NOT: Broken module found
