; ModuleID = '/var/folders/1v/g83tnnts1bdb_xk5b2hfl9x40000gn/T/tmp.RUWQL0RF4A/s1.ll'
source_filename = "./w2a_twoloop_passonly_un.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 !dbg !12 {
    #dbg_value(i32 0, !18, !DIExpression(), !31)
  %h = call i32 @cqrt_alloc_i1(i1 false), !dbg !32
  call void @cqrt_ry_i1(i32 %h, double 5.000000e-01), !dbg !32
    #dbg_value(i32 %h, !19, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !33)
  %h4 = call i32 @cqrt_alloc_i32(i32 7), !dbg !34
  call void @cqrt_ry_i32(i32 %h4, double 2.500000e-01), !dbg !34
    #dbg_value(i32 %h4, !21, !DIExpression(), !33)
  call void @cqrt_ry_i32_controlled(i32 %h, i32 %h4, double 2.000000e-01), !dbg !35
    #dbg_value(i32 %h4, !21, !DIExpression(), !33)
  %m = call i32 @cqrt_measure_i32(i32 %h4), !dbg !37
  %m8 = call i1 @cqrt_measure_i1(i32 %h), !dbg !38
    #dbg_value(!DIArgList(i32 %m, i1 %m8), !18, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_plus, DW_OP_stack_value), !31)
  %h1 = call i32 @cqrt_alloc_i1(i1 false), !dbg !39
  call void @cqrt_ry_i1(i32 %h1, double 5.000000e-01), !dbg !39
    #dbg_value(i32 %h1, !22, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !40)
  %h5 = call i32 @cqrt_alloc_i32(i32 7), !dbg !41
  call void @cqrt_ry_i32(i32 %h5, double 2.500000e-01), !dbg !41
    #dbg_value(i32 %h5, !24, !DIExpression(), !40)
  call void @cqrt_ry_i32_controlled(i32 %h1, i32 %h5, double 2.000000e-01), !dbg !42
    #dbg_value(i32 %h5, !24, !DIExpression(), !40)
  %m9 = call i32 @cqrt_measure_i32(i32 %h5), !dbg !44
  %m10 = call i1 @cqrt_measure_i1(i32 %h1), !dbg !45
    #dbg_value(!DIArgList(i32 %m, i32 %m9, i1 %m10, i1 %m8), !18, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 3, DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_plus, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_plus, DW_OP_plus, DW_OP_stack_value), !31)
  %h2 = call i32 @cqrt_alloc_i1(i1 false), !dbg !46
  call void @cqrt_ry_i1(i32 %h2, double 6.000000e-01), !dbg !46
    #dbg_value(i32 %h2, !25, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !47)
  %h6 = call i32 @cqrt_alloc_i32(i32 9), !dbg !48
  call void @cqrt_ry_i32(i32 %h6, double 3.500000e-01), !dbg !48
    #dbg_value(i32 %h6, !27, !DIExpression(), !47)
  call void @cqrt_ry_i32_controlled(i32 %h2, i32 %h6, double 3.000000e-01), !dbg !49
    #dbg_value(i32 %h6, !27, !DIExpression(), !47)
  %m11 = call i32 @cqrt_measure_i32(i32 %h6), !dbg !51
  %m12 = call i1 @cqrt_measure_i1(i32 %h2), !dbg !52
    #dbg_value(!DIArgList(i32 %m, i32 %m11, i1 %m12, i32 %m9, i1 %m10, i1 %m8), !18, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 5, DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_plus, DW_OP_LLVM_arg, 3, DW_OP_LLVM_arg, 4, DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_plus, DW_OP_plus, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 32, DW_ATE_unsigned, DW_OP_plus, DW_OP_plus, DW_OP_stack_value), !31)
  %h3 = call i32 @cqrt_alloc_i1(i1 false), !dbg !53
  call void @cqrt_ry_i1(i32 %h3, double 6.000000e-01), !dbg !53
    #dbg_value(i32 %h3, !28, !DIExpression(DW_OP_LLVM_convert, 1, DW_ATE_unsigned, DW_OP_LLVM_convert, 8, DW_ATE_unsigned, DW_OP_stack_value), !54)
  %h7 = call i32 @cqrt_alloc_i32(i32 9), !dbg !55
  call void @cqrt_ry_i32(i32 %h7, double 3.500000e-01), !dbg !55
    #dbg_value(i32 %h7, !30, !DIExpression(), !54)
  call void @cqrt_ry_i32_controlled(i32 %h3, i32 %h7, double 3.000000e-01), !dbg !56
  %1 = zext i1 %m8 to i32, !dbg !38
    #dbg_value(!DIArgList(i32 %m, i32 %1), !18, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !31)
    #dbg_value(i32 poison, !18, !DIExpression(), !31)
  %2 = zext i1 %m10 to i32, !dbg !45
    #dbg_value(!DIArgList(i32 poison, i32 poison, i32 poison), !18, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_plus, DW_OP_plus, DW_OP_stack_value), !31)
    #dbg_value(!DIArgList(i32 poison, i32 poison), !18, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !31)
    #dbg_value(i32 poison, !18, !DIExpression(), !31)
  %3 = zext i1 %m12 to i32, !dbg !52
    #dbg_value(!DIArgList(i32 poison, i32 poison, i32 poison), !18, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_LLVM_arg, 2, DW_OP_plus, DW_OP_plus, DW_OP_stack_value), !31)
    #dbg_value(!DIArgList(i32 poison, i32 poison), !18, !DIExpression(DW_OP_LLVM_arg, 0, DW_OP_LLVM_arg, 1, DW_OP_plus, DW_OP_stack_value), !31)
    #dbg_value(i32 poison, !18, !DIExpression(), !31)
    #dbg_value(i32 %h7, !30, !DIExpression(), !54)
  %m13 = call i32 @cqrt_measure_i32(i32 %h7), !dbg !58
  %m14 = call i1 @cqrt_measure_i1(i32 %h3), !dbg !59
  %4 = zext i1 %m14 to i32, !dbg !59
  %5 = add i32 %m, %1, !dbg !60
  %6 = add i32 %5, %m9, !dbg !61
  %7 = add i32 %6, %2, !dbg !62
  %8 = add i32 %7, %m11, !dbg !63
  %9 = add i32 %8, %3, !dbg !64
  %10 = add i32 %9, %m13, !dbg !65
  %11 = add i32 %10, %4, !dbg !66
    #dbg_value(i32 %11, !18, !DIExpression(), !31)
  ret i32 %11, !dbg !67
}

; Function Attrs: nounwind ssp uwtable
define i32 @main() local_unnamed_addr #0 !dbg !68 {
  %1 = tail call i32 @slice(), !dbg !69
  ret i32 %1, !dbg !70
}

declare void @cqrt_x(i32)

declare void @cqrt_ry_i1(i32, double)

declare i32 @cqrt_alloc_i1(i1)

declare void @cqrt_ry_i32(i32, double)

declare i32 @cqrt_alloc_i32(i32)

declare void @cqrt_ry_i32_controlled(i32, i32, double)

declare i32 @cqrt_measure_i32(i32)

declare i1 @cqrt_measure_i1(i32)

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
!8 = !DIFile(filename: "w2a_twoloop_passonly_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "34ac375155e8b449e7e63117e6814fb3")
!9 = !{!10}
!10 = !DIBasicType(name: "_Bool", size: 8, encoding: DW_ATE_boolean)
!11 = !{!"Homebrew clang version 19.1.7"}
!12 = distinct !DISubprogram(name: "slice", scope: !13, file: !13, line: 3, type: !14, scopeLine: 3, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7, retainedNodes: !17)
!13 = !DIFile(filename: "./w2a_twoloop_passonly_un.c", directory: "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/trackW/review_r2_probes", checksumkind: CSK_MD5, checksum: "34ac375155e8b449e7e63117e6814fb3")
!14 = !DISubroutineType(types: !15)
!15 = !{!16}
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{!18, !19, !21, !22, !24, !25, !27, !28, !30}
!18 = !DILocalVariable(name: "s", scope: !12, file: !13, line: 4, type: !16)
!19 = !DILocalVariable(name: "t", scope: !20, file: !13, line: 5, type: !10)
!20 = distinct !DILexicalBlock(scope: !12, file: !13, line: 5, column: 5)
!21 = !DILocalVariable(name: "r", scope: !20, file: !13, line: 5, type: !16)
!22 = !DILocalVariable(name: "t", scope: !23, file: !13, line: 7, type: !10)
!23 = distinct !DILexicalBlock(scope: !12, file: !13, line: 7, column: 5)
!24 = !DILocalVariable(name: "r", scope: !23, file: !13, line: 7, type: !16)
!25 = !DILocalVariable(name: "t2", scope: !26, file: !13, line: 9, type: !10)
!26 = distinct !DILexicalBlock(scope: !12, file: !13, line: 9, column: 5)
!27 = !DILocalVariable(name: "r2", scope: !26, file: !13, line: 9, type: !16)
!28 = !DILocalVariable(name: "t2", scope: !29, file: !13, line: 11, type: !10)
!29 = distinct !DILexicalBlock(scope: !12, file: !13, line: 11, column: 5)
!30 = !DILocalVariable(name: "r2", scope: !29, file: !13, line: 11, type: !16)
!31 = !DILocation(line: 0, scope: !12)
!32 = !DILocation(line: 5, column: 16, scope: !20)
!33 = !DILocation(line: 0, scope: !20)
!34 = !DILocation(line: 5, column: 48, scope: !20)
!35 = !DILocation(line: 6, column: 18, scope: !36)
!36 = distinct !DILexicalBlock(scope: !20, file: !13, line: 6, column: 11)
!37 = !DILocation(line: 6, column: 41, scope: !20)
!38 = !DILocation(line: 6, column: 57, scope: !20)
!39 = !DILocation(line: 7, column: 16, scope: !23)
!40 = !DILocation(line: 0, scope: !23)
!41 = !DILocation(line: 7, column: 48, scope: !23)
!42 = !DILocation(line: 8, column: 18, scope: !43)
!43 = distinct !DILexicalBlock(scope: !23, file: !13, line: 8, column: 11)
!44 = !DILocation(line: 8, column: 41, scope: !23)
!45 = !DILocation(line: 8, column: 57, scope: !23)
!46 = !DILocation(line: 9, column: 17, scope: !26)
!47 = !DILocation(line: 0, scope: !26)
!48 = !DILocation(line: 9, column: 50, scope: !26)
!49 = !DILocation(line: 10, column: 20, scope: !50)
!50 = distinct !DILexicalBlock(scope: !26, file: !13, line: 10, column: 11)
!51 = !DILocation(line: 10, column: 44, scope: !26)
!52 = !DILocation(line: 10, column: 61, scope: !26)
!53 = !DILocation(line: 11, column: 17, scope: !29)
!54 = !DILocation(line: 0, scope: !29)
!55 = !DILocation(line: 11, column: 50, scope: !29)
!56 = !DILocation(line: 12, column: 20, scope: !57)
!57 = distinct !DILexicalBlock(scope: !29, file: !13, line: 12, column: 11)
!58 = !DILocation(line: 12, column: 44, scope: !29)
!59 = !DILocation(line: 12, column: 61, scope: !29)
!60 = !DILocation(line: 12, column: 59, scope: !29)
!61 = !DILocation(line: 10, column: 59, scope: !26)
!62 = !DILocation(line: 8, column: 55, scope: !23)
!63 = !DILocation(line: 6, column: 55, scope: !20)
!64 = !DILocation(line: 8, column: 38, scope: !23)
!65 = !DILocation(line: 10, column: 41, scope: !26)
!66 = !DILocation(line: 12, column: 41, scope: !29)
!67 = !DILocation(line: 13, column: 5, scope: !12)
!68 = distinct !DISubprogram(name: "main", scope: !13, file: !13, line: 15, type: !14, scopeLine: 15, flags: DIFlagPrototyped | DIFlagAllCallsDescribed, spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !7)
!69 = !DILocation(line: 15, column: 25, scope: !68)
!70 = !DILocation(line: 15, column: 18, scope: !68)
