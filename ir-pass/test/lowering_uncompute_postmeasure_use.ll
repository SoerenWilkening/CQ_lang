; lowering_uncompute_postmeasure_use.ll — Phase 5 Step 3 NEGATIVE (PRD §2.5 /
; IMPLEMENTATION §4.3, decision 2.5 sub-rule). Applying a gate to a handle AFTER
; it has been measured is ill-formed: measurement collapses the register
; ("measured ⇒ done"), so a subsequent `cq_phi → cqrt_rz` on the same handle is
; rejected LOUDLY (`DiagnosticInfoUnsupported`, non-zero exit) rather than
; silently uncomputed. FreePoint OWNS the exact `Msg` string; this CHECK mirrors
; it character-for-character. The `!dbg` on the offending gate source-locates it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq uncompute: gate applied to handle after measurement
;
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @cq_phi_si32(i32, double)

define void @slice(i32 %x) !dbg !4 {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01), !dbg !7
  %m = call i32 @cq_measure_si32(i32 %h), !dbg !8
  %p = call i32 @cq_phi_si32(i32 %h, double 1.000000e-01), !dbg !9
  ret void, !dbg !10
}
!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "cq", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "pm.c", directory: "/tmp")
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = distinct !DISubprogram(name: "slice", scope: !1, file: !1, line: 1, type: !5, scopeLine: 1, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{null}
!7 = !DILocation(line: 2, column: 7, scope: !4)
!8 = !DILocation(line: 3, column: 7, scope: !4)
!9 = !DILocation(line: 4, column: 9, scope: !4)
!10 = !DILocation(line: 5, column: 3, scope: !4)
