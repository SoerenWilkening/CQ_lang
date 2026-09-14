; ModuleID = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/u3.s1.ll'
source_filename = "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/u3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !10 {
    #dbg_value(i32 5, !15, !DIExpression(), !18)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !19
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !19
    #dbg_value(i32 %h, !16, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !18)
  %bf = call i32 @cqrt_alloc_i1(i1 false), !dbg !20
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !20
  %out = call i32 @cqrt_alloc_i32(i32 0), !dbg !20
  %selop = call i32 @cqrt_alloc_i32(i32 2), !dbg !20
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop, i32 %out), !dbg !20
  call void @cqrt_x(i32 %bf), !dbg !20
  %selop1 = call i32 @cqrt_alloc_i32(i32 5), !dbg !20
  call void @cqrt_copy_i32_controlled(i32 %bf, i32 %selop1, i32 %out), !dbg !20
  call void @cqrt_x(i32 %bf), !dbg !20
  call void @cqrt_cnot(i32 %h, i32 %bf), !dbg !20
  call void @cqrt_free(i32 %bf), !dbg !20
    #dbg_value(i32 %out, !15, !DIExpression(), !18)
  %m = call i1 @cqrt_measure_i1(i32 %h), !dbg !21
  %1 = zext i1 %m to i32, !dbg !21
  %m2 = call i32 @cqrt_measure_i32(i32 %out), !dbg !22
  %2 = add nsw i32 %m2, %1, !dbg !23
  ret i32 %2, !dbg !24
}

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_copy_i32_controlled(i32, i32, i32)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_cnot(i32, i32)

declare void @cqrt_x(i32)

declare void @cqrt_free(i32)

declare void @cqrt_ry_i1(i32, double)

declare i1 @cqrt_measure_i1(i32)

declare i32 @cqrt_measure_i32(i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4, !5, !6}
!llvm.dbg.cu = !{!7}
!llvm.ident = !{!9}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 7, !"Dwarf Version", i32 5}
!2 = !{i32 2, !"Debug Info Version", i32 3}
!3 = !{i32 1, !"wchar_size", i32 4}
!4 = !{i32 8, !"PIC Level", i32 2}
!5 = !{i32 7, !"uwtable", i32 2}
!6 = !{i32 7, !"frame-pointer", i32 2}
!7 = distinct !DICompileUnit(language: DW_LANG_C11, file: !8, producer: "Homebrew clang version 19.1.7", isOptimized: true, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: Apple, sysroot: "/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk", sdk: "MacOSX26.sdk")
!8 = !DIFile(filename: "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackU/fix_r1_probes/u3.c", directory: "/Users/sorenwilkening/Desktop/CQ_undef", checksumkind: CSK_MD5, checksum: "a765334d618883e5e99f497754c81a86")
!9 = !{!"Homebrew clang version 19.1.7"}
!10 = distinct !DISubprogram(name: "main", scope: !8, file: !8, line: 3, type: !11, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !14)
!11 = !DISubroutineType(types: !12)
!12 = !{!13}
!13 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!14 = !{!15, !16}
!15 = !DILocalVariable(name: "a", scope: !10, file: !8, line: 4, type: !13)
!16 = !DILocalVariable(name: "b0", scope: !10, file: !8, line: 5, type: !17)
!17 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!18 = !DILocation(line: 0, scope: !10)
!19 = !DILocation(line: 6, column: 10, scope: !10)
!20 = !DILocation(line: 7, column: 9, scope: !10)
!21 = !DILocation(line: 8, column: 12, scope: !10)
!22 = !DILocation(line: 8, column: 29, scope: !10)
!23 = !DILocation(line: 8, column: 27, scope: !10)
!24 = !DILocation(line: 8, column: 5, scope: !10)
