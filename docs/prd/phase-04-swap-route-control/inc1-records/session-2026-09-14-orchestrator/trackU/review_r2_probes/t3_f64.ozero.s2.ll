; ModuleID = 't3_f64.ozero.s1.ll'
source_filename = "t3_f64.zero.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !12 {
    #dbg_value(double 0.000000e+00, !15, !DIExpression(), !17)
  %h = call i32 @cqrt_alloc_f64(double 0.000000e+00), !dbg !18
  call void @cqrt_ry_f64(i32 %h, double 5.000000e-01), !dbg !18
    #dbg_value(i32 %h, !15, !DIExpression(), !17)
  %m = call double @cqrt_measure_f64(i32 %h), !dbg !19
  %1 = fptosi double %m to i32, !dbg !20
  ret i32 %1, !dbg !21
}

declare void @cqrt_ry_f64(i32, double)

declare i32 @cqrt_alloc_f64(double)

declare double @cqrt_measure_f64(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!11}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, retainedTypes: !9, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "t3_f64.zero.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/review_r2_probes", checksumkind: CSK_MD5, checksum: "d4501597c072d89adfc5b9dbd2ad525b")
!9 = !{!10}
!10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 2, type: !13, scopeLine: 2, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!13 = !DISubroutineType(types: !9)
!14 = !{!15}
!15 = !DILocalVariable(name: "d", scope: !12, file: !8, line: 2, type: !16)
!16 = !DIBasicType(name: "double", size: 64, encoding: DW_ATE_float)
!17 = !DILocation(line: 0, scope: !12)
!18 = !DILocation(line: 2, column: 38, scope: !12)
!19 = !DILocation(line: 2, column: 69, scope: !12)
!20 = !DILocation(line: 2, column: 63, scope: !12)
!21 = !DILocation(line: 2, column: 56, scope: !12)
