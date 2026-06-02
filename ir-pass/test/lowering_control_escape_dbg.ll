; lowering_control_escape_dbg.ll — Phase 4.1 WP17 (PRD §8.6, epic `-aht.2`),
; negative + SOURCE LOCATION. The escape diagnostic carries the offending
; instruction's `!dbg` so the rejection is source-located (PRD §8.6 /
; backend.md §7, "source-location precision via !dbg"). With debug info present
; the diagnostic reports `file:line:col` at the `cq_measure` site (here
; esc.c:4:9), not just the function. This pins that the acceptance criterion
; "escape cases emit the diagnostic with correct source location" holds.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: esc.c:4:9:{{.*}}measurement under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %a) !dbg !4 {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01), !dbg !7
  %c = icmp sgt i32 %q, 0, !dbg !8
  br i1 %c, label %arm, label %merge, !dbg !8
arm:
  %m = call i32 @cq_measure_si32(i32 %q), !dbg !9   ; line 4, col 9
  br label %merge
merge:
  %y = phi i32 [ %m, %arm ], [ %a, %entry ]
  ret i32 %y, !dbg !10
}
!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!3}
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, producer: "cq", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "esc.c", directory: "/tmp")
!3 = !{i32 2, !"Debug Info Version", i32 3}
!4 = distinct !DISubprogram(name: "example", scope: !1, file: !1, line: 1, type: !5, scopeLine: 1, unit: !0)
!5 = !DISubroutineType(types: !6)
!6 = !{null}
!7 = !DILocation(line: 2, column: 7, scope: !4)
!8 = !DILocation(line: 3, column: 7, scope: !4)
!9 = !DILocation(line: 4, column: 9, scope: !4)
!10 = !DILocation(line: 6, column: 3, scope: !4)
