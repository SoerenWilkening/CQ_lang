; lowering_uncompute_loop_backedge.ll — Phase 5 Step 3 NEGATIVE (PRD §4 bullet 7
; / IMPLEMENTATION §4.3, decision 2.9). Phase 5 assumes an ACYCLIC CFG. A tainted
; handle minted before a loop and used INSIDE the loop body has a live range that
; crosses the loop backedge (a loop-carried / per-iteration register). Loops are
; out of scope for this phase; rather than silently miscompile, such a handle is
; diagnosed LOUDLY (`DiagnosticInfoUnsupported`, non-zero exit). The loops phase
; will EXTEND (not replace) this last-use machinery. FreePoint OWNS the exact
; `Msg` string; this CHECK mirrors it. The `!dbg` source-locates the in-loop use.
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
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq uncompute: tainted handle live range crosses a loop backedge
;
declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x, i32 %n) !dbg !4 {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01), !dbg !7
  br label %loop, !dbg !8
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %p = call i32 @cq_theta_si32(i32 %h, double 1.000000e-01), !dbg !9
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, %n
  br i1 %done, label %loop, label %exit, !dbg !9
exit:
  ret void, !dbg !10
}
!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "cq", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "loop.c", directory: "/tmp")
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = distinct !DISubprogram(name: "slice", scope: !1, file: !1, line: 1, type: !5, scopeLine: 1, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{null}
!7 = !DILocation(line: 2, column: 7, scope: !4)
!8 = !DILocation(line: 3, column: 7, scope: !4)
!9 = !DILocation(line: 4, column: 9, scope: !4)
!10 = !DILocation(line: 6, column: 3, scope: !4)
