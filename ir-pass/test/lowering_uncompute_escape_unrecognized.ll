; lowering_uncompute_escape_unrecognized.ll — Phase 5 Step 3 NEGATIVE (PRD §4
; bullet 6 / IMPLEMENTATION §4.3, decision 2.6). A tainted terminal handle used
; on two arms that DO NOT reconverge — each arm exits via its own `ret`, so the
; user blocks have NO common post-dominator (a real block). Per 2.6 a null common
; post-dominator is treated as an unrecognized escape — a HOLE, not a no-op — and
; is diagnosed LOUDLY (`DiagnosticInfoUnsupported`, non-zero exit), never silently
; skipped. FreePoint OWNS the exact `Msg` string; this CHECK mirrors it.
;
; The `!dbg` on the offending use makes the diagnostic source-located.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq uncompute: tainted handle reaches an unrecognized user
;
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)

define void @slice(i32 %x, i1 %c) !dbg !4 {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01), !dbg !7
  br i1 %c, label %a, label %b, !dbg !8
a:
  %pa = call i32 @cq_phi_si32(i32 %h, double 1.000000e-01), !dbg !9
  ret void, !dbg !9
b:
  %pb = call i32 @cq_phi_si32(i32 %h, double 2.000000e-01), !dbg !10
  ret void, !dbg !10
}
!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "cq", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "esc.c", directory: "/tmp")
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = distinct !DISubprogram(name: "slice", scope: !1, file: !1, line: 1, type: !5, scopeLine: 1, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{null}
!7 = !DILocation(line: 2, column: 7, scope: !4)
!8 = !DILocation(line: 3, column: 7, scope: !4)
!9 = !DILocation(line: 4, column: 9, scope: !4)
!10 = !DILocation(line: 6, column: 9, scope: !4)
