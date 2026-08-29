; lowering_uncompute_loop_backedge_irreducible.ll — the IRREDUCIBLE TWIN of
; lowering_uncompute_loop_backedge.ll (Phase 5 §2.9), added by bd
; test_C_libtooling-4p7j's Rule-13 RE-review (finding G1).
;
; SAME PROGRAM, DIFFERENT CFG SPELLING. A tainted handle is minted in `entry`
; and its in-place `cq_phi` (→ `cqrt_rz_i32`) sits inside a cycle, so the
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq uncompute: tainted handle live range crosses a loop backedge
;
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)

define void @slice(i32 %x, i1 %c0, i1 %c1) !dbg !4 {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01), !dbg !7
  br i1 %c0, label %A, label %B, !dbg !8
A:                                        ; preds = %entry, %B — irreducible
  %p = call i32 @cq_phi_si32(i32 %h, double 1.000000e-01), !dbg !9
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
