; lowering_reject_break_uncollected_clone.ll — DECLINE (bd test_C_libtooling-9g9n).
; THE POST-LOWERING BODY-COVERAGE GATE of the 7.4 break reverse-play, entry path (1):
; a Phase-6 SPECIALIZATION CLONE in the break condition.
;
; This is the OTHER direction of the incomparable-predicates class bd zea5 closed. The
; two predicates over one gate are `BreakReversePlay::isBreakCondTemplate` (collect for
; re-emission) and `EmitInverse::isInverseEmittable` (can adjoint). Along the `_inv`
; suffix DISCOVERY IS WIDER — zea5's axis, fixed by a pre-scan over the collected sets.
; Along `@__cq_q_*` DISCOVERY IS NARROWER: `isInverseEmittable` ACCEPTS a specialization
; clone (EmitInverse.cpp, the Phase-6.3 clause) and `isBreakCondTemplate` REJECTS it
; (it requires the `cq_template_` prefix). A pre-scan that iterates the COLLECTED sets
; structurally cannot see a link that was never collected — which is why zea5's fix,
; correct on its own axis, left this one live.
;
; HOW IT SURVIVES EVERY EARLIER FENCE, in order. `detectSpecializations` retargets the
; `noinline` pure `@g` to the clone `@__cq_q_g_1`. LoopLowering's B4 body fence is
; `I.mayHaveSideEffects()` ALONE (LoopLowering.cpp:1112), so a pure call is ADMITTED.
; E9 walks the break flag's lineage and, finding the call TAINTED and Header-defined,
; INSERTS it into `BreakCondOps` and recurses — so E11 (body coverage) whitelists it and
; the loop is CLAIMED. E9's own header comment names this exact failure mode ("a
; dominance violation / broken module") as the thing it prevents: it bails on an
; UNTAINTED Header-defined operand and waves TAINTED ones through, which is sound only
; if every tainted break-cond op is later cloned. `isBreakCondTemplate` is strictly
; narrower than "tainted", so that premise does not hold and the fence written to
; prevent this failure has a hole shaped exactly like it.
;
; WHAT WENT WRONG, MEASURED on the pre-fix pass (this module, from five lines of
; ordinary C at `clang -O1` — no hand-written IR and no hand-declared symbols):
;   Instruction does not dominate all uses!
;     %6  = tail call fastcc i32 @__cq_q_g_1(i32 noundef %h)
;     %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %6, i32 0)
;   (+ the same for the `_unc` twin)
;   LLVM ERROR: Broken module found, compilation aborted!            rc=134 (SIGABRT)
; `discoverLoweredBreak` returns TRUE anyway — it asks only for a rail handle plus one
; compare — so `cloneBreakCond` clones ONLY the compare into the `cq.brk.rev` companion
; block, and the clone's arg 0 still names the FORWARD body's `%6`. The exit merge has
; two predecessors on the recognized shape (B2 requires it), so the body never dominates
; the companion block and the verifier always fires.
;
; SEVERITY, stated honestly: this is a CRASH, not a silent miscompile. The
; non-dominance is structural so it is always loud, `opt` discards its output, and
; `run_slice.sh` is `set -euo pipefail`, so no broken module can reach the linker. But
; an `LLVM ERROR` with a Homebrew bug-report banner is not a Rule-1 source-located
; `DiagnosticInfoUnsupported`, and BreakReversePlay.cpp's own ruling is that a malformed
; module is "a WORSE outcome than the loud decline".
;
; AND THE FIX IS A COVERAGE CHECK, NOT A REPAIR — the hazard is that the comfortable
; fix is the wrong one. Hoisting `%6`, or re-deriving it in the companion block to
; satisfy the verifier, would make the module VERIFY while leaving a rail that is minted
; per iteration, never uncomputed, never freed and never in `ControlOwnedRails` (checked
; with `-disable-verify`: no `@__cq_q_g_1_unc` and no `cqrt_free` naming it anywhere).
; That trades an always-loud abort for a SILENT dephasing of `out` — the one failure
; mode this project does not tolerate for the one it does (Prime Directive).
;
; CONTROLS that establish this is the break-cond POSITION and not the construct — each
; RE-MEASURED against the fixed pass rather than carried over from the bead:
;   * the same helper on a tainted value OUTSIDE a loop        → rc=0 (Phase-6
;     specialization on a tainted value is supported; the loop is what breaks it);
;   * `if ((q & i) == 0) break` (loop-variant comparand)       → rc=1, "cq taint escape:
;     tainted value muxed by a classical-condition …" (declined upstream of the loop
;     recognizer, not by E9 — worth knowing before citing E9 for it);
;   * `q = cq_phi(q, 0.1)` in the body                         → rc=1, "cq loop lowering:
;     early break preserves a phase answer" (Rule 7).
;   * a QROM read in the break condition, `if (T[q & 63] == k) break` with a 64-entry
;     `static const` table and a RUNTIME comparand `k` → rc=1, "cq QRAM access:
;     tainted-index memory access inside a loop".
;
; THAT LAST CONTROL NEEDS ITS SHAPE STATED OR IT DOES NOT REPRODUCE, which is the whole
; reason it is spelled out here. Written the obvious way — a small table against a
; CONSTANT comparand — `clang -O1` folds the lookup away before the pass ever sees it:
; `T[q&7] == 0` on an 8-entry table with a single zero at index 2 becomes
; `icmp eq (and q,7), 2`, an ORDINARY supported break that lowers at rc=0 with no QRAM
; anywhere (measured). An intermediate draft of this fixture concluded from that one bad
; probe that the bead's control was unreproducible and struck it; the Rule-13 round
; rebuilt it correctly and it reproduces exactly as the bead said. Both halves are
; recorded because the failure mode cuts both ways — an unverified control is worse than
; no control, and a control retracted on a botched probe is worse still.
;
; SUPPORTING the clone in a break condition (collect it, adjoint it via its `_unc`
; twin, clone it into the companion loop) is a WIDENING, not this bug: it is a new
; accept shape owing a PRD, an `_unc`-twin reachability proof and its own Rule-13
; round. Tracked under the 7.x widenings epic, not here.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; bd test_C_libtooling-um24 — the SAME decline under the no-reuse test allocator
; (`CQ_OPT_DEBUG_ALLOC=nofree`, `%debugalloc-cq-opt` only). The unfixed `lowerLoops` prescan
; called `getFunction()` on a `taint.Tainted` key an earlier stage had ERASED;
; with no reuse the dead object's parent is null, so the unfixed binary SIGSEGVs
; here DETERMINISTICALLY (measured on oracle `def1b088` + the test allocator), and
; `not` fails on a crash. The system allocator hid it by reusing the memory.
; RUN: env CQ_OPT_DEBUG_ALLOC=nofree not %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; int f(int x, int n) {
;   int q = x; cq_theta(&q, 0.25);
;   for (int i = 0; i < n; i++) { q ^= 9; if (g(q) == 0) break; }
;   return cq_measure(q);
; }
define i32 @break_uncollected_clone(i32 noundef %0, i32 noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 2.500000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %14

5:                                                ; preds = %2, %5
  %6 = phi i32 [ %11, %5 ], [ 0, %2 ]
  %7 = phi i32 [ %8, %5 ], [ %3, %2 ]
  %8 = xor i32 %7, 9                              ; the in-place rail self-update
  %9 = tail call fastcc i32 @g(i32 noundef %8)    ; → @__cq_q_g_1: TAINTED, UNCOLLECTED
  %10 = icmp eq i32 %9, 0                         ; the break flag
  %11 = add nuw nsw i32 %6, 1
  %12 = icmp eq i32 %11, %1
  %13 = select i1 %10, i1 true, i1 %12            ; the -O1 fused exit (PRD-7.4 §1.1)
  br i1 %13, label %14, label %5

14:                                               ; preds = %5, %2
  %15 = phi i32 [ %3, %2 ], [ %8, %5 ]
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15)
  ret i32 %16
}

; `noinline` + `memory(none)` is what makes B4 admit it and Phase 6 specialize it.
define internal fastcc noundef range(i32 0, 2) i32 @g(i32 noundef %0) unnamed_addr #0 {
  %2 = and i32 %0, 1
  ret i32 %2
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr
declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }

; The decline is loud and source-located; `opt` exits non-zero and NOTHING is emitted.
; CHECK: error:
; CHECK-SAME: cq loop lowering: break reverse-play cannot re-emit an uncollected body value

; And the broken-module abort is GONE — the pre-fix failure mode, character-for-
; character, must not appear on any path.
; CHECK-NOT: Instruction does not dominate all uses
; CHECK-NOT: Broken module found
