; lowering_uncompute_loop_backedge_irreducible.ll — the IRREDUCIBLE TWIN of
; lowering_uncompute_loop_backedge.ll (Phase 5 §2.9), added by bd
; test_C_libtooling-4p7j's Rule-13 RE-review (finding G1).
;
; SAME PROGRAM, DIFFERENT CFG SPELLING. A tainted handle is minted in `entry`
; and its in-place `cq_theta` (→ `cqrt_ry_i32`) sits inside a cycle, so the
; handle's live range crosses a backedge and a once-only reversal + free would
; undo K executions with one adjoint (Rule 6: a free of a non-|0> rail is a
; hidden measurement). The natural-loop spelling has declined loudly since Phase
; 5 Step 3. This spelling is IRREDUCIBLE — `%A` and `%B` each have two
; predecessors and neither dominates the other, so there is no natural loop and
; `LoopInfo::getLoopFor` returns NULL for both blocks.
;
; WHAT IT PINS. `FreePoint::blockInLoop` — the guard behind the LOUD
; `kMsgLoopBackedge` — asked `LoopInfo` alone, so this module LOWERED SILENTLY
; while its natural-loop twin declined: one hazard, two answers, decided by the
; CFG spelling rather than by the physics. `blockInLoop` is now
; `LoopInfo || blockCanRepeat` (the reachable-from-itself DFS the reversal
; backstops in `Uncomputation` were moved onto by the same round's finding F1,
; hoisted to FreePoint.h so there is ONE definition — Rule 14). `blockCanRepeat`
; is a strict SUPERSET of the natural-loop test, so no acyclic module changes
; disposition; the only programs that move are irreducible ones, and they move
; from silent leak to loud decline.
;
; `FreePoint` OWNS the exact `Msg` string; this CHECK mirrors it
; character-for-character. The `!dbg` source-locates the in-cycle use.
;
;
; 3qlq(prep_a2): HAND DECISION — the register `cq_phi` here was NEVER the subject.
; This fixture pins an uncompute / mux / measurement-ordering / specialization rule
; and used `%r = cq_phi_<sfx>(%x, θ)` only as "a gate on a handle".  D1 removes that
; spelling, so the gate is re-spelled `cq_theta_<sfx>` — the OTHER in-place rotation
; on the same rail, which is what the corpus uses everywhere else for the same job.
; MEASURED on the Inc-1 binary: the swap reproduces this fixture's ORIGINAL asserted
; diagnostic, so the CHECK lines are UNCHANGED and the property is pinned by exactly
; the text it was pinned by before.  (prep_a measured the same 16 files against the
; pre-3qlq ORACLE; this is the independent re-measurement on the SUBJECT.)
; ⚠ Note what the swap does NOT preserve: Rz is DIAGONAL and Ry is not, so a rule
; that turned on diagonality would move.  None of these 16 do — that is what the
; character-for-character reproduction of the diagnostic establishes.
;
; ⚠⚠ MESSAGE OWNERSHIP MOVED — bd test_C_libtooling-3d8q, **OWNER RULING
; 2026-09-14 (DECLINE)**. The module, the verdict and the subject below are
; UNCHANGED; only the fence that speaks first has changed, and it is the earlier
; and more accurate one.
;
; This module IS the ruled shape, and it always was: `%h = cq_theta(%x,.25)` is
; minted in ENTRY, loop-INVARIANT, and the body's `%p = cq_theta(%h,.1)` RE-READS
; the name `%h` on every trip while the wire has already moved under it (trip 2
; names `Ry(.25)|x>` while the register holds `Ry(.35)|x>`). The owner ruled that
; spelling a DECLINE on 2026-09-14: the source admits TWO realizable circuits —
; the aliasing chain and the re-preparation one, which needs no cloning and which
; this compiler already emits when asked unambiguously — and names neither.
; `recordStaleQuantumReaders` runs as pure analysis BEFORE `lowerLoops` and is
; diagnosed just above `lowerRotations`, i.e. long before the uncompute spine, and
; `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`) — so the
; earlier owner is the one the user sees.
;
; ⚠ THE UNCOMPUTE FENCE IS NOT LEFT UNPINNED — measured, not assumed:
; `lowering_reject_loop_nested_quantum.ll` and
; `lowering_uncompute_leak_irreducible_dead_spine.ll` still decline at
; `cq uncompute: tainted handle live range crosses a loop backedge` on this
; binary, each with a positive `CHECK`. This file's own subject (a backedge-
; crossing live range) is therefore still enforced and still pinned elsewhere.
;
; RETIREMENT TRIGGER (L8): if the 2026-09-14 ruling is ever reversed — if the
; loop-invariant re-read is ruled an ACCEPT — this file reverts to asserting
; `cq uncompute: tainted handle live range crosses a loop backedge`, and
; `lowering_reject_stale_reader_inloop_invariant_seed.ll` inverts in the same
; commit. Do not move one without the other.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate
; ⚠ The line this file asserted until 2026-09-14, kept as the record of what
; moved and neutered so FileCheck cannot see it:
;   [check]: error{{.*}}cq uncompute: tainted handle live range crosses a loop backedge
;
declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x, i1 %c0, i1 %c1) !dbg !4 {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01), !dbg !7
  br i1 %c0, label %A, label %B, !dbg !8
A:                                        ; preds = %entry, %B — irreducible
  %p = call i32 @cq_theta_si32(i32 %h, double 1.000000e-01), !dbg !9
  br i1 %c1, label %B, label %exit, !dbg !9
B:                                        ; preds = %entry, %A
  br label %A, !dbg !9
exit:
  ret void, !dbg !10
}
!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "cq", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "loop_irreducible.c", directory: "/tmp")
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = distinct !DISubprogram(name: "slice", scope: !1, file: !1, line: 1, type: !5, scopeLine: 1, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{null}
!7 = !DILocation(line: 2, column: 7, scope: !4)
!8 = !DILocation(line: 3, column: 7, scope: !4)
!9 = !DILocation(line: 4, column: 9, scope: !4)
!10 = !DILocation(line: 6, column: 3, scope: !4)
